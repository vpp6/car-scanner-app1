import 'dart:async';

import '../models/dtc.dart';
import '../models/vehicle.dart';
import 'device_service.dart';

abstract class ScanService {
  Future<List<VehicleSystem>> readSystems();
  Future<List<ScanReport>> quickScan();
  Future<Map<String, List<DtcCode>>> readCodes();
  Future<void> clearCodes();
}

/// Real ELM327 OBD-II scan service.
class Elm327ScanService implements ScanService {
  Elm327ScanService(this._deviceService);

  final DeviceService _deviceService;

  bool get _ready => _deviceService.controller?.connected ?? false;

  @override
  Future<List<VehicleSystem>> readSystems() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const [
      VehicleSystem(
          id: 'ecu', name: 'وحدة التحكم بالمحرك ECU', icon: 'motor', supported: true),
      VehicleSystem(
          id: 'abs', name: 'المكابح ABS', icon: 'brake', supported: true),
      VehicleSystem(
          id: 'airbag', name: 'الوسائد الهوائية SRS', icon: 'shield', supported: true),
    ];
  }

  @override
  Future<List<ScanReport>> quickScan() async {
    final codes = await readCodes();
    final reports = <ScanReport>[];
    for (final system in [
      ('وحدة التحكم بالمحرك ECU', 'motor'),
      ('المكابح ABS', 'brake'),
      ('الوسائد الهوائية SRS', 'shield'),
    ]) {
      final list = codes[system.$1] ?? const <DtcCode>[];
      reports.add(ScanReport(
        system: system.$1,
        icon: system.$2,
        codes: list.length,
        status: list.isEmpty ? ScanStatus.ok : ScanStatus.codes,
      ));
    }
    return reports;
  }

  @override
  Future<Map<String, List<DtcCode>>> readCodes() async {
    if (!_ready) return const {};
    final dtc = await _deviceService.controller!.readDtc();
    final grouped = <String, List<DtcCode>>{};
    for (final code in dtc) {
      grouped.putIfAbsent(code.system, () => []).add(code);
    }
    return grouped;
  }

  @override
  Future<void> clearCodes() async {
    if (!_ready) return;
    await _deviceService.controller!.clearDtc();
  }
}

class MockScanService implements ScanService {
  final List<DtcCode> _sample = const [
    DtcCode(
      code: 'P0135',
      description: 'عطل في سخان مستشعر الأكسجين - البنك 1',
      system: 'وحدة التحكم بالمحرك ECU',
      severity: DtcSeverity.medium,
      frozen: false,
    ),
  ];

  @override
  Future<List<VehicleSystem>> readSystems() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const [
      VehicleSystem(
          id: 'ecu', name: 'وحدة التحكم بالمحرك ECU', icon: 'motor', supported: true),
    ];
  }

  @override
  Future<List<ScanReport>> quickScan() async {
    await Future<void>.delayed(const Duration(seconds: 3));
    return const [
      ScanReport(
          system: 'وحدة التحكم بالمحرك ECU',
          icon: 'motor',
          codes: 1,
          status: ScanStatus.codes),
    ];
  }

  @override
  Future<Map<String, List<DtcCode>>> readCodes() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return {'وحدة التحكم بالمحرك ECU': _sample};
  }

  @override
  Future<void> clearCodes() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
}

Stream<double> scanProgress() {
  final controller = StreamController<double>();
  var value = 0.0;
  Timer.periodic(const Duration(milliseconds: 200), (timer) {
    value += 0.04 + (value * 0.01);
    if (value >= 1) {
      value = 1;
      timer.cancel();
      controller.close();
    }
    controller.add(value);
  });
  return controller.stream;
}
