import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/classroom_stats.dart';
import '../models/device.dart';
import '../models/environment_data.dart';
import 'controllers.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../services/iot_service.dart';
import 'notification_provider.dart';
import '../main.dart';

final classroomStatsProvider =
    StateNotifierProvider<ClassroomStatsNotifier, ClassroomStats>(
  (ref) {
    final notifier = ClassroomStatsNotifier();
    // Sync student count from actual Firebase user status (Inside/Outside)
    ref.listen(insideUsersCountProvider, (previous, next) {
      next.whenData((count) => notifier.updateStudentCount(count));
    });
    return notifier;
  },
);

/// StreamProvider for the accurate count of checked-in users
final insideUsersCountProvider = StreamProvider<int>((ref) {
  return ref.watch(databaseServiceProvider).insideUsersCountStream;
});

/// Watches Firebase `classrooms/a8/last_scanned_id`.
/// Whenever the ESP32 writes a new UID to that path, this provider fires
/// and calls toggleUserAttendance — no polling, no counter fragility.
final lastScannedUidProvider = StreamProvider<String?>((ref) {
  return ref.watch(databaseServiceProvider).lastScannedUidStream;
});

/// Drives the RFID attendance bridge by listening to lastScannedUidProvider
/// and toggling the user's status in Firebase on each new scan.
/// Must be kept-alive by being watched somewhere in the widget tree.
final rfidAttendanceBridgeProvider = Provider<void>((ref) {
  ref.listen(lastScannedUidProvider, (previous, next) {
    next.whenData((uid) async {
      if (uid == null || uid.isEmpty || uid == 'None') return;
      debugPrint('🔔 RFID scan detected: $uid — toggling attendance');
      
      bool success = await ref.read(databaseServiceProvider).toggleUserAttendance(uid);
      if (!success) {
        NotificationService().showAlert(
          id: 999,
          title: '🚨 Unauthorized Access Attempt',
          body: 'An unknown RFID card ($uid) tried to access the classroom!',
          payload: 'security',
        );
      }
    });
  });
});

// Load stored IP or default to ESP32 AP IP
final iotIpProvider = StateProvider<String>((ref) => prefs.getString('iot_ip') ?? '192.168.4.1');


final iotServiceProvider = Provider<IotService>((ref) {
  final ip = ref.watch(iotIpProvider);
  return IotService(ipAddress: ip);
});

final devicesProvider =
    StateNotifierProvider<DevicesNotifier, List<Device>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final iotService = ref.watch(iotServiceProvider);
  final notifier = DevicesNotifier(dbService, iotService);

  // Sync device state from Firebase RTDB stream.
  // This ensures changes made by the AI assistant, scheduler,
  // or any other client are reflected in the Controls UI.
  ref.listen(firebaseDevicesProvider, (previous, next) {
    next.whenData((data) => notifier.updateFromMap(data));
  });

  // Load initial data if available
  final initial = ref.read(firebaseDevicesProvider).asData?.value;
  if (initial != null) {
    Future.microtask(() => notifier.updateFromMap(initial));
  }

  return notifier;
});

final _lastNotificationTime = <String, DateTime>{};

final environmentProvider =
    StateNotifierProvider<EnvironmentNotifier, EnvironmentData>((ref) {
  final iotService = ref.watch(iotServiceProvider);
  final notifier = EnvironmentNotifier(iotService);

  // ── IMPORTANT: Local IoT Overrides Cloud ──
  // We no longer listen to firebaseSensorProvider here because we are using 
  // local HTTP polling for real-time sensor data. Listening to Firebase results
  // in local data (like RFID scans) being overwritten by stale values (0).
  
  notifier.onAlert = (String type, double value) {
    // Check master toggle
    final enabled = ref.read(notificationsEnabledProvider);
    if (!enabled) {
      debugPrint('🔔 Notifications are disabled globally');
      return;
    }

    // Check per-category toggle
    bool categoryEnabled = true;
    switch (type) {
      case 'temperature':
        categoryEnabled = ref.read(tempNotifyProvider);
        break;
      case 'humidity':
        categoryEnabled = ref.read(humidityNotifyProvider);
        break;
      case 'light':
        categoryEnabled = ref.read(lightNotifyProvider);
        break;
    }
    
    if (!categoryEnabled) {
      debugPrint('🔔 Notifications for $type are disabled');
      return;
    }

    // Rate limiting: Only one notification per type every 2 minutes
    final now = DateTime.now();
    final lastTime = _lastNotificationTime[type];
    if (lastTime != null && now.difference(lastTime) < const Duration(minutes: 2)) {
      return;
    }
    _lastNotificationTime[type] = now;

    // Build notification content
    String title;
    String body;
    int id;

    switch (type) {
      case 'temperature':
        title = '🌡️ Temperature Alert — Classroom A';
        body = 'Temperature is critically high at ${value.toStringAsFixed(1)}°C! Consider opening windows or activating the AC system.';
        id = 1001;
        break;
      case 'humidity':
        title = '💧 Humidity Alert — Classroom A';
        body = 'Humidity has spiked to ${value.toStringAsFixed(1)}%! Turn on ventilation or dehumidifier to protect equipment.';
        id = 1002;
        break;
      case 'light':
        title = '💡 Low Light Alert — Classroom A';
        body = 'Light level dropped to ${value.toStringAsFixed(1)}%. Turn on classroom lights or open blinds for better visibility.';
        id = 1003;
        break;
      default:
        return;
    }

    // Fire notification
    NotificationService().showAlert(id: id, title: title, body: body, payload: type);

    // Log to history
    ref.read(alertHistoryProvider.notifier).add(
      AlertItem(title: title, body: body, timestamp: DateTime.now(), type: type),
    );
  };

  return notifier;
});

final chatMessagesProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>(
  (ref) => ChatNotifier(),
);

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

final selectedSceneProvider = StateProvider<String?>((ref) => null);

final selectedTabProvider = StateProvider<int>((ref) => 0);
