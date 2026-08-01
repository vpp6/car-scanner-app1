import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as fbs;

import 'obd_models.dart';

abstract class ObdTransport {
  Stream<ObdAdapter> scan();
  Future<void> stopScan();
  Future<void> open(ObdAdapter adapter);
  Future<void> write(String data);
  Future<String> readResponse({Duration timeout});
  Future<void> close();
}

bool _looksLikeObd(String name) {
  final n = name.toLowerCase();
  return n.contains('obd') ||
      n.contains('elm') ||
      n.contains('v-link') ||
      n.contains('vlink') ||
      n.contains('car') ||
      n.contains('scanner') ||
      n.contains('autel') ||
      n.contains('vgate') ||
      n.contains('kobd') ||
      n.contains('obdlink') ||
      n.contains('blue');
}

/// BLE adapter (iOS + Android). Most ELM327 "Bluetooth 4.0/5.0" dongles.
class BleObdTransport implements ObdTransport {
  fbp.BluetoothDevice? _device;
  fbp.BluetoothCharacteristic? _writeChar;
  fbp.BluetoothCharacteristic? _notifyChar;
  StreamSubscription<List<int>>? _valueSub;
  StreamController<List<int>>? _incoming;
  StreamIterator<List<int>>? _iterator;

  static const _preferredService = 'fff0';
  static const _preferredWrite = 'fff2';
  static const _preferredNotify = 'fff1';

  @override
  Stream<ObdAdapter> scan() {
    final controller = StreamController<ObdAdapter>();

    fbp.FlutterBluePlus.adapterState.first.then((state) {
      if (state == fbp.BluetoothAdapterState.off) {
        if (!controller.isClosed) {
          controller.addError(StateError('بلوتوث الجهاز مغلق - فضلاً قم بتشغيله'));
        }
      }
    });

    fbp.FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 12),
      androidUsesFineLocation: true,
    );

    final sub = fbp.FlutterBluePlus.scanResults.listen((results) {
      if (controller.isClosed) return;
      for (final r in results) {
        final name = r.device.platformName;
        if (name.isEmpty || !_looksLikeObd(name)) continue;
        controller.add(ObdAdapter(
          id: r.device.remoteId.str,
          name: name,
          rssi: r.rssi,
          type: ObdTransportType.ble,
        ));
      }
    });
    final scanSub = fbp.FlutterBluePlus.isScanning.listen((isScanning) {
      if (!isScanning) {
        sub.cancel();
        if (!controller.isClosed) controller.close();
      }
    });

    controller.onCancel = () {
      sub.cancel();
      scanSub.cancel();
      fbp.FlutterBluePlus.stopScan();
    };

    return controller.stream;
  }

  @override
  Future<void> stopScan() async {
    await fbp.FlutterBluePlus.stopScan();
  }

  @override
  Future<void> open(ObdAdapter adapter) async {
    _device = fbp.BluetoothDevice.fromId(adapter.id);
    await _device!.connect(
      license: fbp.License.nonprofit,
      timeout: const Duration(seconds: 15),
    );
    await _device!.requestMtu(185);
    await _device!.discoverServices();

    for (final service in _device!.servicesList) {
      final uuid = service.uuid.str.toLowerCase();
      if (uuid.startsWith(_preferredService)) {
        for (final c in service.characteristics) {
          final cu = c.uuid.str.toLowerCase();
          if (cu == _preferredNotify) _notifyChar = c;
          if (cu == _preferredWrite) _writeChar = c;
        }
      }
    }
    if (_notifyChar == null || _writeChar == null) {
      _findSerialFallback();
    }
    if (_notifyChar == null || _writeChar == null) {
      throw StateError('لم يتم العثور على منفذ تسلسلي في هذا الجهاز');
    }

    await _notifyChar!.setNotifyValue(true);
    _incoming = StreamController<List<int>>();
    _valueSub = _notifyChar!.onValueReceived.listen((value) {
      _incoming?.add(value);
    });
    _iterator = StreamIterator(_incoming!.stream);
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  void _findSerialFallback() {
    for (final service in _device!.servicesList) {
      for (final c in service.characteristics) {
        if (c.properties.write && _writeChar == null) _writeChar = c;
        if (c.properties.notify && _notifyChar == null) _notifyChar = c;
      }
    }
  }

  @override
  Future<void> write(String data) async {
    await _writeChar!.write(data.codeUnits);
  }

  @override
  Future<String> readResponse(
      {Duration timeout = const Duration(seconds: 2)}) async {
    final buffer = StringBuffer();
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final remaining = deadline.difference(DateTime.now());
      if (remaining.isNegative) break;
      final chunk = await _nextChunk(timeout: remaining);
      if (chunk == null) break;
      final text = String.fromCharCodes(chunk);
      buffer.write(text);
      if (text.contains('>')) break;
    }
    return buffer.toString();
  }

  Future<List<int>?> _nextChunk({required Duration timeout}) async {
    if (_iterator == null) return null;
    final ok = await _iterator!.moveNext().timeout(
          timeout,
          onTimeout: () => false,
        );
    return ok ? _iterator!.current : null;
  }

  @override
  Future<void> close() async {
    _valueSub?.cancel();
    _iterator?.cancel();
    await _incoming?.close();
    await fbp.FlutterBluePlus.stopScan();
    if (_device != null && _device!.isConnected) {
      await _device!.disconnect().catchError((_) => null);
    }
    _device = null;
    _writeChar = null;
    _notifyChar = null;
  }
}

/// Bluetooth Classic (Android only). Older ELM327 "Bluetooth" dongles.
class ClassicObdTransport implements ObdTransport {
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  fbs.BluetoothConnection? _connection;
  StreamController<List<int>>? _incoming;
  StreamIterator<List<int>>? _iterator;
  StreamSubscription<dynamic>? _discSub;

  @override
  Stream<ObdAdapter> scan() {
    final controller = StreamController<ObdAdapter>();
    if (!isSupported) {
      scheduleMicrotask(controller.close);
      return controller.stream;
    }
    final api = fbs.FlutterBluetoothSerial.instance;

    api.state.then((state) {
      if (state == fbs.BluetoothState.STATE_OFF) {
        if (!controller.isClosed) {
          controller.addError(StateError('بلوتوث الجهاز مغلق - فضلاً قم بتشغيله'));
        }
      }
    });

    api.getBondedDevices().then((devices) {
      if (controller.isClosed) return;
      for (final d in devices) {
        final name = d.name ?? '';
        if (name.isNotEmpty && _looksLikeObd(name)) {
          controller.add(
              ObdAdapter(id: d.address, name: name, type: ObdTransportType.classic));
        }
      }
    });

    _discSub = api.startDiscovery().listen((result) {
      if (controller.isClosed) return;
      final name = result.device.name ?? '';
      if (name.isNotEmpty && _looksLikeObd(name)) {
        controller.add(ObdAdapter(
          id: result.device.address,
          name: name,
          rssi: result.rssi,
          type: ObdTransportType.classic,
        ));
      }
    }, onError: (_) {});

    controller.onCancel = () {
      _discSub?.cancel();
      api.cancelDiscovery();
    };

    return controller.stream;
  }

  @override
  Future<void> stopScan() async {
    if (isSupported) {
      await fbs.FlutterBluetoothSerial.instance.cancelDiscovery();
    }
  }

  @override
  Future<void> open(ObdAdapter adapter) async {
    if (!isSupported) {
      throw StateError('البلوتوث الكلاسيكي غير مدعوم على هذا النظام');
    }
    final conn = await fbs.BluetoothConnection.toAddress(adapter.id);
    _connection = conn;
    _incoming = StreamController<List<int>>();
    conn.input?.listen((data) {
      _incoming?.add(data);
    });
    _iterator = StreamIterator(_incoming!.stream);
  }

  @override
  Future<void> write(String data) async {
    _connection?.output.add(Uint8List.fromList(data.codeUnits));
  }

  @override
  Future<String> readResponse(
      {Duration timeout = const Duration(seconds: 2)}) async {
    final buffer = StringBuffer();
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final remaining = deadline.difference(DateTime.now());
      if (remaining.isNegative) break;
      final chunk = await _nextChunk(timeout: remaining);
      if (chunk == null) break;
      final text = String.fromCharCodes(chunk);
      buffer.write(text);
      if (text.contains('>')) break;
    }
    return buffer.toString();
  }

  Future<List<int>?> _nextChunk({required Duration timeout}) async {
    if (_iterator == null) return null;
    final ok = await _iterator!.moveNext().timeout(
          timeout,
          onTimeout: () => false,
        );
    return ok ? _iterator!.current : null;
  }

  @override
  Future<void> close() async {
    await _connection?.close();
    _connection = null;
    _iterator?.cancel();
    await _incoming?.close();
  }
}

/// Mock ELM327 for offline testing / demo mode.
class MockObdTransport implements ObdTransport {
  bool _connected = false;
  String? _lastCommand;

  final Map<String, String> _responses = {
    'ATZ': 'ELM327 v1.5',
    'ATE0': 'OK',
    'ATL0': 'OK',
    'ATH0': 'OK',
    'ATSP0': 'OK',
    'ATDP': 'AUTO, ISO 15765-4 (CAN 11/500)',
    'ATRV': '12.6V',
    '0100': '41 00 BE 3E B8 11',
    '0105': '41 05 5A',
    '010C': '41 0C 1A F8',
    '010D': '41 0D 3C',
    '010F': '41 0F 32',
    '0110': '41 10 05 DC',
    '0111': '41 11 1A',
    '012F': '41 2F 46',
    '03': '43 01 33 00 00 00',
    '0A': '43 0A 13 00 00 00',
    '04': '44',
    '0902': '014:49 02 01 4C 46 56 33 41 32 33 4B',
  };

  /// Injects/overrides a canned response (used by CAN FD and test scenarios).
  void addMockResponse(String command, String response) {
    _responses[command] = response;
  }

  @override
  Stream<ObdAdapter> scan() async* {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    yield const ObdAdapter(
        id: 'mock:obd1',
        name: 'فاحص برو X1 (محاكاة)',
        rssi: -45,
        type: ObdTransportType.mock);
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> open(ObdAdapter adapter) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _connected = true;
  }

  @override
  Future<void> write(String data) async {
    _lastCommand = data.trim();
  }

  @override
  Future<String> readResponse(
      {Duration timeout = const Duration(seconds: 2)}) async {
    if (!_connected) return '>';
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final cmd = _lastCommand;
    _lastCommand = null;
    final resp = _responses[cmd] ?? 'NO DATA';
    return '$resp>';
  }

  @override
  Future<void> close() async {
    _connected = false;
  }
}
