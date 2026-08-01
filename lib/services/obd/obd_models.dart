enum ObdTransportType { ble, classic, mock }

class ObdAdapter {
  final String id;
  final String name;
  final int rssi;
  final ObdTransportType type;

  const ObdAdapter({
    required this.id,
    required this.name,
    this.rssi = 0,
    this.type = ObdTransportType.ble,
  });
}

enum ObdPid {
  voltage(0x7E, 'جهد البطارية', 'فولت'),
  coolant(0x05, 'حرارة المحرك', '°م'),
  rpm(0x0C, 'سرعة المحرك', 'د/د'),
  speed(0x0D, 'سرعة السيارة', 'كم/س'),
  intake(0x0F, 'حرارة الهواء الساحب', '°م'),
  maf(0x10, 'معدل تدفق الهواء', 'جم/ث'),
  throttle(0x11, 'فتحة الخانق', '%'),
  fuelLevel(0x2F, 'مستوى الوقود', '%');

  final int code;
  final String label;
  final String unit;

  const ObdPid(this.code, this.label, this.unit);
}
