import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_colors.dart';
import '../../theme/tokens.dart';
import '../../state/providers.dart';
import '../../state/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/suggestion_card.dart';

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
    ref.read(chatMessagesProvider.notifier).sendMessage(text);
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
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
    final messages = ref.watch(chatMessagesProvider);
    final locale = ref.watch(localeProvider);
    String t(String key) => AppLocalizations.tr(locale, key);

    final quickActions = [
      t('summarizeClass'),
      t('generateQuiz'),
      t('attendanceInsights'),
      t('optimizeEnv'),
      t('reduceNoise'),
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
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  t('aiAssistant'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
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
                onTap: () {
                  ref.read(chatMessagesProvider.notifier)
                      .sendMessage(quickActions[index]);
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
            itemCount: messages.length + 1,
            itemBuilder: (context, index) {
              if (index == messages.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('smartSuggestions'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SuggestionCard(
                        text: t('humidityHigh'),
                        icon: Icons.water_drop_outlined,
                        onAction: () {
                          ref.read(devicesProvider.notifier).toggle('ac');
                        },
                      ),
                      SuggestionCard(
                        text: t('lightLow'),
                        icon: Icons.light_mode_outlined,
                        onAction: () {
                          ref
                              .read(devicesProvider.notifier)
                              .setBrightness('lights', 1.0);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
                );
              }
              final msg = messages[index];
              final hour = msg.timestamp.hour.toString().padLeft(2, '0');
              final minute = msg.timestamp.minute.toString().padLeft(2, '0');
              return ChatBubble(
                text: msg.text,
                isUser: msg.isUser,
                time: '$hour:$minute',
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
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: context.surfaceLight,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.textPrimary,
                          ),
                      decoration: InputDecoration(
                        hintText: t('askAnything'),
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.mic_none_rounded,
                        color: context.textSecondary, size: 22),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.subtleGlow,
                    ),
                    child: Icon(Icons.send_rounded,
                        color: context.isDark ? AppColors.background : Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
