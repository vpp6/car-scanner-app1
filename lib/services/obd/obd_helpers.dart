import '../../models/dtc.dart';
import 'obd_models.dart';

/// Extracts all 2-hex-digit byte tokens from a string.
List<int> parseHexBytes(String text) {
  final re = RegExp(r'[0-9A-Fa-f]{2}');
  return re
      .allMatches(text)
      .map((m) => int.parse(m.group(0)!, radix: 16))
      .toList();
}

/// Applies the SAE J1979 formula for the given PID.
double? applyPidFormula(ObdPid pid, List<int> b) {
  if (b.isEmpty) return null;
  switch (pid) {
    case ObdPid.coolant:
    case ObdPid.intake:
      return (b[0] - 40).toDouble();
    case ObdPid.rpm:
      if (b.length < 2) return null;
      return ((b[0] << 8) + b[1]) / 4;
    case ObdPid.speed:
      return b[0].toDouble();
    case ObdPid.maf:
      if (b.length < 2) return null;
      return ((b[0] << 8) + b[1]) / 100;
    case ObdPid.throttle:
    case ObdPid.fuelLevel:
      return b[0] * 100 / 255;
    case ObdPid.voltage:
      return b[0].toDouble();
  }
}

/// Decodes a 2-byte DTC into the standard "P0133" form (same encoding as ISO
/// 14229 and SAE J2012).
String dtcCodeFromBytes(int b1, int b2) {
  final prefix = switch (b1 >> 6) {
    0 => 'P',
    1 => 'C',
    2 => 'B',
    _ => 'U',
  };
  final d2 = (b1 >> 4) & 0x03;
  final d3 = b1 & 0x0F;
  final d4 = b2 >> 4;
  final d5 = b2 & 0x0F;
  return '$prefix$d2${d3.toRadixString(16).toUpperCase()}'
      '${d4.toRadixString(16).toUpperCase()}'
      '${d5.toRadixString(16).toUpperCase()}';
}

String dtcSystem(String code) {
  if (code.startsWith('P')) return 'وحدة التحكم بالمحرك ECU';
  if (code.startsWith('C')) return 'الشاسيه والمكابح ABS';
  if (code.startsWith('B')) return 'جسم السيارة BCM';
  return 'الاتصالات والشبكة';
}

DtcSeverity dtcSeverity(String code) {
  if (code.startsWith('U')) return DtcSeverity.high;
  return DtcSeverity.medium;
}

String dtcDescription(String code) {
  const known = {
    'P0171': 'الخليط فقير جداً - البنك 1',
    'P0174': 'الخليط فقير جداً - البنك 2',
    'P0300': 'فقدان احتراق عشوائي/متعدد الأسطوانات',
    'P0301': 'فقدان احتراق - الأسطوانة 1',
    'P0302': 'فقدان احتراق - الأسطوانة 2',
    'P0303': 'فقدان احتراق - الأسطوانة 3',
    'P0304': 'فقدان احتراق - الأسطوانة 4',
    'P0420': 'كفاءة المحول الحفاز أقل من الحد - البنك 1',
    'P0430': 'كفاءة المحول الحفاز أقل من الحد - البنك 2',
    'P0442': 'تسرب صغير في نظام الأبخرة EVAP',
    'P0455': 'تسرب كبير في نظام الأبخرة EVAP',
    'P0500': 'عطل في مستشعر سرعة السيارة',
    'P0505': 'عطل في نظام التحكم بالخمول',
    'P0700': 'عطل في نظام التحكم بناقل الحركة',
    'P0101': 'نطاق مستشعر تدفق الهواء MAF غير طبيعي',
    'P0113': 'إشارة مرتفعة لمستشعر حرارة الهواء',
    'P0128': 'حرارة المحرك أقل من المطلوب للتشغيل',
    'P0135': 'عطل في سخان مستشعر الأكسجين - البنك 1',
  };
  return known[code] ?? 'رمز خطأ قرأه التطبيق من وحدة التحكم الإلكترونية';
}
