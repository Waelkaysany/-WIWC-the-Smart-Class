import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_colors.dart';
import '../../theme/tokens.dart';
import '../../widgets/chat_bubble.dart';

class AdminChatScreen extends ConsumerStatefulWidget {
  const AdminChatScreen({super.key});

  @override
  ConsumerState<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<AdminChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final messagesRef = _db.ref('admin_chats/${user.uid}/messages');
    final metaRef = _db.ref('admin_chats/${user.uid}/meta');

    final newMessage = {
      'text': text,
      'sender': 'user',
      'timestamp': ServerValue.timestamp,
      'read': false,
    };

    _controller.clear();

    try {
      await messagesRef.push().set(newMessage);
      // Update meta for admin overview
      await metaRef.update({
        'lastMessage': text,
        'lastTimestamp': ServerValue.timestamp,
        'unreadCount': ServerValue.increment(1),
        'userName': user.displayName ?? user.email?.split('@').first ?? 'User',
        'userEmail': user.email ?? '',
        'lastSender': 'user',
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login first')));
    }

    final messagesStream = _db
        .ref('admin_chats/${user.uid}/messages')
        .orderByChild('timestamp')
        .onValue;

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<DatabaseEvent>(
          stream: _db.ref('admin_status/online').onValue,
          builder: (context, snapshot) {
            final isOnline = snapshot.hasData &&
                snapshot.data?.snapshot.value == true;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Support Chat',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? AppColors.primary : AppColors.textMuted,
                        shape: BoxShape.circle,
                        boxShadow: isOnline
                            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 4)]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? 'Admin is online' : 'Admin is offline',
                      style: TextStyle(
                        color: isOnline ? AppColors.primary : AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: context.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet.\nOur support team is here to help!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                final data = Map<dynamic, dynamic>.from(
                    snapshot.data!.snapshot.value as Map);
                final messages = data.entries.map((e) {
                  final val = Map<String, dynamic>.from(e.value as Map);
                  return val;
                }).toList();

                // Sort by timestamp
                messages.sort((a, b) => (a['timestamp'] ?? 0)
                    .compareTo(b['timestamp'] ?? 0));

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isUser = msg['sender'] == 'user';
                    final timestamp = msg['timestamp'] as int?;
                    final timeStr = timestamp != null
                        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
                            .toLocal()
                            .toString()
                            .substring(11, 16)
                        : '--:--';

                    return ChatBubble(
                      text: msg['text'] ?? '',
                      isUser: isUser,
                      time: timeStr,
                    );
                  },
                );
              },
            ),
          ),
          // Input Area
          Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
            decoration: BoxDecoration(
              color: context.surface,
              border: Border(
                top: BorderSide(color: context.cardBorder, width: 0.5),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: context.surfaceLight,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: context.textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppShadows.subtleGlow,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
