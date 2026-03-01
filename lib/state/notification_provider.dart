import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

// ── Master toggle ──
class NotificationSettingsNotifier extends StateNotifier<bool> {
  NotificationSettingsNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    if (!state) {
      await NotificationService().cancelAll();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', state);
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    if (!state) {
      await NotificationService().cancelAll();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', state);
  }
}

final notificationsEnabledProvider =
    StateNotifierProvider<NotificationSettingsNotifier, bool>(
  (ref) => NotificationSettingsNotifier(),
);

// ── Per-category toggles ──
class CategoryToggleNotifier extends StateNotifier<bool> {
  final String key;
  CategoryToggleNotifier(this.key) : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('notify_$key') ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_$key', state);
  }
}

final tempNotifyProvider =
    StateNotifierProvider<CategoryToggleNotifier, bool>(
  (ref) => CategoryToggleNotifier('temperature'),
);

final humidityNotifyProvider =
    StateNotifierProvider<CategoryToggleNotifier, bool>(
  (ref) => CategoryToggleNotifier('humidity'),
);

final lightNotifyProvider =
    StateNotifierProvider<CategoryToggleNotifier, bool>(
  (ref) => CategoryToggleNotifier('light'),
);

// ── Alert history (in-memory) ──
class AlertItem {
  final String title;
  final String body;
  final DateTime timestamp;
  final String type; // 'temperature', 'humidity', 'light'

  AlertItem({
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
  });
}

class AlertHistoryNotifier extends StateNotifier<List<AlertItem>> {
  AlertHistoryNotifier() : super([]);

  void add(AlertItem alert) {
    state = [alert, ...state].take(20).toList();
  }

  void clear() {
    state = [];
  }
}

final alertHistoryProvider =
    StateNotifierProvider<AlertHistoryNotifier, List<AlertItem>>(
  (ref) => AlertHistoryNotifier(),
);
