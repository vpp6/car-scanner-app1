import 'package:flutter_test/flutter_test.dart';

import 'package:car_scanner_app/services/obd/doip_controller.dart';
import 'package:car_scanner_app/services/obd/doip_transport.dart';
import 'package:car_scanner_app/services/obd/obd_models.dart';

const _doipAdapter = ObdAdapter(
  id: 'mock:doip',
  name: 'بوابة DoIP (محاكاة)',
  host: 'mock',
  port: 13400,
  type: ObdTransportType.doip,
);

Future<DoipController> _controller() async {
  final c = DoipController(MockDoipClient());
  await c.open(_doipAdapter);
  return c;
}

void main() {
  group('DoipController init', () {
    test('reports DoIP protocol and connected state', () async {
      final c = await _controller();
      expect(c.connected, isTrue);
      expect(c.protocol, contains('DoIP'));
      expect(c.version, contains('ISO 13400'));
    });
  });

  group('PID reads over UDS', () {
    test('rpm decodes from DID F18C', () async {
      final c = await _controller();
      final v = await c.readPid(ObdPid.rpm);
      expect(v, closeTo(1726, 0.01));
    });

    test('speed decodes from DID F18D', () async {
      final c = await _controller();
      final v = await c.readPid(ObdPid.speed);
      expect(v, closeTo(60, 0.01));
    });

    test('coolant and throttle decode', () async {
      final c = await _controller();
      expect(await c.readPid(ObdPid.coolant), closeTo(50, 0.01));
      expect(await c.readPid(ObdPid.throttle), closeTo(10.196, 0.01));
    });

    test('voltage is not available over DoIP', () async {
      final c = await _controller();
      expect(await c.readPid(ObdPid.voltage), isNull);
    });
  });

  group('VIN and DTC over UDS', () {
    test('reads VIN via DID F190', () async {
      final c = await _controller();
      final vin = await c.readVin();
      expect(vin, 'LFV3A23KDOIP00001');
    });

    test('reads and decodes a DTC via 19 02', () async {
      final c = await _controller();
      final codes = await c.readDtc();
      expect(codes, isNotEmpty);
      expect(codes.first.code, 'P0133');
    });

    test('clears DTCs via 14 FFFF', () async {
      final c = await _controller();
      await c.clearDtc();
    });
  });

  group('live data', () {
    test('stream yields PIDs', () async {
      final c = await _controller();
      final first = await c.liveDataStream().first;
      expect(first.containsKey(ObdPid.rpm), isTrue);
      expect(first[ObdPid.speed], closeTo(60, 0.01));
    });
  });

  group('mock scan', () {
    test('yields a DoIP adapter', () async {
      final adapter = await MockDoipClient().scan().first;
      expect(adapter.type, ObdTransportType.doip);
      expect(adapter.host, isNotNull);
      expect(adapter.isMock, isTrue);
    });
  });
}
