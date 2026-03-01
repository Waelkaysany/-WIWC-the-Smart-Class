import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/classroom_stats.dart';
import '../models/device.dart';
import '../models/environment_data.dart';
import '../services/firebase_service.dart';

// ── Classroom Stats ──

class ClassroomStatsNotifier extends StateNotifier<ClassroomStats> {
  Timer? _timer;
  final Random _random = Random();

  ClassroomStatsNotifier()
      : super(const ClassroomStats(
          devicesOnlinePercent: 97,
          studentsPresent: 0,
          maleStudents: 0,
          femaleStudents: 0,
          focusRate: 82,
          participation: 74,
          noiseIndex: 'Low',
          activeNowMin: 0,
          activeNowMax: 0,
          peakActivity: '10:00 AM',
          bestQuizTime: '10–11 AM',
          activityGraph: [0.3, 0.5, 0.7, 0.9, 1.0, 0.8, 0.6, 0.4],
        )) {
    _startLiveUpdates();
  }

  void _startLiveUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      final focusDelta = (_random.nextDouble() * 4) - 2;
      final partDelta = (_random.nextDouble() * 4) - 2;
      final noises = ['Low', 'Low', 'Low', 'Moderate', 'Low'];

      state = state.copyWith(
        // studentsPresent is now driven by ESP32 RFID via Firebase
        focusRate: (state.focusRate + focusDelta).clamp(60, 98),
        participation: (state.participation + partDelta).clamp(55, 95),
        noiseIndex: noises[_random.nextInt(noises.length)],
        activityGraph: List.generate(
            8, (i) => (state.activityGraph[i] + (_random.nextDouble() * 0.2 - 0.1)).clamp(0.1, 1.0)),
      );
    });
  }

  /// Called when real student count arrives from Firebase (ESP32 RFID)
  void updateStudentCount(int count) {
    state = state.copyWith(
      studentsPresent: count,
      activeNowMin: (count - 2).clamp(0, count),
      activeNowMax: (count + 2).clamp(count, 40),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ── Devices ──

class DevicesNotifier extends StateNotifier<List<Device>> {
  final DatabaseService? _dbService;

  DevicesNotifier([this._dbService])
      : super([
          const Device(
            id: 'lights',
            name: 'Lights',
            icon: Icons.lightbulb_outline,
            isOn: true,
            subtitle: '4 devices',
            category: 'Lights',
            brightness: 0.72,
          ),
          const Device(
            id: 'door',
            name: 'Door Lock',
            icon: Icons.lock_outline,
            isOn: true,
            subtitle: 'Main door',
            category: 'Door',
          ),
          const Device(
            id: 'projector',
            name: 'Projector',
            icon: Icons.videocam_outlined,
            isOn: true,
            subtitle: 'Epson EB-X51',
            category: 'Projector',
          ),
          const Device(
            id: 'board',
            name: 'Smart Board',
            icon: Icons.desktop_windows_outlined,
            isOn: false,
            subtitle: 'Interactive panel',
            category: 'Board',
          ),
          const Device(
            id: 'ac',
            name: 'AC',
            icon: Icons.ac_unit,
            isOn: true,
            subtitle: 'Cool mode',
            category: 'AC',
            mode: 'Cool',
          ),
          const Device(
            id: 'speakers',
            name: 'Speakers',
            icon: Icons.speaker_outlined,
            isOn: false,
            subtitle: 'JBL system',
            category: 'Speaker',
          ),
          const Device(
            id: 'window_left',
            name: 'Window Left',
            icon: Icons.window_outlined,
            isOn: false,
            subtitle: 'Left side',
            category: 'Windows',
          ),
          const Device(
            id: 'window_right',
            name: 'Window Right',
            icon: Icons.window_outlined,
            isOn: false,
            subtitle: 'Right side',
            category: 'Windows',
          ),
        ]);

  Future<void> _updateRemote(String id, Map<String, dynamic> data) async {
    try {
      if (_dbService != null) {
        await _dbService!.updateDeviceState(id, data);
      }
    } catch (e) {
      debugPrint('Error updating device $id: $e');
    }
  }

  void updateFromMap(Map<String, dynamic> data) {
    // Sync local state with remote data
    state = [
      for (final device in state)
        if (data.containsKey(device.id))
          _updateDeviceFromMap(device, Map<String, dynamic>.from(data[device.id] as Map))
        else
          device,
    ];
  }

  Device _updateDeviceFromMap(Device device, Map<String, dynamic> map) {
    return device.copyWith(
      isOn: map['isOn'] as bool? ?? device.isOn,
      brightness: (map['brightness'] as num?)?.toDouble() ?? device.brightness,
      mode: map['mode'] as String? ?? device.mode,
    );
  }

  void toggle(String id) {
    final device = state.firstWhere((d) => d.id == id, orElse: () => state.first);
    final newState = !device.isOn;
    
    state = [
      for (final d in state)
        if (d.id == id) d.copyWith(isOn: newState) else d,
    ];
    
    _updateRemote(id, {'isOn': newState});
  }

  void setBrightness(String id, double value) {
    state = [
      for (final d in state)
        if (d.id == id) d.copyWith(brightness: value) else d,
    ];
    
    _updateRemote(id, {'brightness': value});
  }

  void setMode(String id, String mode) {
    state = [
      for (final d in state)
        if (d.id == id) d.copyWith(mode: mode) else d,
    ];
    
    _updateRemote(id, {'mode': mode});
  }

  void applyScene(String scene) {
    // Apply local state first for immediate UI feedback, then sync
    List<Device> newState = [];
    
    switch (scene) {
      case 'Lecture Mode':
        newState = [
          for (final d in state)
            d.copyWith(
              isOn: d.id == 'lights' ||
                  d.id == 'projector' ||
                  d.id == 'ac' ||
                  d.id == 'speakers',
            ),
        ];
        break;
      case 'Exam Mode':
        newState = [
          for (final d in state)
            d.copyWith(
              isOn: d.id == 'lights' || d.id == 'door' || d.id == 'ac',
            ),
        ];
        break;
      case 'Presentation Mode':
        newState = [
          for (final d in state)
            d.copyWith(
              isOn: d.id != 'lights',
              brightness: d.id == 'lights' ? 0.3 : d.brightness,
            ),
        ];
        break;
      case 'Break Mode':
        newState = [
          for (final d in state) d.copyWith(isOn: d.id == 'ac'),
        ];
        break;
      default:
        newState = state;
    }
    
    state = newState;

    // Sync all affected devices to firebase
    for (final device in newState) {
       // For now, let's update all to ensure consistency
       final Map<String, dynamic> updates = {'isOn': device.isOn};
       if (device.brightness != null) updates['brightness'] = device.brightness;
       if (device.mode != null) updates['mode'] = device.mode;
       
       _updateRemote(device.id, updates);
    }
  }
}

class EnvironmentNotifier extends StateNotifier<EnvironmentData> {
  // Callback for firing notifications — set by the provider
  void Function(String type, double value)? onAlert;

  EnvironmentNotifier()
      : super(const EnvironmentData(
          temperature: 23,
          humidity: 55,
          lightLevel: 72,
          studentsPresent: 0,
          airQuality: 95,
        ));

  void update(EnvironmentData data) {
    if (data.temperature > 30) onAlert?.call('temperature', data.temperature);
    if (data.humidity > 80) onAlert?.call('humidity', data.humidity);
    if (data.lightLevel < 20) onAlert?.call('light', data.lightLevel);
    
    state = data;
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// ── Chat ──

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier()
      : super([
          ChatMessage(
            text: 'Good morning! I\'m your WIWC AI Assistant. How can I help you manage your classroom today?',
            isUser: false,
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
          ChatMessage(
            text: 'What\'s the current attendance like?',
            isUser: true,
            timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
          ),
          ChatMessage(
            text: 'Currently 28 out of 32 students are present (87.5%). Attendance is above average for this time slot. 3 students joined in the last 10 minutes.',
            isUser: false,
            timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
          ),
        ]);

  void sendMessage(String text) {
    state = [
      ...state,
      ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
    ];

    Future.delayed(const Duration(milliseconds: 800), () {
      state = [
        ...state,
        ChatMessage(
          text: _generateResponse(text),
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];
    });
  }

  String _generateResponse(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('quiz') || lower.contains('test')) {
      return 'I\'ve prepared a 10-question quiz based on today\'s topics. The best time to launch is between 10-11 AM when engagement peaks. Want me to schedule it?';
    } else if (lower.contains('noise') || lower.contains('quiet')) {
      return 'The current noise level is Low. I can activate "Focus Mode" which dims lights slightly and sends a gentle reminder to students\' devices, shall I proceed?';
    } else if (lower.contains('summary') || lower.contains('summarize')) {
      return 'Today\'s class summary: 28 students attended. Peak engagement at 10:00 AM. Focus rate averaged 82%. 3 interactive activities were completed. Overall class performance: Above Average.';
    } else if (lower.contains('temperature') || lower.contains('ac') || lower.contains('cool')) {
      return 'Current temperature is 28°C with 65% humidity. The AC is running in Cool mode. I can optimize it to 24°C for better focus — studies show 22-24°C is ideal for learning.';
    } else if (lower.contains('attendance')) {
      return 'Current attendance: 28/32 students (87.5%). 16 male, 12 female students. All teaching staff present. 2 students marked as excused absence.';
    } else {
      return 'I\'ve analyzed your request. Based on the current classroom data, all systems are running optimally. Is there anything specific you\'d like me to adjust or report on?';
    }
  }
}
