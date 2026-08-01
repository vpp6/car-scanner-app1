enum DtcSeverity { low, medium, high, critical }

class DtcCode {
  final String code;
  final String description;
  final String system;
  final DtcSeverity severity;
  final bool frozen;
  final int occurrences;

  const DtcCode({
    required this.code,
    required this.description,
    required this.system,
    required this.severity,
    required this.frozen,
    this.occurrences = 1,
  });

  String get severityLabel => switch (severity) {
        DtcSeverity.low => 'منخفض',
        DtcSeverity.medium => 'متوسط',
        DtcSeverity.high => 'مرتفع',
        DtcSeverity.critical => 'حرج',
      };
}
