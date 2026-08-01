import 'dart:async';

import '../../models/dtc.dart';
import 'obd_controller.dart';
import 'obd_helpers.dart';
import 'obd_models.dart';
import 'obd_transport.dart';

class Elm327Controller implements ObdController {
  Elm327Controller(this._transport, {bool enableCanFd = false})
      : _enableCanFd = enableCanFd;

  final ObdTransport _transport;
  final bool _enableCanFd;
  bool _connected = false;
  bool _canFd = false;
  String _version = '';
  String _protocol = '';
  double _voltage = 0;

  @override
  bool get connected => _connected;
  bool get canFd => _canFd;
  @override
  String get version => _version;
  @override
  String get protocol => _protocol;
  @override
  double get voltage => _voltage;

  Future<void> init() async {
    await _transport.open(_currentAdapter!);
    _connected = true;

    _version = await _command('ATZ', expectPrompt: true) ?? '';
    await _command('ATE0');
    await _command('ATL0');
    await _command('ATH0');
    await _command('ATS1');
    await _command('ATSP0');
    if (_enableCanFd) {
      await _enableCanFdMode();
    }
    _protocol = await _command('ATDP') ?? '';
    _voltage = await readVoltage();
  }

  Future<void> _enableCanFdMode() async {
    final allowLong = await _command('ATAL');
    _canFd = (allowLong ?? '').toUpperCase().contains('OK');
    if (_canFd) {
      await _command('ATSDL');
    }
  }

  ObdAdapter? _currentAdapter;

  @override
  Future<void> open(ObdAdapter adapter) async {
    _currentAdapter = adapter;
    await init();
  }

  @override
  Future<void> close() async {
    _connected = false;
    await _transport.close();
  }

  Future<String?> _command(String cmd, {bool expectPrompt = true}) async {
    await _transport.write('$cmd\r');
    if (!expectPrompt) return null;
    final raw = await _transport.readResponse(
      timeout: const Duration(seconds: 4),
    );
    return _clean(raw);
  }

  String _clean(String raw) {
    var s = raw.replaceAll('>', '');
    for (final token in [
      'SEARCHING...',
      'BUS INIT: OK',
      'BUS INIT: ...',
      'STOPPED',
      'CAN ERROR',
    ]) {
      s = s.replaceAll(token, '');
    }
    final lines = s
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    return lines.join(' ');
  }

  @override
  Future<double> readVoltage() async {
    final raw = await _command('ATRV');
    final match = RegExp(r'([0-9]+\.?[0-9]*)').firstMatch(raw ?? '');
    if (match == null) return 0;
    final v = double.tryParse(match.group(1)!);
    _voltage = v ?? 0;
    return _voltage;
  }

  @override
  Future<double?> readPid(ObdPid pid) async {
    if (pid == ObdPid.voltage) return readVoltage();
    final cmd = '01${pid.code.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    final raw = await _command(cmd);
    return _parsePid(raw ?? '', pid);
  }

  double? _parsePid(String cleaned, ObdPid pid) {
    final pidHex = pid.code.toRadixString(16).padLeft(2, '0').toUpperCase();
    final re = RegExp(
      r'41\s+' + pidHex + r'\s+([0-9A-Fa-f\s]+)',
    );
    final m = re.firstMatch(cleaned);
    if (m == null) return null;
    final bytes = parseHexBytes(m.group(1)!);
    if (bytes.isEmpty) return null;
    return applyPidFormula(pid, bytes);
  }

  @override
  Future<List<DtcCode>> readDtc() async {
    final codes = <DtcCode>{};
    final raw = await _command('03');
    codes.addAll(_parseDtc(raw ?? ''));
    if (codes.isEmpty) {
      final perm = await _command('0A');
      codes.addAll(_parseDtc(perm ?? ''));
    }
    return codes.toList();
  }

  List<DtcCode> _parseDtc(String cleaned) {
    final re = RegExp(r'43\s+[0-9A-Fa-f\s]+');
    final m = re.firstMatch(cleaned);
    if (m == null) return [];
    final tokens = parseHexBytes(m.group(0)!);
    if (tokens.isEmpty) return [];
    final payload = tokens.sublist(1);
    final result = <DtcCode>[];
    for (var i = 0; i + 1 < payload.length; i += 2) {
      final b1 = payload[i];
      final b2 = payload[i + 1];
      if (b1 == 0 && b2 == 0) continue;
      final code = dtcCodeFromBytes(b1, b2);
      result.add(DtcCode(
        code: code,
        description: dtcDescription(code),
        system: dtcSystem(code),
        severity: dtcSeverity(code),
        frozen: false,
      ));
    }
    return result;
  }

  @override
  Future<void> clearDtc() async {
    await _command('04');
  }

  @override
  Future<String?> readVin() async {
    final raw = await _command('0902');
    return _parseVin(raw ?? '');
  }

  String? _parseVin(String cleaned) {
    final tokens = cleaned
        .split(RegExp(r'[^0-9A-Fa-f]+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final bytes = <int>[];
    for (final t in tokens) {
      if (t.length == 1) {
        bytes.add(int.parse(t, radix: 16));
      } else if (t.length == 2) {
        bytes.add(int.parse(t, radix: 16));
      }
    }
    // Find 49 02 01 marker.
    var start = -1;
    for (var i = 0; i + 2 < bytes.length; i++) {
      if (bytes[i] == 0x49 && bytes[i + 1] == 0x02 && bytes[i + 2] == 0x01) {
        start = i + 3;
        break;
      }
    }
    if (start < 0) return null;
    final vin = String.fromCharCodes(bytes
        .sublist(start)
        .where((b) => b >= 0x30 && b <= 0x7A));
    return vin.isEmpty ? null : vin;
  }

  @override
  Stream<Map<ObdPid, double>> liveDataStream() async* {
    while (_connected) {
      final data = <ObdPid, double>{};
      for (final pid in ObdPid.values) {
        if (!_connected) break;
        try {
          final v = await readPid(pid);
          if (v != null) data[pid] = v;
        } catch (_) {}
      }
      yield data;
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }
}
