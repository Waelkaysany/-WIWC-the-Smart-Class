class UserModel {
  final String uid;
  final String name;
  final String role;
  final String status;
  final String? currentSessionId;
  final int? registeredAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.role,
    required this.status,
    this.currentSessionId,
    this.registeredAt,
  });

  factory UserModel.fromMap(String uid, Map<dynamic, dynamic> data) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? 'Unknown',
      role: data['role'] ?? 'student',
      status: data['status'] ?? 'outside',
      currentSessionId: data['current_session_id'],
      registeredAt: data['registeredAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'status': status,
      'current_session_id': currentSessionId,
      'registeredAt': registeredAt,
    };
  }
}
