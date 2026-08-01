import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'obd_models.dart';

/// DoIP (ISO 13400-2) client over TCP/UDP with a UDS (ISO 14229) payload.
abstract class DoipClient {
  Stream<ObdAdapter> scan();
  Future<void> open(ObdAdapter adapter);
  Future<Uint8List?> requestUds(Uint8List uds);
  Future<void> close();
}

class DoipTransport implements DoipClient {
  static const int defaultPort = 13400;
  static const int _protocolVersion = 0x02;
  static const int _inverseVersion = 0xFD;
  static const int _gatewayAddress = 0x0000;

  static const int _ptVehicleIdentificationRequest = 0x0002;
  static const int _ptVehicleAnnouncementResponse = 0x0004;
  static const int _ptRoutingActivationRequest = 0x0005;
  static const int _ptRoutingActivationResponse = 0x0006;
  static const int _ptDiagnosticMessage = 0x8001;

  Socket? _socket;
  int _logicalAddress = 0;
  StreamController<List<int>>? _rx;
  final List<int> _buffer = [];

  // ---------------------------------------------------------------- framing

  List<int> _frame(int payloadType, List<int> payload) {
    return [
      _protocolVersion,
      _inverseVersion,
      (payloadType >> 8) & 0xFF,
      payloadType & 0xFF,
      (payload.length >> 24) & 0xFF,
      (payload.length >> 16) & 0xFF,
      (payload.length >> 8) & 0xFF,
      payload.length & 0xFF,
      ...payload,
    ];
  }

  // ------------------------------------------------------------------ scan

  @override
  Stream<ObdAdapter> scan() {
    final controller = StreamController<ObdAdapter>();
    if (kIsWeb) {
      scheduleMicrotask(controller.close);
      return controller.stream;
    }
    unawaited(_udpDiscover(controller));
    return controller.stream;
  }

  Future<void> _udpDiscover(StreamController<ObdAdapter> controller) async {
    RawDatagramSocket? socket;
    try {
      socket =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0, reusePort: true);
    } catch (_) {
      if (!controller.isClosed) controller.close();
      return;
    }
    socket.broadcastEnabled = true;
    final request = _frame(_ptVehicleIdentificationRequest, const []);
    try {
      socket.send(request, InternetAddress('224.244.224.245'), defaultPort);
      socket.send(request, InternetAddress('255.255.255.255'), defaultPort);
    } catch (_) {}

    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket?.receive();
      if (datagram == null) return;
      final vin = _parseVehicleAnnouncement(datagram.data);
      if (vin == null || controller.isClosed) return;
      controller.add(ObdAdapter(
        id: 'doip:${datagram.address.address}',
        name: 'بوابة DoIP - VIN: $vin',
        host: datagram.address.address,
        port: defaultPort,
        type: ObdTransportType.doip,
      ));
    });

    controller.onCancel = () => socket?.close();

    Future<void>.delayed(const Duration(seconds: 6), () {
      socket?.close();
      if (!controller.isClosed) controller.close();
    });
  }

  String? _parseVehicleAnnouncement(List<int> data) {
    if (data.length < 8 + 25) return null;
    final type = (data[2] << 8) | data[3];
    if (type != _ptVehicleAnnouncementResponse) return null;
    final vin = String.fromCharCodes(data.sublist(8, 25));
    if (vin.trim().isEmpty) return null;
    return vin;
  }

  // ------------------------------------------------------------------ open

  @override
  Future<void> open(ObdAdapter adapter) async {
    final host = adapter.host;
    if (host == null || host.isEmpty) {
      throw StateError('عنوان IP الخاص ببوابة DoIP غير محدد');
    }
    _rx = StreamController<List<int>>.broadcast(sync: true);
    _socket = await Socket.connect(
      host,
      adapter.port ?? defaultPort,
      timeout: const Duration(seconds: 6),
    );
    _socket!.listen(
      _onData,
      onDone: () => _rx?.close(),
      onError: (_) {},
    );
    await _routingActivation();
  }

  void _onData(List<int> data) {
    _buffer.addAll(data);
    while (_buffer.length >= 8) {
      final length = (_buffer[4] << 24) |
          (_buffer[5] << 16) |
          (_buffer[6] << 8) |
          _buffer[7];
      if (_buffer.length < 8 + length) return;
      final frame = List<int>.from(_buffer.sublist(0, 8 + length));
      _buffer.removeRange(0, 8 + length);
      _rx?.add(frame);
    }
  }

  Future<void> _routingActivation() async {
    // Vehicle Identification Request -> expect Vehicle Announcement.
    _send(_ptVehicleIdentificationRequest, const []);
    final announcement = await _waitFor(
      _ptVehicleAnnouncementResponse,
      timeout: const Duration(seconds: 5),
    );
    if (announcement == null) {
      throw StateError('لا يوجد استجابة من بوابة DoIP');
    }

    // Routing Activation Request (tester address 0x0000, type 0x00).
    _send(_ptRoutingActivationRequest, const [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
    final response = await _waitFor(
      _ptRoutingActivationResponse,
      timeout: const Duration(seconds: 5),
    );
    if (response == null || response.length < 5) {
      throw StateError('فشل تفعيل التوجيه على بوابة DoIP');
    }
    final activationCode = response[4];
    if (activationCode != 0x10) {
      throw StateError('رفض تفعيل التوجيه (رمز $activationCode)');
    }
    _logicalAddress = (response[2] << 8) | response[3];
  }

  void _send(int payloadType, List<int> payload) {
    _socket?.add(_frame(payloadType, payload));
    _socket?.flush();
  }

  // ------------------------------------------------------------------ UDS

  @override
  Future<Uint8List?> requestUds(Uint8List uds) async {
    if (_socket == null) return null;
    final payload = [
      (_logicalAddress >> 8) & 0xFF,
      _logicalAddress & 0xFF,
      (_gatewayAddress >> 8) & 0xFF,
      _gatewayAddress & 0xFF,
      ...uds,
    ];
    _send(_ptDiagnosticMessage, payload);
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (true) {
      final remaining = deadline.difference(DateTime.now());
      if (remaining.isNegative) return null;
      final frame = await _waitFor(
        _ptDiagnosticMessage,
        timeout: remaining,
      );
      if (frame == null) return null;
      if (frame.length <= 4) continue;
      final udsResponse = frame.sublist(4);
      if (udsResponse.isNotEmpty && udsResponse.first == 0x7F) return null;
      return Uint8List.fromList(udsResponse);
    }
  }

  Future<List<int>?> _waitFor(int type, {required Duration timeout}) {
    final completer = Completer<List<int>?>();
    late StreamSubscription<List<int>> sub;
    final rx = _rx;
    if (rx == null) {
      return Future.value(null);
    }
    sub = rx.stream.listen((frame) {
      final frameType = (frame[2] << 8) | frame[3];
      if (frameType == type) {
        if (!completer.isCompleted) completer.complete(frame.sublist(8));
        sub.cancel();
      }
    });
    Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(null);
        sub.cancel();
      }
    });
    return completer.future;
  }

  // ----------------------------------------------------------------- close

  @override
  Future<void> close() async {
    await _rx?.close();
    _rx = null;
    await _socket?.close();
    _socket = null;
    _buffer.clear();
  }
}

/// Canned DoIP/UDS responses for offline testing / demo mode.
class MockDoipClient implements DoipClient {
  bool _connected = false;

  @override
  Stream<ObdAdapter> scan() async* {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    yield const ObdAdapter(
      id: 'mock:doip',
      name: 'بوابة DoIP (محاكاة)',
      host: 'mock',
      port: 13400,
      type: ObdTransportType.doip,
    );
  }

  @override
  Future<void> open(ObdAdapter adapter) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _connected = true;
  }

  @override
  Future<Uint8List?> requestUds(Uint8List uds) async {
    if (!_connected) return null;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (uds.isEmpty) return null;
    switch (uds.first) {
      case 0x22: // ReadDataByIdentifier
        if (uds.length < 3) return null;
        final didHi = uds[1];
        final didLo = uds[2];
        if (didHi == 0xF1 && didLo == 0x90) {
          return Uint8List.fromList(
            [0x62, 0xF1, 0x90, ...'LFV3A23KDOIP00001'.codeUnits],
          );
        }
        if (didHi != 0xF1) return null;
        final data = switch (didLo) {
          0x05 => [0x5A],
          0x0C => [0x1A, 0xF8],
          0x0D => [0x3C],
          0x0F => [0x32],
          0x10 => [0x05, 0xDC],
          0x11 => [0x1A],
          0x2F => [0x46],
          _ => null,
        };
        if (data == null) return null;
        return Uint8List.fromList([0x62, 0xF1, didLo, ...data]);
      case 0x19: // ReadDTCInformation (reportDTCByStatusMask)
        return Uint8List.fromList([0x59, 0x02, 0x01, 0x01, 0x33, 0x00]);
      case 0x14: // ClearDiagnosticInformation
        return Uint8List.fromList([0x54]);
    }
    return null;
  }

  @override
  Future<void> close() async {
    _connected = false;
  }
}
