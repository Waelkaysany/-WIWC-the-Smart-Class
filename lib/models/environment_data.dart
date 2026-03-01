class EnvironmentData {
  final double temperature;
  final double humidity;
  final double lightLevel;
  final int studentsPresent;
  final double airQuality;

  const EnvironmentData({
    required this.temperature,
    required this.humidity,
    required this.lightLevel,
    required this.studentsPresent,
    this.airQuality = 95, // Default to a healthy 95%
  });

  EnvironmentData copyWith({
    double? temperature,
    double? humidity,
    double? lightLevel,
    int? studentsPresent,
    double? airQuality,
  }) {
    return EnvironmentData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      lightLevel: lightLevel ?? this.lightLevel,
      studentsPresent: studentsPresent ?? this.studentsPresent,
      airQuality: airQuality ?? this.airQuality,
    );
  }
}
