import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../theme/tokens.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String time;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? null
              : LinearGradient(
                  colors: [
                    context.secondary.withValues(alpha: 0.12),
                    context.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isUser ? context.surfaceLight : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: Border.all(
            color: isUser
                ? context.cardBorder
                : context.secondary.withValues(alpha: 0.2),
            width: 0.5,
          ),
          boxShadow: isUser
              ? null
              : [
                  BoxShadow(
                    color: context.secondary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.textPrimary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              time,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.textMuted,
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
