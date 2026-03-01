import 'package:flutter/material.dart';

class Device {
  final String id;
  final String name;
  final IconData icon;
  final bool isOn;
  final String subtitle;
  final String category;
  final double? brightness;
  final String? mode;

  const Device({
    required this.id,
    required this.name,
    required this.icon,
    required this.isOn,
    required this.subtitle,
    required this.category,
    this.brightness,
    this.mode,
  });

  Device copyWith({
    bool? isOn,
    double? brightness,
    String? mode,
    String? subtitle,
  }) {
    return Device(
      id: id,
      name: name,
      icon: icon,
      isOn: isOn ?? this.isOn,
      subtitle: subtitle ?? this.subtitle,
      category: category,
      brightness: brightness ?? this.brightness,
      mode: mode ?? this.mode,
    );
  }
}
