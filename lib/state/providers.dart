import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/classroom_stats.dart';
import '../models/device.dart';
import '../models/environment_data.dart';
import 'controllers.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import 'notification_provider.dart';

final classroomStatsProvider =
    StateNotifierProvider<ClassroomStatsNotifier, ClassroomStats>(
  (ref) {
    final notifier = ClassroomStatsNotifier();
    // Sync student count from Firebase (ESP32 RFID) environment data
    ref.listen(environmentProvider, (previous, next) {
      notifier.updateStudentCount(next.studentsPresent);
    });
    return notifier;
  },
);

final devicesProvider =
    StateNotifierProvider<DevicesNotifier, List<Device>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final notifier = DevicesNotifier(dbService);

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
  final notifier = EnvironmentNotifier();

  // Watch the provider for continuous updates
  // Note: We use ref.listen instead of ref.watch in the body to avoid re-creating 
  // the notifier and causing rebuild loops.
  ref.listen(firebaseSensorProvider, (previous, next) {
    next.whenData((data) => notifier.update(data));
  });

  // Fetch initial data immediately if available
  final initial = ref.read(firebaseSensorProvider).asData?.value;
  if (initial != null) {
     // Use microtask to avoid updating during build
     Future.microtask(() => notifier.update(initial));
  }

  notifier.onAlert = (String type, double value) {
    // Check master toggle
    final enabled = ref.read(notificationsEnabledProvider);
    if (!enabled) return;

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
    if (!categoryEnabled) return;

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
