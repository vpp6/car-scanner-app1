import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/device.dart';
import 'obd/canfd_transport.dart';
import 'obd/doip_controller.dart';
import 'obd/doip_transport.dart';
import 'obd/elm327.dart';
import 'obd/obd_controller.dart';
import 'obd/obd_models.dart';
import 'obd/obd_transport.dart';

abstract class DeviceService {
  Stream<ObdAdapter> scanDevices();
  Future<void> stopScan();
  Future<DeviceInfo> connectToAdapter(ObdAdapter adapter);
  Future<void> disconnect();
  Stream<int> batteryStream();
  ObdController? get controller;
  void dispose();
}

class Elm327DeviceService implements DeviceService {
  Elm327DeviceService({bool enableMock = false})
      : _enableMock = enableMock;

  final bool _enableMock;
  ObdController? _controller;
  final _batteryController = StreamController<int>.broadcast();
  Timer? _voltageTimer;
  int _batteryLevel = 0;

  @override
  ObdController? get controller => _controller;

  @override
  Stream<ObdAdapter> scanDevices() {
    final merged = StreamController<ObdAdapter>.broadcast();

    StreamSubscription<ObdAdapter>? classicSub;
    StreamSubscription<ObdAdapter>? mockSub;
    StreamSubscription<ObdAdapter>? mockFdSub;
    StreamSubscription<ObdAdapter>? mockDoipSub;
    bool bleDone = false;
    void closeStreamIfDone() {
      if (bleDone) return;
      bleDone = true;
      classicSub?.cancel();
      mockSub?.cancel();
      mockFdSub?.cancel();
      mockDoipSub?.cancel();
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
      mockSub = MockObdTransport().scan().listen(
            (adapter) => merged.add(adapter),
            onError: (e) => merged.addError(e),
          );
      mockFdSub = MockCanFdTransport().scan().listen(
            (adapter) => merged.add(adapter),
            onError: (e) => merged.addError(e),
          );
      mockDoipSub = MockDoipClient().scan().listen(
            (adapter) => merged.add(adapter),
            onError: (e) => merged.addError(e),
          );
    }

    merged.onCancel = () {
      classicSub?.cancel();
      mockSub?.cancel();
      mockFdSub?.cancel();
      mockDoipSub?.cancel();
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

    if (adapter.type == ObdTransportType.doip) {
      return _connectDoip(adapter);
    }

    final transport = _transportFor(adapter);
    final enableCanFd = adapter.type == ObdTransportType.canFd;
    _controller = Elm327Controller(transport, enableCanFd: enableCanFd);
    await _controller!.open(adapter);

    final elm = _controller as Elm327Controller;
    final voltage = elm.voltage;
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
    final canFd = elm.canFd || protocol.contains('FD');
    return DeviceInfo(
      name: adapter.name,
      model: enableCanFd && canFd ? 'ELM327 STN (CAN FD)' : 'ELM327',
      serial: adapter.id,
      firmware: _controller!.version,
      batteryLevel: _batteryLevel,
      batteryCapacityMah: 0,
      charging: false,
      canFdSupported: canFd,
      doipSupported: false,
      oscilloscope4ch: false,
      softwareVersion: _controller!.version,
      connectionMethod: ConnectionMethod.bluetooth,
    );
  }

  Future<DeviceInfo> _connectDoip(ObdAdapter adapter) async {
    final client = adapter.isMock ? MockDoipClient() : DoipTransport();
    _controller = DoipController(client);
    await _controller!.open(adapter);
    _batteryLevel = 100;
    if (!_batteryController.isClosed) {
      _batteryController.add(_batteryLevel);
    }
    return DeviceInfo(
      name: adapter.name,
      model: 'DoIP (ISO 13400-2)',
      serial: adapter.id,
      firmware: 'DoIP / UDS',
      batteryLevel: 100,
      batteryCapacityMah: 0,
      charging: false,
      canFdSupported: false,
      doipSupported: true,
      oscilloscope4ch: false,
      softwareVersion: 'DoIP 1.0',
      connectionMethod: ConnectionMethod.wifi,
    );
  }

  ObdTransport _transportFor(ObdAdapter adapter) {
    switch (adapter.type) {
      case ObdTransportType.ble:
        return BleObdTransport();
      case ObdTransportType.classic:
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          return ClassicObdTransport();
        }
        throw StateError('البلوتوث الكلاسيكي غير مدعوم على هذا النظام');
      case ObdTransportType.canFd:
        return adapter.isMock ? MockCanFdTransport() : CanFdObdTransport();
      case ObdTransportType.mock:
        return MockObdTransport();
      case ObdTransportType.doip:
        throw StateError('DoIP يُدار عبر مسار منفصل');
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
  }

  @override
  Stream<int> batteryStream() => _batteryController.stream;

  @override
  void dispose() {
    _voltageTimer?.cancel();
    _batteryController.close();
  }
}
