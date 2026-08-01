import 'dart:async';

import 'obd_models.dart';
import 'obd_transport.dart';

/// CAN FD capable interface. Physically a Bluetooth (BLE/classic) ELM/STN
/// dongle; the FD mode is enabled by the controller via STN commands
/// (`ATAL` / `ATSDL`) after connection.
class CanFdObdTransport implements ObdTransport {
  final BleObdTransport _inner = BleObdTransport();

  @override
  Stream<ObdAdapter> scan() => _inner.scan();

  @override
  Future<void> stopScan() => _inner.stopScan();

  @override
  Future<void> open(ObdAdapter adapter) => _inner.open(adapter);

  @override
  Future<void> write(String data) => _inner.write(data);

  @override
  Future<String> readResponse(
          {Duration timeout = const Duration(seconds: 2)}) =>
      _inner.readResponse(timeout: timeout);

  @override
  Future<void> close() => _inner.close();
}

/// Mock CAN FD dongle for offline testing / demo mode.
class MockCanFdTransport extends MockObdTransport {
  MockCanFdTransport() {
    addMockResponse('ATAL', 'OK');
    addMockResponse('ATSDL', 'OK');
  }

  @override
  Stream<ObdAdapter> scan() async* {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    yield const ObdAdapter(
      id: 'mock:canfd',
      name: 'محول CAN FD (محاكاة)',
      rssi: -50,
      type: ObdTransportType.canFd,
    );
  }
}
