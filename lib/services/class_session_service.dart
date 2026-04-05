import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Service that manages class sessions: enter, leave, heartbeat, auto-release.
class ClassSessionService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Timer? _heartbeatTimer;
  String? _activeClassId;
  String? _activeSessionId;

  String? get activeClassId => _activeClassId;

  static const Duration heartbeatInterval = Duration(seconds: 25);
  static const Duration autoReleaseTimeout = Duration(minutes: 10);

  /// Enter a class: create session, lock the class, start heartbeat.
  Future<bool> enterClass(String classId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final classRef = _db.ref('classrooms/$classId');
    final snapshot = await classRef.get();
    if (!snapshot.exists) return false;

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    // Check if class is taken
    if (data['status'] == 'taken') {
      // Check if the heartbeat expired (auto-release)
      final takenBy = data['takenBy'];
      if (takenBy != null && takenBy is Map) {
        final lastHeartbeat = takenBy['lastHeartbeat'] ?? takenBy['since'] ?? 0;
        final elapsed = DateTime.now().millisecondsSinceEpoch - (lastHeartbeat as int);
        if (elapsed < autoReleaseTimeout.inMilliseconds) {
          // Still active, can't enter
          return false;
        }
        // Expired — auto-release
        debugPrint('⏰ Auto-releasing class $classId (heartbeat expired)');
      } else {
        return false;
      }
    }

    // Create session
    final sessionRef = _db.ref('classSessions').push();
    _activeSessionId = sessionRef.key;
    _activeClassId = classId;

    final now = DateTime.now().millisecondsSinceEpoch;
    final displayName = user.displayName ?? user.email?.split('@').first ?? 'Teacher';

    await sessionRef.set({
      'classId': classId,
      'teacherId': user.uid,
      'teacherName': displayName,
      'startedAt': now,
      'status': 'ACTIVE',
      'lastHeartbeat': now,
    });

    // Lock the class
    await classRef.update({
      'status': 'taken',
      'takenBy': {
        'uid': user.uid,
        'name': displayName,
        'since': now,
        'lastHeartbeat': now,
        'sessionId': _activeSessionId,
      },
    });

    // Initialize classroom data if missing (to ensure UI works before ESP32 connects)
    final sensorsRef = _db.ref('classrooms/$classId/sensors');
    final sensorsSnap = await sensorsRef.get();
    if (!sensorsSnap.exists) {
      await sensorsRef.set({
        'temperature': 24.0,
        'humidity': 50.0,
        'lightLevel': 80.0,
        'studentsPresent': 0,
        'airQuality': 98.0,
      });
    }

    final devicesRef = _db.ref('classrooms/$classId/devices');
    final devicesSnap = await devicesRef.get();
    if (!devicesSnap.exists) {
      await devicesRef.set({
        'light_1': {
          'name': 'Light 1',
          'isOn': false,
          'category': 'Lights',
          'icon': 'lightbulb_outline',
          'subtitle': 'Main ceiling',
          'brightness': 1.0,
        },
        'light_2': {
          'name': 'Light 2',
          'isOn': false,
          'category': 'Lights',
          'icon': 'lightbulb_outline',
          'subtitle': 'Window side',
          'brightness': 1.0,
        },
        'door': {
          'name': 'Door Lock',
          'isOn': true,
          'category': 'Door',
          'icon': 'lock_outline',
          'subtitle': 'Main door',
        },
        'projector': {
          'name': 'Projector',
          'isOn': false,
          'category': 'Projector',
          'icon': 'videocam_outlined',
          'subtitle': 'Epson EB-X51',
        },
        'ac': {
          'name': 'AC',
          'isOn': true,
          'category': 'AC',
          'icon': 'ac_unit',
          'subtitle': 'Cool mode',
          'mode': 'Cool',
        },
        'speakers': {
          'name': 'Speakers',
          'isOn': false,
          'category': 'Speaker',
          'icon': 'speaker_outlined',
          'subtitle': 'JBL system',
        },
        'board': {
          'name': 'Smart Board',
          'isOn': false,
          'category': 'Board',
          'icon': 'desktop_windows_outlined',
          'subtitle': 'Interactive panel',
        },
        'window_left': {
          'name': 'Window Left',
          'isOn': false,
          'category': 'Windows',
          'icon': 'window_outlined',
          'subtitle': 'Left side',
        },
        'window_right': {
          'name': 'Window Right',
          'isOn': false,
          'category': 'Windows',
          'icon': 'window_outlined',
          'subtitle': 'Right side',
        },
      });
    }

    // Start heartbeat
    _startHeartbeat(classId);

    debugPrint('✅ Entered class $classId (session: $_activeSessionId)');
    return true;
  }

  /// Leave a class: end session, unlock, stop heartbeat, and reset student statuses.
  Future<void> leaveClass() async {
    if (_activeClassId == null) return;

    final classId = _activeClassId!;
    final sessionId = _activeSessionId;

    // Stop heartbeat
    _stopHeartbeat();

    // End session
    if (sessionId != null) {
      await _db.ref('classSessions/$sessionId').update({
        'status': 'ENDED',
        'endedAt': DateTime.now().millisecondsSinceEpoch,
      });
    }

    // ── Reset all students who are still marked 'inside' back to 'outside' ──
    // This ensures the live counter drops to 0 immediately when the teacher leaves.
    try {
      final usersSnap = await _db.ref('users').orderByChild('status').equalTo('inside').get();
      if (usersSnap.exists && usersSnap.value is Map) {
        final insideUsers = Map<String, dynamic>.from(usersSnap.value as Map);
        final batch = <Future>[];
        for (final uid in insideUsers.keys) {
          batch.add(_db.ref('users/$uid').update({'status': 'outside'}));
        }
        await Future.wait(batch);
        debugPrint('🧹 Reset ${insideUsers.length} user(s) to outside on class exit.');
      }
    } catch (e) {
      debugPrint('⚠️ Could not reset user statuses on leave: $e');
    }

    // Clear the last scanned ID so no ghost scan fires after session ends
    await _db.ref('classrooms/$classId/last_scanned_id').remove();

    // Unlock class
    await _db.ref('classrooms/$classId').update({
      'status': 'available',
      'takenBy': null,
    });

    debugPrint('🚪 Left class $classId');

    _activeClassId = null;
    _activeSessionId = null;
  }

  /// Check if the current user has an active session and restore it.
  Future<String?> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Check all classrooms for one taken by this user
    final snapshot = await _db.ref('classrooms').get();
    if (!snapshot.exists) return null;

    final classrooms = Map<String, dynamic>.from(snapshot.value as Map);
    for (final entry in classrooms.entries) {
      final data = Map<String, dynamic>.from(entry.value as Map);
      if (data['status'] == 'taken' && data['takenBy'] != null) {
        final takenBy = Map<String, dynamic>.from(data['takenBy'] as Map);
        if (takenBy['uid'] == user.uid) {
          // Check if heartbeat is still valid
          final lastHeartbeat = takenBy['lastHeartbeat'] ?? takenBy['since'] ?? 0;
          final elapsed = DateTime.now().millisecondsSinceEpoch - (lastHeartbeat as int);
          if (elapsed < autoReleaseTimeout.inMilliseconds) {
            _activeClassId = entry.key;
            _activeSessionId = takenBy['sessionId'] as String?;
            _startHeartbeat(entry.key);
            debugPrint('🔄 Restored session for class ${entry.key}');
            return entry.key;
          }
        }
      }
    }
    return null;
  }

  void _startHeartbeat(String classId) {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      try {
        await _db.ref('classrooms/$classId/takenBy/lastHeartbeat').set(now);
        if (_activeSessionId != null) {
          await _db.ref('classSessions/$_activeSessionId/lastHeartbeat').set(now);
        }
      } catch (e) {
        debugPrint('💓 Heartbeat failed: $e');
      }
    });
    debugPrint('💓 Heartbeat started for class $classId');
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void dispose() {
    _stopHeartbeat();
  }

  /// Scan ALL classrooms and release any whose heartbeat has expired.
  /// This fixes the problem of classes stuck as "taken" after a teacher
  /// disconnects without properly leaving.
  static Future<int> cleanupStaleClassrooms() async {
    final db = FirebaseDatabase.instance;
    final snapshot = await db.ref('classrooms').get();
    if (!snapshot.exists) return 0;

    int released = 0;
    final classrooms = Map<String, dynamic>.from(snapshot.value as Map);
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final entry in classrooms.entries) {
      final data = Map<String, dynamic>.from(entry.value as Map);
      if (data['status'] != 'taken') continue;

      final takenBy = data['takenBy'];

      // Case 1: takenBy is null, not a map, or is an empty map — broken state
      if (takenBy == null || takenBy is! Map || (takenBy as Map).isEmpty) {
        await db.ref('classrooms/${entry.key}').update({
          'status': 'available',
          'takenBy': null,
        });
        released++;
        debugPrint('🧹 Released broken class ${entry.key} (no valid takenBy)');
        continue;
      }

      // Case 2: Parse heartbeat, treat 0 or null as "infinitely stale"
      int lastHeartbeat = 0;
      try {
        final hbVal = takenBy['lastHeartbeat'] ?? takenBy['since'];
        if (hbVal != null && hbVal is int && hbVal > 0) {
          lastHeartbeat = hbVal;
        } else if (hbVal != null && hbVal is String) {
          lastHeartbeat = int.tryParse(hbVal) ?? 0;
        }
      } catch (_) {
        lastHeartbeat = 0;
      }

      // If heartbeat is 0 or missing, it's stale. Otherwise check timeout.
      final isStale = lastHeartbeat == 0 ||
          (now - lastHeartbeat) >= autoReleaseTimeout.inMilliseconds;

      if (isStale) {
        // End the session if it exists
        final sessionId = takenBy['sessionId'];
        if (sessionId != null) {
          try {
            await db.ref('classSessions/$sessionId').update({
              'status': 'ENDED',
              'endedAt': now,
              'endReason': 'auto_released_heartbeat_expired',
            });
          } catch (_) {}
        }

        // Release the classroom
        await db.ref('classrooms/${entry.key}').update({
          'status': 'available',
          'takenBy': null,
        });
        released++;
        debugPrint('🧹 Auto-released stale class ${entry.key} (hb=$lastHeartbeat, elapsed=${now - lastHeartbeat}ms)');
      }
    }

    if (released > 0) {
      debugPrint('🧹 Cleanup complete: released $released stale classroom(s)');
    }
    return released;
  }
}
