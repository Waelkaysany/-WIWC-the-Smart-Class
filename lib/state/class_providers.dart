import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/classroom.dart';
import '../services/class_session_service.dart';
import '../services/firebase_service.dart';

/// Share the same ClassSessionService instance used by AuthService
final classSessionServiceProvider = Provider<ClassSessionService>((ref) {
  return ref.read(classSessionServiceProviderInternal);
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

/// Name of the currently active class
final activeClassNameProvider = StateProvider<String>((ref) => 'Class');

/// Filter for class selection screen
final classFilterProvider = StateProvider<String>((ref) => 'All Classes');
