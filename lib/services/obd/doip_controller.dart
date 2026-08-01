import 'dart:async';
import 'dart:typed_data';

import '../../models/dtc.dart';
import 'doip_transport.dart';
import 'obd_controller.dart';
import 'obd_helpers.dart';
import 'obd_models.dart';

/// UDS (ISO 14229) diagnostic controller running over a DoIP (ISO 13400)
/// Ethernet gateway.
class DoipController implements ObdController {
  DoipController(this._client);

  final DoipClient _client;
  bool _connected = false;

  @override
  bool get connected => _connected;
  @override
  String get version => 'DoIP ISO 13400-2';  @override
  String get protocol => 'DoIP / UDS (Ethernet)';
  @override
  double get voltage => 0;

  @override
  Future<void> open(ObdAdapter adapter) async {
    await _client.open(adapter);
    _connected = true;
  }

  @override
  Future<void> close() async {
    _connected = false;
    await _client.close();
  }

  @override
  Future<double> readVoltage() async => 0;

  @override
  Future<double?> readPid(ObdPid pid) async {
    if (pid == ObdPid.voltage) return null;
    final response = await _request([0x22, 0xF1, pid.code]);
    if (response == null || response.length < 3) return null;
    return applyPidFormula(pid, response.sublist(3));
  }

  @override
  Future<List<DtcCode>> readDtc() async {
    final response = await _request([0x19, 0x02, 0xFF]);
    if (response == null || response.length < 3) return const [];
    final rest = response.sublist(2);
    var offset = 0;
    while (offset < rest.length && (rest.length - offset) % 3 != 0) {
      offset++;
    }
    final codes = <DtcCode>[];
    for (var i = offset; i + 2 < rest.length; i += 3) {
      final b1 = rest[i];
      final b2 = rest[i + 1];
      if (b1 == 0 && b2 == 0) continue;
      final code = dtcCodeFromBytes(b1, b2);
      codes.add(DtcCode(
        code: code,
        description: dtcDescription(code),
        system: dtcSystem(code),
        severity: dtcSeverity(code),
        frozen: (rest[i + 2] & 0x08) != 0,
      ));
    }
    return codes;
  }

  @override
  Future<void> clearDtc() async {
    await _request([0x14, 0xFF, 0xFF, 0xFF]);
  }

  @override
  Future<String?> readVin() async {
    final response = await _request([0x22, 0xF1, 0x90]);
    if (response == null || response.length < 4) return null;
    final vin = String.fromCharCodes(response
        .sublist(3)
        .where((b) => b >= 0x20 && b <= 0x7E));
    return vin.trim().isEmpty ? null : vin;
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
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  Future<List<int>?> _request(List<int> uds) async {
    final response = await _client.requestUds(Uint8List.fromList(uds));
    if (response == null || response.isEmpty) return null;
    if (response.first == 0x7F) return null;
    return response;
  }
}
