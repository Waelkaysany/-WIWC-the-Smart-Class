import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_colors.dart';
import '../../theme/tokens.dart';
import '../../state/ai_chat_provider.dart';
import '../../state/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/action_proposal_card.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(aiChatMessagesProvider.notifier).sendMessage(text, ref);
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
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
    final messages = ref.watch(aiChatMessagesProvider);
    final isLoading = ref.watch(aiChatLoadingProvider);
    final locale = ref.watch(localeProvider);
    String t(String key) => AppLocalizations.tr(locale, key);

    // Initialize scheduler when this screen is first built
    ref.watch(schedulerServiceProvider);

    // Auto-scroll when messages change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    final quickActions = [
      'What rooms are available?',
      'List devices in classroom',
      'Check room temperature',
      'Show recent activity',
      'What is scheduled?',
    ];

    return Column(
      children: [
        // ── Header ──
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppGradients.secondaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  t('aiAssistant'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                ),
                const Spacer(),
                // AI status indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AI Online',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF00E676),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Quick Actions ──
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            itemCount: quickActions.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: isLoading
                    ? null
                    : () {
                        _controller.text = quickActions[index];
                        _sendMessage();
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: context.surfaceLight,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: context.cardBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      quickActions[index],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.textSecondary,
                          ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ── Chat Messages ──
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
            itemCount: messages.length + (isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              // Typing indicator at the bottom
              if (index == messages.length && isLoading) {
                return _buildTypingIndicator(context);
              }

              final msg = messages[index];
              final hour = msg.timestamp.hour.toString().padLeft(2, '0');
              final minute = msg.timestamp.minute.toString().padLeft(2, '0');

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ChatBubble(
                    text: msg.text,
                    isUser: msg.isUser,
                    time: '$hour:$minute',
                  ),
                  // Show action proposal card if present
                  if (msg.actionProposal != null)
                    ActionProposalCard(
                      proposal: msg.actionProposal!,
                      onConfirm: () {
                        ref
                            .read(aiChatMessagesProvider.notifier)
                            .confirmProposal(msg.actionProposal!.id);
                        _scrollToBottom();
                      },
                      onCancel: () {
                        ref
                            .read(aiChatMessagesProvider.notifier)
                            .cancelProposal(msg.actionProposal!.id);
                        _scrollToBottom();
                      },
                    ),
                ],
              );
            },
          ),
        ),

        // ── Input Bar ──
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: context.surfaceLight,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: TextField(
                      controller: _controller,
                      enabled: !isLoading,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.textPrimary,
                          ),
                      decoration: InputDecoration(
                        hintText: isLoading
                            ? 'AI is thinking...'
                            : t('askAnything'),
                        hintStyle:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: context.textMuted,
                                ),
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
                  onTap: isLoading ? null : _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: isLoading
                          ? null
                          : AppGradients.primaryGradient,
                      color: isLoading
                          ? Colors.grey.withValues(alpha: 0.3)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isLoading ? null : AppShadows.subtleGlow,
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(context.textMuted),
                            ),
                          )
                        : Icon(Icons.send_rounded,
                            color: context.isDark
                                ? AppColors.background
                                : Colors.white,
                            size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Beautiful typing indicator animation.
  Widget _buildTypingIndicator(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.secondary.withValues(alpha: 0.12),
              context.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(
            color: context.secondary.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 14,
              color: context.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Thinking',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(width: 4),
            _AnimatedDots(),
          ],
        ),
      ),
    );
  }
}

/// Animated dots for the typing indicator.
class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final opacity = ((value - delay) % 1.0 < 0.5) ? 1.0 : 0.3;
            return Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Opacity(
                opacity: opacity,
                child: Text(
                  '.',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
