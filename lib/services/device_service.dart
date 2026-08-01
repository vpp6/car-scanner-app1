import 'dart:async';

import '../models/device.dart';
import 'mock_data.dart';

abstract class DeviceService {
  Future<DeviceInfo> connect(ConnectionMethod method);
  Future<void> disconnect();
  Stream<int> batteryStream();
}

class MockDeviceService implements DeviceService {
  final _batteryController = StreamController<int>.broadcast();
  Timer? _timer;
  int _level = MockData.device.batteryLevel;
  bool _connected = false;

  @override
  Future<DeviceInfo> connect(ConnectionMethod method) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    _connected = true;
    _startBatterySimulation();
    return MockData.device.copyWith(method: method);
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _timer?.cancel();
  }

  @override
  Stream<int> batteryStream() => _batteryController.stream;

  void _startBatterySimulation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!_connected) return;
      _level = (_level - 1).clamp(0, 100);
      _batteryController.add(_level);
    });
  }
}

extension on DeviceInfo {
  DeviceInfo copyWith({ConnectionMethod? method}) => DeviceInfo(
        name: name,
        model: model,
        serial: serial,
        firmware: firmware,
        batteryLevel: batteryLevel,
        batteryCapacityMah: batteryCapacityMah,
        charging: charging,
        canFdSupported: canFdSupported,
        doipSupported: doipSupported,
        oscilloscope4ch: oscilloscope4ch,
        softwareVersion: softwareVersion,
        connectionMethod: method ?? connectionMethod,
      );
}
