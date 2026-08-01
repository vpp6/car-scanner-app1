import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/device.dart';
import '../models/dtc.dart';
import '../models/vehicle.dart';
import '../services/device_service.dart';
import '../services/scan_service.dart';

class AppState extends ChangeNotifier {
  AppState({DeviceService? deviceService, ScanService? scanService})
      : _deviceService = deviceService ?? MockDeviceService(),
        _scanService = scanService ?? MockScanService() {
    _batterySub = _deviceService.batteryStream().listen((level) {
      _batteryLevel = level;
      notifyListeners();
    });
  }

  final DeviceService _deviceService;
  final ScanService _scanService;
  StreamSubscription<int>? _batterySub;

  DeviceStatus _status = DeviceStatus.disconnected;
  DeviceInfo? _device;
  Vehicle? _vehicle;
  List<VehicleSystem> _systems = const [];
  Map<String, List<DtcCode>> _codes = const {};
  int _batteryLevel = 0;

  DeviceStatus get status => _status;
  DeviceInfo? get device => _device;
  Vehicle? get vehicle => _vehicle;
  List<VehicleSystem> get systems => _systems;
  Map<String, List<DtcCode>> get codes => _codes;
  int get batteryLevel => _batteryLevel;

  bool get isConnected => _status == DeviceStatus.connected;

  int get totalDtcCount {
    var count = 0;
    for (final list in _codes.values) {
      count += list.length;
    }
    return count;
  }

  Future<void> connect(ConnectionMethod method) async {
    _status = DeviceStatus.connecting;
    notifyListeners();
    _device = await _deviceService.connect(method);
    _batteryLevel = _device!.batteryLevel;
    _status = DeviceStatus.connected;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _deviceService.disconnect();
    _status = DeviceStatus.disconnected;
    _device = null;
    _codes = const {};
    notifyListeners();
  }

  Future<void> setVehicle(Vehicle vehicle) async {
    _vehicle = vehicle;
    _systems = await _scanService.readSystems();
    notifyListeners();
  }

  Future<void> refreshSystems() async {
    if (_vehicle == null) return;
    _systems = await _scanService.readSystems();
    notifyListeners();
  }

  Future<void> readCodes() async {
    _codes = await _scanService.readCodes();
    notifyListeners();
  }

  Future<void> clearCodes() async {
    await _scanService.clearCodes();
    _codes = const {};
    notifyListeners();
  }

  @override
  void dispose() {
    _batterySub?.cancel();
    super.dispose();
  }
}
