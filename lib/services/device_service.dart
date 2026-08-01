import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/device.dart';
import 'obd/elm327.dart';
import 'obd/obd_models.dart';
import 'obd/obd_transport.dart';

abstract class DeviceService {
  Stream<ObdAdapter> scanDevices();
  Future<void> stopScan();
  Future<DeviceInfo> connectToAdapter(ObdAdapter adapter);
  Future<void> disconnect();
  Stream<int> batteryStream();
  Elm327Controller? get controller;
  void dispose();
}

class Elm327DeviceService implements DeviceService {
  Elm327DeviceService({bool enableMock = false})
      : _enableMock = enableMock;

  final bool _enableMock;
  Elm327Controller? _controller;
  ObdTransport? _activeTransport;
  final _batteryController = StreamController<int>.broadcast();
  Timer? _voltageTimer;
  int _batteryLevel = 0;

  @override
  Elm327Controller? get controller => _controller;

  @override
  Stream<ObdAdapter> scanDevices() {
    final merged = StreamController<ObdAdapter>.broadcast();

    StreamSubscription<ObdAdapter>? classicSub;
    StreamSubscription<ObdAdapter>? mockSub;
    bool bleDone = false;
    void closeStreamIfDone() {
      if (bleDone) return;
      bleDone = true;
      classicSub?.cancel();
      mockSub?.cancel();
      if (!merged.isClosed) merged.close();
    }

    final ble = BleObdTransport();
    ble.scan().listen(
          (adapter) => merged.add(adapter),
          onError: (e) => merged.addError(e),
          onDone: closeStreamIfDone,
        );

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        ClassicObdTransport.isSupported) {
      final classic = ClassicObdTransport();
      classicSub = classic.scan().listen(
            (adapter) => merged.add(adapter),
            onError: (e) => merged.addError(e),
          );
    }

    if (_enableMock) {
      final mock = MockObdTransport();
      mockSub = mock.scan().listen(
            (adapter) => merged.add(adapter),
            onError: (e) => merged.addError(e),
          );
    }

    merged.onCancel = () {
      classicSub?.cancel();
      mockSub?.cancel();
      FlutterBluePlus.stopScan();
    };

    return merged.stream;
  }

  @override
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await ClassicObdTransport().stopScan();
    }
  }

  @override
  Future<DeviceInfo> connectToAdapter(ObdAdapter adapter) async {
    await disconnect();

    _activeTransport = _transportFor(adapter.type);
    _controller = Elm327Controller(_activeTransport!);
    await _controller!.open(adapter);

    final voltage = _controller!.voltage;
    _batteryLevel = _scaleVoltage(voltage);

    _voltageTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_controller == null || !_controller!.connected) return;
      final v = await _controller!.readVoltage();
      _batteryLevel = _scaleVoltage(v);
      if (!_batteryController.isClosed) {
        _batteryController.add(_batteryLevel);
      }
    });

    final protocol = _controller!.protocol;
    return DeviceInfo(
      name: adapter.name,
      model: 'ELM327',
      serial: adapter.id,
      firmware: _controller!.version,
      batteryLevel: _batteryLevel,
      batteryCapacityMah: 0,
      charging: false,
      canFdSupported: protocol.contains('FD'),
      doipSupported: false,
      oscilloscope4ch: false,
      softwareVersion: _controller!.version,
      connectionMethod: ConnectionMethod.bluetooth,
    );
  }

  ObdTransport _transportFor(ObdTransportType type) {
    switch (type) {
      case ObdTransportType.ble:
        return BleObdTransport();
      case ObdTransportType.classic:
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          return ClassicObdTransport();
        }
        throw StateError('البلوتوث الكلاسيكي غير مدعوم على هذا النظام');
      case ObdTransportType.mock:
        return MockObdTransport();
    }
  }

  int _scaleVoltage(double v) {
    if (v <= 0) return 100;
    final pct = ((v - 11.5) / 1.5) * 100;
    return pct.clamp(0, 100).round();
  }

  @override
  Future<void> disconnect() async {
    _voltageTimer?.cancel();
    _voltageTimer = null;
    await _controller?.close();
    _controller = null;
    _activeTransport = null;
  }

  @override
  Stream<int> batteryStream() => _batteryController.stream;

  @override
  void dispose() {
    _voltageTimer?.cancel();
    _batteryController.close();
  }
}
