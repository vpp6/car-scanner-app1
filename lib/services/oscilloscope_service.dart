import 'dart:async';
import 'dart:math' as math;

import '../models/oscilloscope.dart';

abstract class OscilloscopeService {
  Stream<List<ScopeChannel>> channels();
  Future<void> start();
  Future<void> stop();
}

class MockOscilloscopeService implements OscilloscopeService {
  final _controller = StreamController<List<ScopeChannel>>.broadcast();
  Timer? _timer;
  double _phase = 0;

  @override
  Stream<List<ScopeChannel>> channels() => _controller.stream;

  @override
  Future<void> start() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      _phase += 0.12;
      final channels = [
        ScopeChannel(
          index: 1,
          name: 'CH1',
          enabled: true,
          voltageScale: 2,
          timeScale: 1,
          points: WaveformGenerator.sine(
            count: 120,
            amplitude: 2.2,
            frequency: 1,
            phase: _phase,
          ),
        ),
        ScopeChannel(
          index: 2,
          name: 'CH2',
          enabled: true,
          voltageScale: 2,
          timeScale: 1,
          points: WaveformGenerator.square(
            count: 120,
            amplitude: 1.8,
            frequency: 0.6,
            phase: _phase * 0.8,
          ),
        ),
        ScopeChannel(
          index: 3,
          name: 'CH3',
          enabled: true,
          voltageScale: 1,
          timeScale: 1,
          points: WaveformGenerator.sine(
            count: 120,
            amplitude: 1.0,
            frequency: 3.2,
            phase: _phase * 1.4 + math.pi / 2,
            offset: -1,
          ),
        ),
        ScopeChannel(
          index: 4,
          name: 'CH4',
          enabled: true,
          voltageScale: 1,
          timeScale: 1,
          points: WaveformGenerator.ramp(
            count: 120,
            amplitude: 0.9,
            frequency: 0.4,
            phase: _phase * 0.5,
            offset: -2,
          ),
        ),
      ];
      _controller.add(channels);
    });
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

double signalPeakToPeak(List<Point> points) {
  if (points.isEmpty) return 0;
  var min = double.infinity;
  var max = double.negativeInfinity;
  for (final p in points) {
    if (p.v < min) min = p.v;
    if (p.v > max) max = p.v;
  }
  return max - min;
}

double signalFrequency(List<Point> points) {
  if (points.length < 3) return 0;
  var crossings = 0;
  var prev = points.first.v;
  for (final p in points.skip(1)) {
    if ((prev < 0 && p.v >= 0) || (prev >= 0 && p.v < 0)) crossings++;
    prev = p.v;
  }
  return crossings / 2;
}
