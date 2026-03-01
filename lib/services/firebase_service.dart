import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/environment_data.dart';
import 'email_service.dart';

// ── Auth Service ──

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (credential.user != null) {
      final db = DatabaseService();
      final profile = await db.getUserProfile(credential.user!.uid);
      if (profile == null) {
        // Returning user whose RTDB profile is missing — auto-approve since
        // they already have a Firebase Auth account.
        await db.createUserProfile(
          uid: credential.user!.uid,
          email: email,
          name: email.split('@').first,
          role: 'teacher', 
          isApproved: true,
        );
        
        // Ensure some sensor data exists so the UI isn't empty
        await db.writeMockSensorData();
        await db.writeInitialDeviceStates();
      } else {
        await db.updateLastLogin(credential.user!.uid);
      }
    }
    
    return credential;
  }

  Future<UserCredential> signUp(String email, String password, {required String role}) async {
    final db = DatabaseService();
    
    // Check spam protection
    final attempts = await db.getSignupAttempts(email);
    if (attempts >= 3) {
      throw Exception('Signup limit reached for this email. Please contact support.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Increment attempts
    await db.incrementSignupAttempts(email);

    // Save user profile to RTDB
    if (credential.user != null) {
      await db.createUserProfile(
        uid: credential.user!.uid,
        email: email,
        name: email.split('@').first,
        role: role,
        isApproved: role != 'teacher', // Students/Admins approved by default
      );

      if (role == 'teacher') {
        await db.createApprovalRequest(credential.user!.uid, email);
      }
    }

    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}

// ── Database Service ──
// RTDB structure:
//   users/
//     {uid}/
//       name: "user"
//       email: "user@gmail.com"
//       role: "admin"
//       createdAt: "2026-02-19T..."
//       lastLogin: "2026-02-19T..."
//   classroom/
//     sensors/
//       temperature: 28.5
//       humidity: 65.0
//       lightLevel: 72.0
//       studentsPresent: 28
//     devices/
//       lights: { isOn: true, brightness: 0.72 }
//       door: { isOn: true }
//       projector: { isOn: true }
//       ac: { isOn: true, mode: "Cool" }
//       speakers: { isOn: false }
//       board: { isOn: false }
//       window_left: { isOn: false }
//       window_right: { isOn: false }

class DatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ── User Profile ──
  DatabaseReference get _usersRef => _db.ref('users');

  DatabaseReference get _attemptsRef => _db.ref('signup_attempts');

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String name,
    required String role,
    bool isApproved = false,
  }) async {
    await _usersRef.child(uid).set({
      'name': name,
      'email': email,
      'role': role,
      'isApproved': isApproved,
      'createdAt': DateTime.now().toIso8601String(),
      'lastLogin': DateTime.now().toIso8601String(),
    });
  }

  Future<int> getSignupAttempts(String email) async {
    final cleanEmail = email.replaceAll('.', '_').replaceAll('@', '_');
    final snapshot = await _attemptsRef.child(cleanEmail).get();
    return (snapshot.value as int?) ?? 0;
  }

  Future<void> incrementSignupAttempts(String email) async {
    final cleanEmail = email.replaceAll('.', '_').replaceAll('@', '_');
    final current = await getSignupAttempts(email);
    await _attemptsRef.child(cleanEmail).set(current + 1);
  }

  Future<bool> isUserApproved(String uid) async {
    final profile = await getUserProfile(uid);
    return profile?['isApproved'] ?? false;
  }

  Future<void> updateLastLogin(String uid) async {
    await _usersRef.child(uid).update({
      'lastLogin': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snapshot = await _usersRef.child(uid).get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _usersRef.child(uid).update(data);
  }

  // ── Approval Management ──
  DatabaseReference get _approvalsRef => _db.ref('pending_approvals');

  Stream<List<Map<String, dynamic>>> get pendingApprovalsStream {
    return _approvalsRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      
      return data.entries.map((e) {
        final val = Map<String, dynamic>.from(e.value as Map);
        return {
          'uid': e.key as String,
          ...val,
        };
      }).toList();
    });
  }

  Future<void> approveUser(String uid) async {
    // 1. Update user profile
    await _usersRef.child(uid).update({'isApproved': true});
    // 2. Remove from pending approvals
    await _approvalsRef.child(uid).remove();
  }

  Future<void> rejectUser(String uid) async {
    // We just remove the approval request. 
    // The user will still be stuck on the Pending screen until they logout or we delete their profile.
    // Usually "Delete" means remove the request AND potentially the user profile if we want to be thorough.
    await _approvalsRef.child(uid).remove();
    // Optional: await _usersRef.child(uid).remove();
  }

  Future<int> cleanupStaleApprovals() async {
    final snapshot = await _approvalsRef.get();
    if (!snapshot.exists) return 0;
    
    int count = 0;
    final data = snapshot.value as Map<dynamic, dynamic>;
    for (var entry in data.entries) {
      final uid = entry.key as String;
      final isApproved = await isUserApproved(uid);
      if (isApproved) {
        await _approvalsRef.child(uid).remove();
        count++;
      }
    }
    return count;
  }

  Future<void> createApprovalRequest(String uid, String email) async {
    final now = DateTime.now().toIso8601String();
    
    // 1. Record in pending_approvals for admin dashboard use
    await _approvalsRef.child(uid).set({
      'email': email,
      'requestedAt': now,
      'status': 'pending',
    });

    // 2. Trigger email via EmailService
    try {
      await EmailService.sendApprovalEmail(
        teacherEmail: email,
        uid: uid,
      );
      print('DEBUG: Approval email sent successfully for $email');
    } catch (e) {
      print('DEBUG ERROR: Failed to send approval email: $e');
    }
  }

  // ── Sensor Data (ESP32 writes, App reads) ──
  DatabaseReference get _sensorsRef => _db.ref('classroom/sensors');

  Stream<EnvironmentData> get sensorStream {
    return _sensorsRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        return const EnvironmentData(
          temperature: 0,
          humidity: 0,
          lightLevel: 0,
          studentsPresent: 0,
        );
      }
      return EnvironmentData(
        temperature: (data['temperature'] ?? 0).toDouble(),
        humidity: (data['humidity'] ?? 0).toDouble(),
        lightLevel: (data['lightLevel'] ?? 0).toDouble(),
        studentsPresent: (data['studentsPresent'] ?? 0).toInt(),
        airQuality: (data['airQuality'] ?? 95.0).toDouble(),
      );
    });
  }

  // ── Device States (App reads/writes, ESP32 reads) ──
  DatabaseReference get _devicesRef => _db.ref('classroom/devices');

  Future<void> updateDeviceState(String deviceId, Map<String, dynamic> state) async {
    await _devicesRef.child(deviceId).update(state);
  }

  Stream<Map<String, dynamic>> deviceStream(String deviceId) {
    return _devicesRef.child(deviceId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      return data?.cast<String, dynamic>() ?? {};
    });
  }

  Stream<Map<String, dynamic>> get allDevicesStream {
    return _devicesRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      return data?.cast<String, dynamic>() ?? {};
    });
  }

  // ── Write initial sensor data (for testing without ESP32) ──
  Future<void> writeMockSensorData() async {
    await _sensorsRef.set({
      'temperature': 28.5,
      'humidity': 65.0,
      'lightLevel': 72.0,
      'studentsPresent': 0,
      'airQuality': 94.0,
    });
  }

  // ── Write initial device states ──
  Future<void> writeInitialDeviceStates() async {
    await _devicesRef.set({
      'lights': {'isOn': true, 'brightness': 0.72},
      'door': {'isOn': true},
      'projector': {'isOn': true},
      'board': {'isOn': false},
      'ac': {'isOn': true, 'mode': 'Cool'},
      'speakers': {'isOn': false},
      'window_left': {'isOn': false},
      'window_right': {'isOn': false},
    });
  }
}

// ── Riverpod Providers ──

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  
  final db = ref.watch(databaseServiceProvider);
  return db._usersRef.child(user.uid).onValue.map((event) {
    final data = event.snapshot.value as Map?;
    return data?.cast<String, dynamic>();
  });
});

final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());

final firebaseSensorProvider = StreamProvider<EnvironmentData>((ref) {
  return ref.watch(databaseServiceProvider).sensorStream;
});

final firebaseDevicesProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return ref.watch(databaseServiceProvider).allDevicesStream;
});

final pendingApprovalsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(databaseServiceProvider).pendingApprovalsStream;
});
