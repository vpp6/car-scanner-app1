enum DeviceStatus { disconnected, scanning, connecting, connected }

enum ConnectionMethod { bluetooth, usb, wifi }

class DeviceInfo {
  final String name;
  final String model;
  final String serial;
  final String firmware;
  final int batteryLevel;
  final int batteryCapacityMah;
  final bool charging;
  final bool canFdSupported;
  final bool doipSupported;
  final bool oscilloscope4ch;
  final String softwareVersion;
  final ConnectionMethod connectionMethod;

  const DeviceInfo({
    required this.name,
    required this.model,
    required this.serial,
    required this.firmware,
    required this.batteryLevel,
    required this.batteryCapacityMah,
    required this.charging,
    required this.canFdSupported,
    required this.doipSupported,
    required this.oscilloscope4ch,
    required this.softwareVersion,
    required this.connectionMethod,
  });

  String get methodLabel => switch (connectionMethod) {
        ConnectionMethod.bluetooth => 'بلوتوث',
        ConnectionMethod.usb => 'USB',
        ConnectionMethod.wifi => 'WiFi',
      };
}
