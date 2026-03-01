import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../theme/tokens.dart';

class DeviceTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final String subtitle;
  final bool isOn;
  final double? brightness;
  final VoidCallback onToggle;
  final ValueChanged<double>? onBrightnessChanged;

  const DeviceTile({
    super.key,
    required this.icon,
    required this.name,
    required this.subtitle,
    required this.isOn,
    required this.onToggle,
    this.brightness,
    this.onBrightnessChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: isOn
            ? LinearGradient(
                colors: [
                  context.primary.withValues(alpha: 0.15),
                  context.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : context.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isOn ? context.primary.withValues(alpha: 0.5) : context.cardBorder,
          width: isOn ? 1.5 : 0.5,
        ),
        boxShadow: isOn ? AppShadows.subtleGlow : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isOn
                      ? context.primary
                      : context.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isOn
                      ? [
                          BoxShadow(
                            color: context.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: isOn ? 1.1 : 1.0),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Icon(
                        icon,
                        color: isOn ? Colors.white : context.textMuted,
                        size: 22,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 28,
                child: Switch(
                  value: isOn,
                  onChanged: (_) => onToggle(),
                  activeColor: context.primary,
                  activeTrackColor: context.primary.withValues(alpha: 0.3),
                  inactiveThumbColor: context.textMuted,
                  inactiveTrackColor: context.surfaceLight,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isOn ? context.textPrimary : context.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textMuted,
                ),
          ),
          if (brightness != null && isOn) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.brightness_low, size: 14, color: context.textMuted),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: context.primary,
                      inactiveTrackColor: context.surfaceLight,
                      thumbColor: context.primary,
                      overlayColor: context.primary.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: brightness!,
                      onChanged: onBrightnessChanged,
                    ),
                  ),
                ),
                Icon(Icons.brightness_high, size: 14, color: context.primary),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
