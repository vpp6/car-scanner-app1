import 'dart:async';

import '../models/dtc.dart';
import '../models/vehicle.dart';
import 'mock_data.dart';

abstract class ScanService {
  Future<List<VehicleSystem>> readSystems();
  Future<List<ScanReport>> quickScan();
  Future<Map<String, List<DtcCode>>> readCodes();
  Future<void> clearCodes();
}

class MockScanService implements ScanService {
  @override
  Future<List<VehicleSystem>> readSystems() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return MockData.vehicleSystems;
  }

  @override
  Future<List<ScanReport>> quickScan() async {
    await Future<void>.delayed(const Duration(seconds: 4));
    return MockData.scanReports;
  }

  @override
  Future<Map<String, List<DtcCode>>> readCodes() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return MockData.dtcBySystem;
  }

  @override
  Future<void> clearCodes() async {
    await Future<void>.delayed(const Duration(seconds: 2));
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
