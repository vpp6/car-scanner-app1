import 'dart:math' as math;

class ScopeChannel {
  final int index;
  final String name;
  final bool enabled;
  final double voltageScale;
  final double timeScale;
  final List<Point> points;

  const ScopeChannel({
    required this.index,
    required this.name,
    required this.enabled,
    required this.voltageScale,
    required this.timeScale,
    this.points = const [],
  });

  ScopeChannel copyWith({
    bool? enabled,
    double? voltageScale,
    double? timeScale,
    List<Point>? points,
  }) {
    return ScopeChannel(
      index: index,
      name: name,
      enabled: enabled ?? this.enabled,
      voltageScale: voltageScale ?? this.voltageScale,
      timeScale: timeScale ?? this.timeScale,
      points: points ?? this.points,
    );
  }
}

class Point {
  final double t;
  final double v;

  const Point(this.t, this.v);
}

class WaveformGenerator {
  static List<Point> sine({
    required int count,
    required double amplitude,
    required double frequency,
    double phase = 0,
    double offset = 0,
  }) {
    return List.generate(
      count,
      (i) => Point(
        i.toDouble(),
        offset +
            amplitude *
                math.sin(
                  2 * math.pi * frequency * (i / count) + phase,
                ),
      ),
    );
  }

  static List<Point> square({
    required int count,
    required double amplitude,
    required double frequency,
    double phase = 0,
    double offset = 0,
  }) {
    return List.generate(
      count,
      (i) => Point(
        i.toDouble(),
        offset +
            (math.sin(2 * math.pi * frequency * (i / count) + phase) >= 0
                ? amplitude
                : -amplitude),
      ),
    );
  }

  static List<Point> ramp({
    required int count,
    required double amplitude,
    required double frequency,
    double phase = 0,
    double offset = 0,
  }) {
    return List.generate(
      count,
      (i) {
        final t = (frequency * (i / count) + phase / (2 * math.pi)) % 1.0;
        return Point(i.toDouble(), offset + amplitude * (2 * t - 1));
      },
    );
  }
}
