/// Data model for a classroom and its session state.
class ClassRoom {
  final String id;
  final String name;
  final String grade;        // e.g. "ROOM 402", "STUDIO B", "HUB 1"
  final String subject;      // e.g. "Science", "Digital Media"
  final int imageIndex;      // index into asset images list
  final String status;       // "available" or "taken"
  final TakenInfo? takenBy;

  const ClassRoom({
    required this.id,
    required this.name,
    this.grade = '',
    this.subject = '',
    this.imageIndex = 0,
    this.status = 'available',
    this.takenBy,
  });

  bool get isAvailable => status == 'available';
  bool get isTaken => status == 'taken';

  factory ClassRoom.fromMap(String id, Map<dynamic, dynamic> map) {
    TakenInfo? takenBy;
    if (map['takenBy'] != null && map['takenBy'] is Map) {
      takenBy = TakenInfo.fromMap(Map<String, dynamic>.from(map['takenBy']));
    }
    return ClassRoom(
      id: id,
      name: map['name'] ?? 'Unnamed Class',
      grade: map['grade'] ?? '',
      subject: map['subject'] ?? '',
      imageIndex: map['imageIndex'] ?? 0,
      status: map['status'] ?? 'available',
      takenBy: takenBy,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'grade': grade,
    'subject': subject,
    'imageIndex': imageIndex,
    'status': status,
    if (takenBy != null) 'takenBy': takenBy!.toMap(),
  };
}

class TakenInfo {
  final String uid;
  final String name;
  final int since; // timestamp ms

  const TakenInfo({
    required this.uid,
    required this.name,
    required this.since,
  });

  factory TakenInfo.fromMap(Map<String, dynamic> map) {
    return TakenInfo(
      uid: map['uid'] ?? '',
      name: map['name'] ?? 'Unknown',
      since: map['since'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'since': since,
  };

  String get sinceFormatted {
    final dt = DateTime.fromMillisecondsSinceEpoch(since);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
