import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Client-side scheduler that periodically checks for due actions in RTDB
/// and executes them. This replaces Cloud Functions (which require Blaze plan).
class SchedulerService {
  final FirebaseDatabase _db;
  Timer? _timer;
  final _uuid = const Uuid();
  bool _isProcessing = false;

  SchedulerService(this._db);

  /// Start the scheduler. Checks every 30 seconds for due actions.
  void start() {
    debugPrint('⏰ Scheduler started');
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _processDueActions());
    // Also run immediately on start
    _processDueActions();
  }

  /// Stop the scheduler.
  void stop() {
    _timer?.cancel();
    _timer = null;
    debugPrint('⏰ Scheduler stopped');
  }

  /// Check for and execute any due actions.
  Future<void> _processDueActions() async {
    if (_isProcessing) return; // Prevent concurrent runs
    _isProcessing = true;

    try {
      final snapshot = await _db.ref('ai_assistant/scheduled_actions').get();
      if (!snapshot.exists) {
        _isProcessing = false;
        return;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final entry in data.entries) {
        final actionId = entry.key as String;
        final action = Map<String, dynamic>.from(entry.value as Map);

        // Only process pending actions that are due
        if (action['status'] != 'pending') continue;
        final runAt = (action['runAt'] as num).toInt();
        if (runAt > now) continue;

        // Execute the action
        debugPrint('⏰ Executing scheduled action: $actionId');
        await _executeAction(actionId, action);
      }
    } catch (e) {
      debugPrint('⏰ Scheduler error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Execute a single scheduled action.
  Future<void> _executeAction(String actionId, Map<String, dynamic> action) async {
    final deviceId = action['deviceId'] as String;
    final actionType = action['action'] as String;

    try {
      // Get current device state for logging
      final deviceSnapshot = await _db.ref('classroom/devices/$deviceId').get();
      final previousState = deviceSnapshot.exists
          ? Map<String, dynamic>.from(deviceSnapshot.value as Map)
          : {};

      // Update device state
      final bool newIsOn = actionType == 'on' || actionType == 'open';
      await _db.ref('classroom/devices/$deviceId').update({
        'isOn': newIsOn,
      });

      // Mark action as executed
      await _db.ref('ai_assistant/scheduled_actions/$actionId').update({
        'status': 'executed',
        'executedAt': ServerValue.timestamp,
      });

      // Write action log
      final logId = _uuid.v4();
      await _db.ref('ai_assistant/action_logs/$logId').set({
        'deviceId': deviceId,
        'deviceName': _getDeviceName(deviceId),
        'action': actionType,
        'previousState': previousState,
        'result': 'success',
        'executedAt': ServerValue.timestamp,
        'triggeredBy': 'scheduler',
        'scheduledActionId': actionId,
      });

      debugPrint('✅ Scheduled action executed: $deviceId → $actionType');
    } catch (e) {
      // Mark as failed
      await _db.ref('ai_assistant/scheduled_actions/$actionId').update({
        'status': 'failed',
        'error': e.toString(),
      });
      debugPrint('❌ Scheduled action failed: $e');
    }
  }

  String _getDeviceName(String deviceId) {
    const names = {
      'lights': 'Lights',
      'door': 'Door Lock',
      'projector': 'Projector',
      'board': 'Smart Board',
      'ac': 'Air Conditioner',
      'speakers': 'Speakers',
      'window_left': 'Left Window',
      'window_right': 'Right Window',
    };
    return names[deviceId] ?? deviceId;
  }
}
