class VehicleMake {
  final String name;
  final List<String> models;

  const VehicleMake(this.name, this.models);
}

class Vehicle {
  final String vin;
  final String make;
  final String model;
  final int year;
  final String engine;
  final String fuel;
  final String odometer;
  final String plate;

  const Vehicle({
    required this.vin,
    required this.make,
    required this.model,
    required this.year,
    required this.engine,
    required this.fuel,
    required this.odometer,
    required this.plate,
  });

  String get shortName => '$make $model';
}

class VehicleSystem {
  final String id;
  final String name;
  final String icon;
  final bool supported;

  const VehicleSystem({
    required this.id,
    required this.name,
    required this.icon,
    required this.supported,
  });
}

class ScanReport {
  final String system;
  final String icon;
  final int codes;
  final ScanStatus status;

  const ScanReport({
    required this.system,
    required this.icon,
    required this.codes,
    required this.status,
  });
}

enum ScanStatus {
  ok,
  codes,
  noModule,
  warning;

  String get label => switch (this) {
        ScanStatus.ok => 'سليم',
        ScanStatus.codes => 'يحتاج فحص',
        ScanStatus.noModule => 'غير مزود',
        ScanStatus.warning => 'تحذير',
      };
}
