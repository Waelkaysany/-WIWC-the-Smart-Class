import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../theme/tokens.dart';

class MiniMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? delta;
  final bool isPositive;
  final IconData? icon;
  final Color? accentColor;

  const MiniMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.isPositive = true,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: context.surfaceGradient,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: context.cardBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: accentColor ?? context.primary),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: accentColor ?? context.textPrimary,
                      ),
                ),
                if (delta != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12,
                    color: isPositive ? context.success : context.error,
                  ),
                  Text(
                    delta!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isPositive ? context.success : context.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
