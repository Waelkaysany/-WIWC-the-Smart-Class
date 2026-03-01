class ClassroomStats {
  final double devicesOnlinePercent;
  final int studentsPresent;
  final int maleStudents;
  final int femaleStudents;
  final double focusRate;
  final double participation;
  final String noiseIndex;
  final int activeNowMin;
  final int activeNowMax;
  final String peakActivity;
  final String bestQuizTime;
  final List<double> activityGraph;

  const ClassroomStats({
    required this.devicesOnlinePercent,
    required this.studentsPresent,
    required this.maleStudents,
    required this.femaleStudents,
    required this.focusRate,
    required this.participation,
    required this.noiseIndex,
    required this.activeNowMin,
    required this.activeNowMax,
    required this.peakActivity,
    required this.bestQuizTime,
    required this.activityGraph,
  });

  ClassroomStats copyWith({
    double? devicesOnlinePercent,
    int? studentsPresent,
    int? maleStudents,
    int? femaleStudents,
    double? focusRate,
    double? participation,
    String? noiseIndex,
    int? activeNowMin,
    int? activeNowMax,
    String? peakActivity,
    String? bestQuizTime,
    List<double>? activityGraph,
  }) {
    return ClassroomStats(
      devicesOnlinePercent: devicesOnlinePercent ?? this.devicesOnlinePercent,
      studentsPresent: studentsPresent ?? this.studentsPresent,
      maleStudents: maleStudents ?? this.maleStudents,
      femaleStudents: femaleStudents ?? this.femaleStudents,
      focusRate: focusRate ?? this.focusRate,
      participation: participation ?? this.participation,
      noiseIndex: noiseIndex ?? this.noiseIndex,
      activeNowMin: activeNowMin ?? this.activeNowMin,
      activeNowMax: activeNowMax ?? this.activeNowMax,
      peakActivity: peakActivity ?? this.peakActivity,
      bestQuizTime: bestQuizTime ?? this.bestQuizTime,
      activityGraph: activityGraph ?? this.activityGraph,
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
