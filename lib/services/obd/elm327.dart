import 'dart:async';

import '../../models/dtc.dart';
import 'obd_models.dart';
import 'obd_transport.dart';

class Elm327Controller {
  Elm327Controller(this._transport);

  final ObdTransport _transport;
  bool _connected = false;
  String _version = '';
  String _protocol = '';
  double _voltage = 0;

  bool get connected => _connected;
  String get version => _version;
  String get protocol => _protocol;
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
    _protocol = await _command('ATDP') ?? '';
    _voltage = await readVoltage();
  }

  ObdAdapter? _currentAdapter;

  Future<void> open(ObdAdapter adapter) async {
    _currentAdapter = adapter;
    await init();
  }

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

  Future<double> readVoltage() async {
    final raw = await _command('ATRV');
    final match = RegExp(r'([0-9]+\.?[0-9]*)').firstMatch(raw ?? '');
    if (match == null) return 0;
    final v = double.tryParse(match.group(1)!);
    _voltage = v ?? 0;
    return _voltage;
  }

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
    final bytes = m
        .group(1)!
        .split(RegExp(r'\s+'))
        .where((t) => RegExp(r'^[0-9A-Fa-f]+$').hasMatch(t))
        .map((t) => int.parse(t, radix: 16))
        .toList();
    if (bytes.isEmpty) return null;
    return _applyFormula(pid, bytes);
  }

  double _applyFormula(ObdPid pid, List<int> b) {
    switch (pid) {
      case ObdPid.coolant:
      case ObdPid.intake:
        return (b[0] - 40).toDouble();
      case ObdPid.rpm:
        return ((b[0] << 8) + b[1]) / 4;
      case ObdPid.speed:
        return b[0].toDouble();
      case ObdPid.maf:
        return ((b[0] << 8) + b[1]) / 100;
      case ObdPid.throttle:
      case ObdPid.fuelLevel:
        return b[0] * 100 / 255;
      case ObdPid.voltage:
        return b[0].toDouble();
    }
  }

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
    final tokens = m
        .group(0)!
        .split(RegExp(r'\s+'))
        .where((t) => RegExp(r'^[0-9A-Fa-f]+$').hasMatch(t))
        .map((t) => int.parse(t, radix: 16))
        .toList();
    if (tokens.isEmpty) return [];
    final payload = tokens.sublist(1);
    final result = <DtcCode>[];
    for (var i = 0; i + 1 < payload.length; i += 2) {
      final b1 = payload[i];
      final b2 = payload[i + 1];
      if (b1 == 0 && b2 == 0) continue;
      final prefix = switch (b1 >> 6) {
        0 => 'P',
        1 => 'C',
        2 => 'B',
        _ => 'U',
      };
      final d2 = (b1 >> 4) & 0x03;
      final d3 = b1 & 0x0F;
      final d4 = b2 >> 4;
      final d5 = b2 & 0x0F;
      final code = '$prefix$d2${d3.toRadixString(16).toUpperCase()}'
          '${d4.toRadixString(16).toUpperCase()}'
          '${d5.toRadixString(16).toUpperCase()}';
      result.add(DtcCode(
        code: code,
        description: _describe(code),
        system: _systemFor(code),
        severity: _severityFor(code),
        frozen: false,
      ));
    }
    return result;
  }

  Future<void> clearDtc() async {
    await _command('04');
  }

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

  String _systemFor(String code) {
    if (code.startsWith('P')) return 'وحدة التحكم بالمحرك ECU';
    if (code.startsWith('C')) return 'الشاسيه والمكابح ABS';
    if (code.startsWith('B')) return 'جسم السيارة BCM';
    return 'الاتصالات والشبكة';
  }

  DtcSeverity _severityFor(String code) {
    if (code.startsWith('U')) return DtcSeverity.high;
    return DtcSeverity.medium;
  }

  String _describe(String code) {
    final known = {
      'P0171': 'الخليط فقير جداً - البنك 1',
      'P0174': 'الخليط فقير جداً - البنك 2',
      'P0300': 'فقدان احتراق عشوائي/متعدد الأسطوانات',
      'P0301': 'فقدان احتراق - الأسطوانة 1',
      'P0302': 'فقدان احتراق - الأسطوانة 2',
      'P0303': 'فقدان احتراق - الأسطوانة 3',
      'P0304': 'فقدان احتراق - الأسطوانة 4',
      'P0420': 'كفاءة المحول الحفاز أقل من الحد - البنك 1',
      'P0430': 'كفاءة المحول الحفاز أقل من الحد - البنك 2',
      'P0442': 'تسرب صغير في نظام الأبخرة EVAP',
      'P0455': 'تسرب كبير في نظام الأبخرة EVAP',
      'P0500': 'عطل في مستشعر سرعة السيارة',
      'P0505': 'عطل في نظام التحكم بالخمول',
      'P0700': 'عطل في نظام التحكم بناقل الحركة',
      'P0101': 'نطاق مستشعر تدفق الهواء MAF غير طبيعي',
      'P0113': 'إشارة مرتفعة لمستشعر حرارة الهواء',
      'P0128': 'حرارة المحرك أقل من المطلوب للتشغيل',
      'P0135': 'عطل في سخان مستشعر الأكسجين - البنك 1',
    };
    return known[code] ?? 'رمز خطأ قرأه التطبيق من وحدة التحكم الإلكترونية';
  }
}
