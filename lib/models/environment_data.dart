class EnvironmentData {
  final double temperature;
  final double humidity;
  final double lightLevel;
  final int studentsPresent;
  final double airQuality;
  final String? lastScannedUser;
  final String? lastScannedUID;
  final bool autoLight;

  const EnvironmentData({
    required this.temperature,
    required this.humidity,
    required this.lightLevel,
    required this.studentsPresent,
    this.airQuality = 95, 
    this.lastScannedUser,
    this.lastScannedUID,
    this.autoLight = true,
  });

  EnvironmentData copyWith({
    double? temperature,
    double? humidity,
    double? lightLevel,
    int? studentsPresent,
    double? airQuality,
    String? lastScannedUser,
    String? lastScannedUID,
    bool? autoLight,
  }) {
    return EnvironmentData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      lightLevel: lightLevel ?? this.lightLevel,
      studentsPresent: studentsPresent ?? this.studentsPresent,
      airQuality: airQuality ?? this.airQuality,
      lastScannedUser: lastScannedUser ?? this.lastScannedUser,
      lastScannedUID: lastScannedUID ?? this.lastScannedUID,
      autoLight: autoLight ?? this.autoLight,
    );
  }
}

