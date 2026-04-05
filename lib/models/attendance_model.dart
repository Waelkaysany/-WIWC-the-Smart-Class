class AttendanceModel {
  final String sessionId;
  final String uid;
  final String name;
  final int checkInTime;
  final int checkOutTime;
  final String status;
  final int? durationMins;

  AttendanceModel({
    required this.sessionId,
    required this.uid,
    required this.name,
    required this.checkInTime,
    required this.checkOutTime,
    required this.status,
    this.durationMins,
  });

  factory AttendanceModel.fromMap(String sessionId, Map<dynamic, dynamic> data) {
    return AttendanceModel(
      sessionId: sessionId,
      uid: data['uid'] ?? '',
      name: data['name'] ?? 'Unknown',
      checkInTime: data['checkInTime'] ?? 0,
      checkOutTime: data['checkOutTime'] ?? 0,
      status: data['status'] ?? 'unknown',
      durationMins: data['durationMins'],
    );
  }
}
