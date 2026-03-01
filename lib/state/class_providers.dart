import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/classroom.dart';
import '../services/class_session_service.dart';

/// Singleton class session service
final classSessionServiceProvider = Provider<ClassSessionService>((ref) {
  final service = ClassSessionService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream of all classrooms from RTDB
final classroomsStreamProvider = StreamProvider<List<ClassRoom>>((ref) {
  final dbRef = FirebaseDatabase.instance.ref('classrooms');
  return dbRef.onValue.map((event) {
    if (event.snapshot.value == null) return <ClassRoom>[];
    final map = Map<String, dynamic>.from(event.snapshot.value as Map);
    return map.entries
        .map((e) => ClassRoom.fromMap(e.key, Map<dynamic, dynamic>.from(e.value as Map)))
        .toList();
  });
});

/// Currently active class ID (null = on class selection screen)
final activeClassIdProvider = StateProvider<String?>((ref) => null);

/// Filter for class selection screen
final classFilterProvider = StateProvider<String>((ref) => 'All Classes');
