import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/device.dart';
import '../models/dtc.dart';
import '../models/vehicle.dart';
import '../services/device_service.dart';
import '../services/obd/obd_models.dart';
import '../services/scan_service.dart';

class AppState extends ChangeNotifier {
  AppState({DeviceService? deviceService, ScanService? scanService})
      : _deviceService = deviceService ?? Elm327DeviceService(enableMock: true),
        _scanService = scanService ?? Elm327ScanService(deviceService ?? Elm327DeviceService(enableMock: true)) {
    _batterySub = _deviceService.batteryStream().listen((level) {
      _batteryLevel = level;
      notifyListeners();
    });
  }

  final DeviceService _deviceService;
  final ScanService _scanService;
  StreamSubscription<int>? _batterySub;
  StreamSubscription<Map<ObdPid, double>>? _liveSub;

  DeviceStatus _status = DeviceStatus.disconnected;
  DeviceInfo? _device;
  Vehicle? _vehicle;
  List<VehicleSystem> _systems = const [];
  Map<String, List<DtcCode>> _codes = const {};
  Map<ObdPid, double> _liveData = const {};
  int _batteryLevel = 0;
  String _error = '';

  DeviceStatus get status => _status;
  DeviceInfo? get device => _device;
  Vehicle? get vehicle => _vehicle;
  List<VehicleSystem> get systems => _systems;
  Map<String, List<DtcCode>> get codes => _codes;
  Map<ObdPid, double> get liveData => _liveData;
  int get batteryLevel => _batteryLevel;
  String get error => _error;
  String? get vin => _vehicle?.vin;

  bool get isConnected => _status == DeviceStatus.connected;

  int get totalDtcCount {
    var count = 0;
    for (final list in _codes.values) {
      count += list.length;
    }
    return count;
  }

  Stream<ObdAdapter> scanDevices() => _deviceService.scanDevices();

  Future<void> stopScan() => _deviceService.stopScan();

  Future<bool> connectToAdapter(ObdAdapter adapter) async {
    _error = '';
    _status = DeviceStatus.connecting;
    notifyListeners();
    try {
      _device = await _deviceService.connectToAdapter(adapter);
      _batteryLevel = _device!.batteryLevel;
      _status = DeviceStatus.connected;
      _startLiveData();
      _readVinAfterConnect();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = DeviceStatus.disconnected;
      notifyListeners();
      return false;
    }
  }

  Future<bool> connect(ConnectionMethod method) async {
    if (method != ConnectionMethod.bluetooth) {
      _error = 'وحدات ELM327 تدعم الاتصال عبر البلوتوث فقط';
      notifyListeners();
      return false;
    }
    final adapters = <ObdAdapter>[];
    final sub = _deviceService.scanDevices().listen((a) => adapters.add(a));
    await Future<void>.delayed(const Duration(seconds: 4));
    await sub.cancel();
    await _deviceService.stopScan();
    if (adapters.isEmpty) {
      _error = 'لم يتم العثور على أي جهاز OBD - تحقق من تشغيل الجهاز والبلوتوث';
      notifyListeners();
      return false;
    }
    return connectToAdapter(adapters.first);
  }

  void _startLiveData() {
    _liveSub?.cancel();
    final controller = _deviceService.controller;
    if (controller == null) return;
    _liveSub = controller.liveDataStream().listen((data) {
      _liveData = data;
      notifyListeners();
    });
  }

  Future<void> _readVinAfterConnect() async {
    try {
      final controller = _deviceService.controller;
      if (controller == null) return;
      final vin = await controller.readVin();
      if (vin == null || vin.isEmpty) return;
      _vehicle = Vehicle(
        vin: vin,
        make: 'غير محدد',
        model: 'غير محدد',
        year: 0,
        engine: '',
        fuel: '',
        odometer: '',
        plate: '',
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> disconnect() async {
    await _deviceService.disconnect();
    _liveSub?.cancel();
    _liveSub = null;
    _status = DeviceStatus.disconnected;
    _device = null;
    _codes = const {};
    _liveData = const {};
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
    _liveSub?.cancel();
    _deviceService.dispose();
    super.dispose();
  }
}
