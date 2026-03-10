import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'firebase_service.dart';

/// Represents one message in the AI chat.
class AiChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ActionProposal? actionProposal;

  AiChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.actionProposal,
  });
}

/// An action proposed by the AI that needs user confirmation.
class ActionProposal {
  final String id;
  final String deviceId;
  final String deviceName;
  final String roomId;
  final String action; // "on", "off", "open", "close"
  final String description;
  bool isConfirmed;
  bool isCancelled;

  ActionProposal({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.roomId,
    required this.action,
    required this.description,
    this.isConfirmed = false,
    this.isCancelled = false,
  });
}

class AiChatService {
  final FirebaseDatabase _db;
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final _uuid = const Uuid();

  // Track pending proposals
  final Map<String, ActionProposal> _pendingProposals = {};

  // System prompt
  static const String _systemPrompt = '''
You are WIWC Assistant, the AI assistant for the WIWC Smart Classroom system.
You help teachers and admins manage classroom devices, check room status, schedule actions, AND answer questions about the app itself.

═══════════════════════════════════
DEVICE CONTROL RULES
═══════════════════════════════════
- Use tools to get REAL data. Never invent room names, device IDs, or sensor readings.
- When a user asks to control a device, ALWAYS use proposeDeviceAction first. Never directly change device state.
- For bulk actions (e.g. "close all windows"), propose each device separately so the user can confirm each one.
- Students can only view data. Teachers and admins can control devices.
- When proposing an action, describe what will happen clearly so the user can confirm or cancel via the card that appears.
- For scheduling, confirm the exact time and device before scheduling.

═══════════════════════════════════
CLASSROOM INFO
═══════════════════════════════════
- The classroom is called "Classroom A" with id "classroom_a".
- Devices: lights, door, projector, board (smart board), ac (air conditioner), speakers, window_left, window_right.
- Device states: isOn (true/false), brightness (0.0-1.0 for lights), mode (for AC: Cool/Heat/Fan).
- For "close/open windows": window_left and window_right are the two window devices. Propose action for EACH window separately.

═══════════════════════════════════
SMART RECOMMENDATIONS
═══════════════════════════════════
When the user asks for advice like "should I open the windows?", "is the temperature OK?", "what should I do?":
1. ALWAYS use getRoomStatus first to check real sensor data.
2. Base your recommendation on actual readings:

Temperature guidelines:
- Below 18°C: Too cold. Recommend closing windows, turning on AC in Heat mode.
- 18–24°C: Comfortable. No changes needed unless humidity is off.
- 24–28°C: Getting warm. Recommend opening windows for fresh air, or turn on AC in Cool mode.
- Above 28°C: Too hot. Strongly recommend AC in Cool mode + open windows.

Humidity guidelines:
- Below 30%: Too dry. Suggest opening windows for airflow.
- 30–60%: Ideal range.
- Above 60%: Too humid. Recommend AC or ventilation.

Light level guidelines:
- Below 30%: Too dark for studying. Recommend turning on lights.
- 30–70%: Acceptable range.
- Above 70%: Bright enough. Lights can be turned off to save energy.

Best times to open windows:
- Morning (8-10 AM): Great for fresh air before class.
- Break times: Good for ventilation.
- Avoid: During heavy rain, extreme heat (>35°C), or if air quality is poor.

═══════════════════════════════════
APP NAVIGATION & HELP
═══════════════════════════════════
The WIWC app has 4 main tabs at the bottom:

1. 📊 LIVE TAB (Home) — Shows real-time sensor data:
   - Temperature, humidity, light level gauges
   - Student count (from RFID attendance)
   - Environment alerts and insights
   - Quick stats overview

2. 🎛️ CONTROLS TAB — Device management:
   - Toggle devices on/off (lights, AC, projector, etc.)
   - Adjust brightness for lights
   - Change AC mode (Cool/Heat/Fan)
   - Scene presets: "Movie Mode", "Focus Mode", "Presentation Mode", "Energy Saver"
   - Filter devices by category

3. 🤖 ASSISTANT TAB (this chat) — AI-powered help:
   - Ask questions about the classroom
   - Control devices through conversation
   - Get smart recommendations
   - Schedule future actions

4. 👤 PROFILE TAB — Account & settings:
   - View your profile (name, email, role)
   - Change profile picture: tap the camera icon on your avatar
   - Change password: Go to Profile → Account → "Change Password" button
   - Change language: Profile → Account → Language selector (Arabic/English/French)
   - Change theme: Profile → tap the sun/moon toggle in the top right for dark/light mode
   - Notification settings: Profile → Notifications → toggle alerts for temperature, humidity, light
   - Help & Support: Profile → Help & Support
   - Approvals: Profile → Approvals (for pending requests)
   - Log out: Profile → scroll down → "Log Out" button

Common user questions:
- "Where do I change my password?" → Profile tab → Account → Change Password
- "How do I switch to dark mode?" → Profile tab → tap the sun/moon icon at the top right
- "How to change language?" → Profile tab → Account → Language section
- "How to see temperature?" → Live tab — it shows real-time temperature gauge
- "How to turn off lights?" → Controls tab, or ask me and I will do it for you
- "Who is in the classroom?" → Live tab shows student count, or ask me
- "How do I enable notifications?" → Profile tab → Notifications → toggle each alert type

═══════════════════════════════════
SUPPORT REQUESTS — YOU CAN REPORT PROBLEMS TO THE ADMIN!
═══════════════════════════════════
IMPORTANT: You have the ability to report problems to the SuperAdmin using the "reportProblem" tool.
When a teacher asks you to report something, or mentions a problem that needs admin attention, you MUST call the reportProblem tool.

How to use it:
- Call reportProblem with: title (short summary), description (detailed info), priority ("low", "medium", "high", or "critical")
- The tool will automatically submit a support ticket to the SuperAdmin dashboard.
- After calling the tool, confirm to the teacher that the problem has been reported.

When to call reportProblem:
- Teacher says "report to admin", "send to admin", "tell the admin", "I have a problem", "report this problem"
- A device seems broken or unresponsive
- Teacher mentions an issue: broken projector, AC not working, door stuck, lights flickering, etc.
- Teacher explicitly asks you to create a ticket or support request

Priority guidelines:
- "low": Minor issue, not urgent (e.g. a small cosmetic issue)
- "medium": Something is not working perfectly (e.g. light flickering)
- "high": A device is completely broken or not responding (e.g. projector won't turn on)
- "critical": Safety issue or multiple systems down

Examples:
- "Report to admin the projector is broken" → Call reportProblem(title: "Projector not working", description: "Teacher reports the projector is not turning on", priority: "high")
- "Tell admin AC is making noise" → Call reportProblem(title: "AC making unusual noise", description: "Teacher reports AC unit making noise during operation", priority: "medium")
- "I have a problem" → Ask what the problem is, then call reportProblem

DO NOT say you cannot report problems. You CAN. Just call the reportProblem tool.

═══════════════════════════════════
GENERAL BEHAVIOR
═══════════════════════════════════
- Be friendly, helpful, and concise.
- Format responses naturally. Don't expose internal tool names or IDs to the user.
- If the user asks something about the app, answer from your knowledge above — no need to call tools.
- If the user asks about environment conditions (temperature, should I open windows, etc.), ALWAYS call getRoomStatus first to get real data, then give advice.
- If you don't know something, say so honestly.
- You can also explain how the WIWC system works: it monitors classroom environment with sensors and lets authorized users control devices remotely.
''';

  AiChatService(this._db) {
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      tools: _buildTools(),
      systemInstruction: Content.system(_systemPrompt),
    );
    _chat = _model.startChat();
  }

  /// Build the tool declarations for function calling.
  List<Tool> _buildTools() {
    return [
      Tool.functionDeclarations([
        // 1. getRooms — no parameters
        FunctionDeclaration(
          'getRooms',
          'List all available rooms/classrooms in the system.',
          parameters: {},
        ),

        // 2. listDevices
        FunctionDeclaration(
          'listDevices',
          'List all devices in a specific room with their current state.',
          parameters: {
            'roomId': Schema.string(
              description: 'The room ID, e.g. "classroom_a"',
            ),
          },
        ),

        // 3. getRoomStatus
        FunctionDeclaration(
          'getRoomStatus',
          'Get current sensor readings and environment data for a room (temperature, humidity, light level, student count).',
          parameters: {
            'roomId': Schema.string(
              description: 'The room ID, e.g. "classroom_a"',
            ),
          },
        ),

        // 4. proposeDeviceAction
        FunctionDeclaration(
          'proposeDeviceAction',
          'Propose a device action for user confirmation. Returns a proposal that the user must confirm before execution. Use this BEFORE any device change.',
          parameters: {
            'deviceId': Schema.string(
              description: 'The device ID (e.g. "lights", "ac", "window_left")',
            ),
            'action': Schema.string(
              description: 'The action: "on", "off", "open", or "close"',
            ),
            'description': Schema.string(
              description: 'Human-readable description of what will happen',
            ),
          },
        ),

        // 5. scheduleDeviceAction
        FunctionDeclaration(
          'scheduleDeviceAction',
          'Schedule a device action to run after a specified delay in minutes.',
          parameters: {
            'deviceId': Schema.string(
              description: 'The device ID',
            ),
            'action': Schema.string(
              description: 'The action: "on" or "off"',
            ),
            'delayMinutes': Schema.integer(
              description: 'Number of minutes to wait before executing',
            ),
            'description': Schema.string(
              description: 'Human-readable description of the scheduled action',
            ),
          },
        ),

        // 6. cancelScheduledAction
        FunctionDeclaration(
          'cancelScheduledAction',
          'Cancel a previously scheduled action by its ID.',
          parameters: {
            'actionId': Schema.string(
              description: 'The scheduled action ID to cancel',
            ),
          },
        ),

        // 7. getScheduledActions — no parameters
        FunctionDeclaration(
          'getScheduledActions',
          'List all pending scheduled actions.',
          parameters: {},
        ),

        // 8. getRecentLogs — no parameters
        FunctionDeclaration(
          'getRecentLogs',
          'Get recent action logs showing what device actions have been performed.',
          parameters: {},
        ),

        // 9. getDeviceStatus
        FunctionDeclaration(
          'getDeviceStatus',
          'Get the current status of a specific device.',
          parameters: {
            'deviceId': Schema.string(
              description: 'The device ID to check',
            ),
          },
        ),

        // 10. reportProblem
        FunctionDeclaration(
          'reportProblem',
          'Report a problem or issue to the SuperAdmin. Use this when a teacher reports a broken device, malfunctioning system, or any classroom issue that needs admin attention.',
          parameters: {
            'title': Schema.string(
              description: 'A short, clear title for the problem (e.g. "Projector not working")',
            ),
            'description': Schema.string(
              description: 'Detailed description of the problem',
            ),
            'priority': Schema.string(
              description: 'Priority level: "low", "medium", "high", or "critical"',
            ),
          },
        ),
      ]),
    ];
  }

  /// Send a message to the AI and get a response. Handles the tool-calling loop.
  Future<AiChatMessage> sendMessage(String userMessage) async {
    try {
      var response = await _chat.sendMessage(Content.text(userMessage));

      // Tool-calling loop
      int maxIterations = 10;
      while (maxIterations-- > 0) {
        final functionCalls = response.functionCalls.toList();
        if (functionCalls.isEmpty) break;

        // Process each function call and send responses one at a time
        ActionProposal? lastProposal;

        for (final call in functionCalls) {
          debugPrint('🤖 AI calling tool: ${call.name}(${call.args})');
          final result = await _handleToolCall(call.name, call.args);

          // Check if this was a proposal
          if (call.name == 'proposeDeviceAction' && result.containsKey('proposalId')) {
            lastProposal = _pendingProposals[result['proposalId']];
          }

          // Send function response back
          response = await _chat.sendMessage(
            Content.functionResponse(call.name, result),
          );
        }

        // If we had a proposal, return the message with the proposal attached
        if (lastProposal != null && response.text != null) {
          return AiChatMessage(
            text: response.text!,
            isUser: false,
            timestamp: DateTime.now(),
            actionProposal: lastProposal,
          );
        }
      }

      final text = response.text ?? 'I apologize, I couldn\'t process that request. Could you try again?';
      return AiChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ AI Error: $e');
      return AiChatMessage(
        text: 'Sorry, I encountered an error. Please try again in a moment.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Handle a tool call from the AI model.
  Future<Map<String, dynamic>> _handleToolCall(String name, Map<String, dynamic> args) async {
    switch (name) {
      case 'getRooms':
        return _toolGetRooms();
      case 'listDevices':
        return _toolListDevices(args['roomId'] as String? ?? 'classroom_a');
      case 'getRoomStatus':
        return _toolGetRoomStatus(args['roomId'] as String? ?? 'classroom_a');
      case 'proposeDeviceAction':
        return _toolProposeDeviceAction(
          args['deviceId'] as String,
          args['action'] as String,
          args['description'] as String? ?? '',
        );
      case 'scheduleDeviceAction':
        return _toolScheduleDeviceAction(
          args['deviceId'] as String,
          args['action'] as String,
          (args['delayMinutes'] as num).toInt(),
          args['description'] as String? ?? '',
        );
      case 'cancelScheduledAction':
        return _toolCancelScheduledAction(args['actionId'] as String);
      case 'getScheduledActions':
        return _toolGetScheduledActions();
      case 'getRecentLogs':
        return _toolGetRecentLogs();
      case 'getDeviceStatus':
        return _toolGetDeviceStatus(args['deviceId'] as String);
      case 'reportProblem':
        return _toolReportProblem(
          (args['title'] ?? 'Issue reported by teacher').toString(),
          (args['description'] ?? 'No description provided').toString(),
          (args['priority'] ?? 'medium').toString(),
        );
      default:
        return {'error': 'Unknown tool: $name'};
    }
  }

  // ── Tool Implementations ──

  Future<Map<String, dynamic>> _toolGetRooms() async {
    return {
      'rooms': [
        {
          'id': 'classroom_a',
          'name': 'Classroom A',
          'building': 'Main Building',
          'floor': '1st Floor',
          'capacity': 32,
        },
      ],
    };
  }

  Future<Map<String, dynamic>> _toolListDevices(String roomId) async {
    try {
      final snapshot = await _db.ref('classroom/devices').get();
      if (!snapshot.exists) {
        return {'devices': [], 'message': 'No devices found'};
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final devices = <Map<String, dynamic>>[];

      data.forEach((key, value) {
        final deviceData = Map<String, dynamic>.from(value as Map);
        devices.add({
          'id': key,
          'name': _deviceNames[key] ?? key,
          'isOn': deviceData['isOn'] ?? false,
          if (deviceData['brightness'] != null) 'brightness': deviceData['brightness'],
          if (deviceData['mode'] != null) 'mode': deviceData['mode'],
        });
      });

      return {'roomId': roomId, 'devices': devices};
    } catch (e) {
      return {'error': 'Failed to read devices: $e'};
    }
  }

  Future<Map<String, dynamic>> _toolGetRoomStatus(String roomId) async {
    try {
      final snapshot = await _db.ref('classroom/sensors').get();
      if (!snapshot.exists) {
        return {'error': 'No sensor data available'};
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return {
        'roomId': roomId,
        'roomName': 'Classroom A',
        'sensors': {
          'temperature': data['temperature'] ?? 0,
          'humidity': data['humidity'] ?? 0,
          'lightLevel': data['lightLevel'] ?? 0,
          'studentsPresent': data['studentsPresent'] ?? 0,
          'airQuality': data['airQuality'] ?? 0,
        },
      };
    } catch (e) {
      return {'error': 'Failed to read sensors: $e'};
    }
  }

  Future<Map<String, dynamic>> _toolProposeDeviceAction(
    String deviceId,
    String action,
    String description,
  ) async {
    // Validate user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'error': 'You must be logged in to control devices.'};
    }

    // Check role
    final profileSnapshot = await _db.ref('users/${user.uid}').get();
    if (profileSnapshot.exists) {
      final profile = Map<String, dynamic>.from(profileSnapshot.value as Map);
      final role = profile['role'] as String? ?? 'student';
      if (role == 'student') {
        return {'error': 'Students are not allowed to control devices. Please ask your teacher.'};
      }
    }

    // Validate device
    final deviceSnapshot = await _db.ref('classroom/devices/$deviceId').get();
    if (!deviceSnapshot.exists) {
      return {'error': 'Device "$deviceId" not found.'};
    }

    // Create proposal
    final proposalId = _uuid.v4();
    final proposal = ActionProposal(
      id: proposalId,
      deviceId: deviceId,
      deviceName: _deviceNames[deviceId] ?? deviceId,
      roomId: 'classroom_a',
      action: action,
      description: description,
    );
    _pendingProposals[proposalId] = proposal;

    return {
      'proposalId': proposalId,
      'deviceId': deviceId,
      'deviceName': _deviceNames[deviceId] ?? deviceId,
      'action': action,
      'description': description,
      'status': 'awaiting_confirmation',
      'message': 'Action proposed. Waiting for user to confirm or cancel.',
    };
  }

  /// Execute a confirmed proposal.
  Future<void> confirmProposal(String proposalId) async {
    final proposal = _pendingProposals[proposalId];
    if (proposal == null) return;

    proposal.isConfirmed = true;

    try {
      // Get current state for logging
      final deviceSnapshot = await _db.ref('classroom/devices/${proposal.deviceId}').get();
      final previousState = deviceSnapshot.exists
          ? Map<String, dynamic>.from(deviceSnapshot.value as Map)
          : {};

      // Update device state
      final bool newIsOn = proposal.action == 'on' || proposal.action == 'open';
      await _db.ref('classroom/devices/${proposal.deviceId}').update({
        'isOn': newIsOn,
      });

      // Write action log
      final logId = _uuid.v4();
      await _db.ref('ai_assistant/action_logs/$logId').set({
        'deviceId': proposal.deviceId,
        'deviceName': proposal.deviceName,
        'action': proposal.action,
        'previousState': previousState,
        'result': 'success',
        'executedAt': ServerValue.timestamp,
        'triggeredBy': 'user_confirmed',
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
      });

      debugPrint('✅ Action confirmed: ${proposal.deviceName} → ${proposal.action}');
    } catch (e) {
      debugPrint('❌ Action execution error: $e');
    }
  }

  /// Cancel a proposal.
  void cancelProposal(String proposalId) {
    final proposal = _pendingProposals[proposalId];
    if (proposal != null) {
      proposal.isCancelled = true;
    }
  }

  Future<Map<String, dynamic>> _toolScheduleDeviceAction(
    String deviceId,
    String action,
    int delayMinutes,
    String description,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'error': 'You must be logged in.'};
    if (delayMinutes < 1 || delayMinutes > 480) {
      return {'error': 'Delay must be between 1 and 480 minutes (8 hours max).'};
    }

    final deviceSnapshot = await _db.ref('classroom/devices/$deviceId').get();
    if (!deviceSnapshot.exists) return {'error': 'Device "$deviceId" not found.'};

    final actionId = _uuid.v4();
    final runAt = DateTime.now().add(Duration(minutes: delayMinutes)).millisecondsSinceEpoch;
    final formatter = DateFormat('HH:mm');
    final runAtFormatted = formatter.format(DateTime.fromMillisecondsSinceEpoch(runAt));

    await _db.ref('ai_assistant/scheduled_actions/$actionId').set({
      'deviceId': deviceId,
      'action': action,
      'delayMinutes': delayMinutes,
      'runAt': runAt,
      'status': 'pending',
      'description': description,
      'createdBy': user.uid,
      'createdAt': ServerValue.timestamp,
    });

    return {
      'actionId': actionId,
      'deviceId': deviceId,
      'action': action,
      'scheduledFor': runAtFormatted,
      'delayMinutes': delayMinutes,
      'status': 'scheduled',
      'message': 'Action scheduled. Will run at $runAtFormatted.',
    };
  }

  Future<Map<String, dynamic>> _toolCancelScheduledAction(String actionId) async {
    try {
      final snapshot = await _db.ref('ai_assistant/scheduled_actions/$actionId').get();
      if (!snapshot.exists) return {'error': 'Scheduled action not found.'};

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      if (data['status'] != 'pending') {
        return {'error': 'Action is already ${data['status']}. Cannot cancel.'};
      }

      await _db.ref('ai_assistant/scheduled_actions/$actionId').update({
        'status': 'cancelled',
      });

      return {'actionId': actionId, 'status': 'cancelled', 'message': 'Scheduled action cancelled.'};
    } catch (e) {
      return {'error': 'Failed to cancel: $e'};
    }
  }

  Future<Map<String, dynamic>> _toolGetScheduledActions() async {
    try {
      final snapshot = await _db.ref('ai_assistant/scheduled_actions').get();
      if (!snapshot.exists) return {'actions': [], 'message': 'No scheduled actions.'};

      final data = snapshot.value as Map<dynamic, dynamic>;
      final actions = <Map<String, dynamic>>[];
      final formatter = DateFormat('HH:mm');

      data.forEach((key, value) {
        final action = Map<String, dynamic>.from(value as Map);
        if (action['status'] == 'pending') {
          actions.add({
            'actionId': key,
            'deviceId': action['deviceId'],
            'action': action['action'],
            'scheduledFor': formatter.format(
              DateTime.fromMillisecondsSinceEpoch((action['runAt'] as num).toInt()),
            ),
            'description': action['description'] ?? '',
            'status': action['status'],
          });
        }
      });

      return {'actions': actions};
    } catch (e) {
      return {'error': 'Failed to read scheduled actions: $e'};
    }
  }

  Future<Map<String, dynamic>> _toolGetRecentLogs() async {
    try {
      final snapshot = await _db.ref('ai_assistant/action_logs')
          .orderByChild('executedAt')
          .limitToLast(10)
          .get();

      if (!snapshot.exists) return {'logs': [], 'message': 'No recent logs.'};

      final data = snapshot.value as Map<dynamic, dynamic>;
      final logs = <Map<String, dynamic>>[];

      data.forEach((key, value) {
        final log = Map<String, dynamic>.from(value as Map);
        logs.add({
          'logId': key,
          'deviceName': log['deviceName'] ?? log['deviceId'],
          'action': log['action'],
          'result': log['result'],
          'triggeredBy': log['triggeredBy'],
        });
      });

      return {'logs': logs};
    } catch (e) {
      return {'error': 'Failed to read logs: $e'};
    }
  }

  Future<Map<String, dynamic>> _toolGetDeviceStatus(String deviceId) async {
    try {
      final snapshot = await _db.ref('classroom/devices/$deviceId').get();
      if (!snapshot.exists) return {'error': 'Device "$deviceId" not found.'};

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return {
        'deviceId': deviceId,
        'deviceName': _deviceNames[deviceId] ?? deviceId,
        'isOn': data['isOn'] ?? false,
        if (data['brightness'] != null) 'brightness': data['brightness'],
        if (data['mode'] != null) 'mode': data['mode'],
      };
    } catch (e) {
      return {'error': 'Failed to read device: $e'};
    }
  }

  // Human-readable device names
  static const _deviceNames = {
    'lights': 'Lights',
    'door': 'Door Lock',
    'projector': 'Projector',
    'board': 'Smart Board',
    'ac': 'Air Conditioner',
    'speakers': 'Speakers',
    'window_left': 'Left Window',
    'window_right': 'Right Window',
  };

  Future<Map<String, dynamic>> _toolReportProblem(
    String title,
    String description,
    String priority,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final teacherName = user?.displayName ?? user?.email?.split('@').first ?? 'Teacher';
      final teacherEmail = user?.email ?? '';
      final teacherId = user?.uid ?? 'unknown';

      debugPrint('📋 Submitting support request: title="$title", priority=$priority, teacher=$teacherName');

      final db = DatabaseService();
      final requestId = await db.submitSupportRequest(
        title: title,
        description: description,
        priority: priority,
        source: 'ai',
        teacherId: teacherId,
        teacherName: teacherName,
        teacherEmail: teacherEmail,
      );

      debugPrint('✅ Support request submitted: $requestId');

      return {
        'requestId': requestId,
        'title': title,
        'priority': priority,
        'status': 'submitted',
        'message': 'Support request submitted successfully. The SuperAdmin will review it.',
      };
    } catch (e) {
      debugPrint('❌ Report problem failed: $e');
      return {'error': 'Failed to submit support request: $e'};
    }
  }
}
