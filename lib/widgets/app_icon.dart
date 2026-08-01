import 'package:flutter/material.dart';

IconData iconFor(String name) => switch (name) {
      'motor' => Icons.settings,
      'brake' => Icons.disc_full,
      'shield' => Icons.safety_check,
      'gearbox' => Icons.settings_input_component,
      'car' => Icons.directions_car,
      'steering' => Icons.wifi_tethering,
      'stability' => Icons.control_camera,
      'tire' => Icons.tire_repair,
      'battery' => Icons.battery_charging_full,
      'key' => Icons.key,
      _ => Icons.memory,
    };
