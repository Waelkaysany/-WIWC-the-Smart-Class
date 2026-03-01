import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_chat_service.dart';
import '../services/scheduler_service.dart';

// ── AI Chat Service Provider ──
final aiChatServiceProvider = Provider<AiChatService>((ref) {
  final db = FirebaseDatabase.instance;
  return AiChatService(db);
});

// ── Scheduler Service Provider ──
final schedulerServiceProvider = Provider<SchedulerService>((ref) {
  final db = FirebaseDatabase.instance;
  final scheduler = SchedulerService(db);
  scheduler.start();
  ref.onDispose(() => scheduler.stop());
  return scheduler;
});

// ── AI Chat Messages Provider ──
final aiChatMessagesProvider =
    StateNotifierProvider<AiChatNotifier, List<AiChatMessage>>((ref) {
  final chatService = ref.watch(aiChatServiceProvider);
  return AiChatNotifier(chatService);
});

// ── AI Loading State ──
final aiChatLoadingProvider = StateProvider<bool>((ref) => false);

/// StateNotifier managing the AI chat message list.
class AiChatNotifier extends StateNotifier<List<AiChatMessage>> {
  final AiChatService _chatService;

  AiChatNotifier(this._chatService)
      : super([
          AiChatMessage(
            text: 'Hello! I\'m your WIWC AI Assistant. I can help you manage classroom devices, check sensor data, and schedule actions. Try asking me "What devices are in the classroom?" or "Turn off the lights in 10 minutes".',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ]);

  /// Send a message to the AI.
  Future<void> sendMessage(String text, WidgetRef? ref) async {
    // Add user message
    state = [
      ...state,
      AiChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    ];

    // Set loading
    ref?.read(aiChatLoadingProvider.notifier).state = true;

    // Get AI response
    final response = await _chatService.sendMessage(text);

    // Add AI response
    state = [...state, response];

    // Clear loading
    ref?.read(aiChatLoadingProvider.notifier).state = false;
  }

  /// Confirm an action proposal.
  Future<void> confirmProposal(String proposalId) async {
    await _chatService.confirmProposal(proposalId);

    // Update the message in state to reflect confirmation
    state = [
      for (final msg in state)
        if (msg.actionProposal?.id == proposalId)
          AiChatMessage(
            text: msg.text,
            isUser: msg.isUser,
            timestamp: msg.timestamp,
            actionProposal: msg.actionProposal!..isConfirmed = true,
          )
        else
          msg,
    ];

    // Add confirmation message
    state = [
      ...state,
      AiChatMessage(
        text: '✅ Action confirmed and executed successfully.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }

  /// Cancel an action proposal.
  void cancelProposal(String proposalId) {
    _chatService.cancelProposal(proposalId);

    // Update the message in state
    state = [
      for (final msg in state)
        if (msg.actionProposal?.id == proposalId)
          AiChatMessage(
            text: msg.text,
            isUser: msg.isUser,
            timestamp: msg.timestamp,
            actionProposal: msg.actionProposal!..isCancelled = true,
          )
        else
          msg,
    ];

    // Add cancellation message
    state = [
      ...state,
      AiChatMessage(
        text: '❌ Action cancelled.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }
}
