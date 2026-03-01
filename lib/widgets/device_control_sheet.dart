import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';
import '../theme/tokens.dart';
import '../models/device.dart';

class DeviceControlSheet extends StatelessWidget {
  final Device device;
  final VoidCallback onToggle;
  final ValueChanged<double>? onBrightnessChanged;
  final ValueChanged<String>? onModeChanged;

  const DeviceControlSheet({
    super.key,
    required this.device,
    required this.onToggle,
    this.onBrightnessChanged,
    this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                // ── Header ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: device.isOn
                            ? context.primary.withValues(alpha: 0.15)
                            : context.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        device.icon,
                        color: device.isOn ? context.primary : context.textMuted,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            device.subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: context.textMuted,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 1.2,
                      child: Switch(
                        value: device.isOn,
                        onChanged: (_) => onToggle(),
                        activeColor: context.primary,
                        activeTrackColor: context.primary.withValues(alpha: 0.3),
                        inactiveThumbColor: context.textMuted,
                        inactiveTrackColor: context.surfaceLight,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ── Status Indicator ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: device.isOn
                        ? context.primary.withValues(alpha: 0.08)
                        : context.surfaceLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(
                      color: device.isOn
                          ? context.primary.withValues(alpha: 0.2)
                          : context.cardBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: device.isOn ? context.primary : context.textMuted,
                          shape: BoxShape.circle,
                          boxShadow: device.isOn
                              ? AppShadows.glowShadow(context.primary)
                              : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        device.isOn ? 'Device is ON' : 'Device is OFF',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: device.isOn ? context.primary : context.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),

                // ── Brightness Slider (Lights) ──
                if (device.brightness != null && device.isOn) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    children: [
                      Icon(Icons.brightness_low, color: context.textMuted, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Brightness',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '${(device.brightness! * 100).toInt()}%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: context.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                      activeTrackColor: context.primary,
                      inactiveTrackColor: context.surfaceLight,
                      thumbColor: context.primary,
                      overlayColor: context.primary.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: device.brightness!,
                      onChanged: onBrightnessChanged,
                    ),
                  ),
                ],

                // ── Mode Selector (AC) ──
                if (device.mode != null && device.isOn) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    children: [
                      Icon(Icons.air, color: context.textMuted, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Mode',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: ['Cool', 'Auto', 'Heat'].map((mode) {
                      final isActive = device.mode == mode;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onModeChanged?.call(mode),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            decoration: BoxDecoration(
                              gradient: isActive ? AppGradients.primaryGradient : null,
                              color: isActive ? null : context.surfaceLight,
                              borderRadius: BorderRadius.circular(AppRadius.button),
                              boxShadow: isActive ? AppShadows.subtleGlow : null,
                            ),
                            child: Center(
                              child: Text(
                                mode,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: isActive
                                          ? (context.isDark ? AppColors.background : Colors.white)
                                          : context.textSecondary,
                                      fontWeight: isActive
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // ── Door Lock Status ──
                if (device.id == 'door') ...[
                  const SizedBox(height: AppSpacing.xxl),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: device.isOn
                          ? context.primary.withValues(alpha: 0.08)
                          : context.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(
                        color: device.isOn
                            ? context.primary.withValues(alpha: 0.2)
                            : context.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          device.isOn ? Icons.lock : Icons.lock_open,
                          color: device.isOn ? context.primary : context.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          device.isOn ? 'Door is Locked' : 'Door is Unlocked',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: device.isOn ? context.primary : context.error,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void showDeviceControlSheet(
  BuildContext context, {
  required Device device,
  required VoidCallback onToggle,
  ValueChanged<double>? onBrightnessChanged,
  ValueChanged<String>? onModeChanged,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DeviceControlSheet(
      device: device,
      onToggle: () {
        onToggle();
        Navigator.of(context).pop();
      },
      onBrightnessChanged: onBrightnessChanged,
      onModeChanged: onModeChanged,
    ),
  );
}
