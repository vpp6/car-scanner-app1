import 'package:flutter_test/flutter_test.dart';

import 'package:car_scanner_app/services/obd/elm327.dart';
import 'package:car_scanner_app/services/obd/obd_models.dart';
import 'package:car_scanner_app/services/obd/obd_transport.dart';

const _mockAdapter = ObdAdapter(
  id: 'mock:obd1',
  name: 'فاحص برو X1 (محاكاة)',
  type: ObdTransportType.mock,
);

Future<Elm327Controller> _controller() async {
  final c = Elm327Controller(MockObdTransport());
  await c.open(_mockAdapter);
  return c;
}

void main() {
  group('Elm327Controller init', () {
    test('reads version, protocol and voltage', () async {
      final c = await _controller();
      expect(c.connected, isTrue);
      expect(c.version, contains('ELM327'));
      expect(c.protocol, contains('ISO 15765-4'));
      expect(c.voltage, closeTo(12.6, 0.01));
    });
  });

  group('PID formulas', () {
    test('coolant temperature is value - 40', () async {
      final c = await _controller();
      final v = await c.readPid(ObdPid.coolant);
      expect(v, closeTo(50, 0.01));
    });

    test('rpm = ((A*256)+B)/4', () async {
      final c = await _controller();
      final v = await c.readPid(ObdPid.rpm);
      expect(v, closeTo(1726, 0.01));
    });

    test('vehicle speed is raw byte', () async {
      final c = await _controller();
      final v = await c.readPid(ObdPid.speed);
      expect(v, closeTo(60, 0.01));
    });

    test('intake temperature is value - 40', () async {
      final c = await _controller();
      final v = await c.readPid(ObdPid.intake);
      expect(v, closeTo(10, 0.01));
    });

    test('MAF = ((A*256)+B)/100', () async {
      final c = await _controller();
      final v = await c.readPid(ObdPid.maf);
      expect(v, closeTo(15, 0.01));
    });

    test('throttle and fuel level are percentage', () async {
      final c = await _controller();
      final throttle = await c.readPid(ObdPid.throttle);
      final fuel = await c.readPid(ObdPid.fuelLevel);
      expect(throttle, closeTo(10.196, 0.01));
      expect(fuel, closeTo(27.45, 0.01));
    });

    test('voltage pid maps to ATRV', () async {
      final c = await _controller();
      final v = await c.readPid(ObdPid.voltage);
      expect(v, closeTo(12.6, 0.01));
    });
  });

  group('DTC handling', () {
    test('reads and decodes a DTC', () async {
      final c = await _controller();
      final codes = await c.readDtc();
      expect(codes, isNotEmpty);
      expect(codes.first.code, 'P0133');
      expect(codes.first.system, contains('ECU'));
    });

    test('clearDtc sends 04 without error', () async {
      final c = await _controller();
      await c.clearDtc();
    });
  });

  group('VIN', () {
    test('reads and decodes VIN', () async {
      final c = await _controller();
      final vin = await c.readVin();
      expect(vin, 'LFV3A23K');
    });
  });

  group('live data', () {
    test('stream yields data for all PIDs', () async {
      final c = await _controller();
      final first = await c.liveDataStream().first;
      expect(first.containsKey(ObdPid.rpm), isTrue);
      expect(first[ObdPid.speed], closeTo(60, 0.01));
      expect(first[ObdPid.voltage], closeTo(12.6, 0.01));
    });
  });
}
