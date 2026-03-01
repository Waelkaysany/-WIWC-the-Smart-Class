import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_colors.dart';
import '../../theme/tokens.dart';
import '../../state/theme_provider.dart';
import '../../state/locale_provider.dart';
import '../../state/notification_provider.dart';
import '../../l10n/app_localizations.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final locale = ref.watch(localeProvider);
    final masterEnabled = ref.watch(notificationsEnabledProvider);
    final tempEnabled = ref.watch(tempNotifyProvider);
    final humidityEnabled = ref.watch(humidityNotifyProvider);
    final lightEnabled = ref.watch(lightNotifyProvider);
    final alertHistory = ref.watch(alertHistoryProvider);
    String t(String key) => AppLocalizations.tr(locale, key);

    return Scaffold(
      backgroundColor: context.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            backgroundColor: context.background,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.cardBorder, width: 0.5),
                ),
                child: Icon(Icons.arrow_back_ios_new, size: 16, color: context.textPrimary),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              t('notifications'),
              style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),

          // ── Master Toggle ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: context.surfaceGradient,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: context.cardBorder, width: 0.5),
                  boxShadow: isDark
                      ? null
                      : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: masterEnabled
                              ? [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)]
                              : [context.surfaceLight, context.surfaceLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        masterEnabled ? Icons.notifications_active : Icons.notifications_off,
                        color: masterEnabled ? Colors.white : context.textMuted,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('pushNotifications'),
                            style: TextStyle(
                              color: context.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            masterEnabled ? t('notificationsOn') : t('notificationsOff'),
                            style: TextStyle(
                              color: masterEnabled ? AppColors.success : context.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: masterEnabled,
                      onChanged: (_) => ref.read(notificationsEnabledProvider.notifier).toggle(),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Category Section Title ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.sm),
              child: Text(
                t('alertCategories'),
                style: TextStyle(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          // ── Category Toggles ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Container(
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: context.cardBorder, width: 0.5),
                ),
                child: Column(
                  children: [
                    _CategoryTile(
                      icon: Icons.thermostat,
                      label: t('temperatureAlerts'),
                      subtitle: t('tempAlertDesc'),
                      color: AppColors.error,
                      enabled: tempEnabled && masterEnabled,
                      onToggle: masterEnabled
                          ? () => ref.read(tempNotifyProvider.notifier).toggle()
                          : null,
                      isDark: isDark,
                    ),
                    Divider(height: 0.5, thickness: 0.5, color: context.cardBorder, indent: 56),
                    _CategoryTile(
                      icon: Icons.water_drop,
                      label: t('humidityAlerts'),
                      subtitle: t('humidityAlertDesc'),
                      color: AppColors.secondary,
                      enabled: humidityEnabled && masterEnabled,
                      onToggle: masterEnabled
                          ? () => ref.read(humidityNotifyProvider.notifier).toggle()
                          : null,
                      isDark: isDark,
                    ),
                    Divider(height: 0.5, thickness: 0.5, color: context.cardBorder, indent: 56),
                    _CategoryTile(
                      icon: Icons.lightbulb_outline,
                      label: t('lightAlerts'),
                      subtitle: t('lightAlertDesc'),
                      color: AppColors.warning,
                      enabled: lightEnabled && masterEnabled,
                      onToggle: masterEnabled
                          ? () => ref.read(lightNotifyProvider.notifier).toggle()
                          : null,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Recent Alerts Title ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t('recentAlerts'),
                      style: TextStyle(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (alertHistory.isNotEmpty)
                    GestureDetector(
                      onTap: () => ref.read(alertHistoryProvider.notifier).clear(),
                      child: Text(
                        t('clearAll'),
                        style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Alert History List ──
          if (alertHistory.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none, size: 48, color: context.textMuted.withValues(alpha: 0.4)),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        t('noAlerts'),
                        style: TextStyle(color: context.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final alert = alertHistory[index];
                    return _AlertHistoryCard(alert: alert, isDark: isDark);
                  },
                  childCount: alertHistory.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl * 2)),
        ],
      ),
    );
  }
}

// ── Category Toggle Tile ──
class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool enabled;
  final VoidCallback? onToggle;
  final bool isDark;

  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.enabled,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onToggle != null ? (_) => onToggle!() : null,
            activeColor: color,
          ),
        ],
      ),
    );
  }
}

// ── Alert History Card ──
class _AlertHistoryCard extends StatelessWidget {
  final AlertItem alert;
  final bool isDark;

  const _AlertHistoryCard({required this.alert, required this.isDark});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (alert.type) {
      case 'temperature':
        icon = Icons.thermostat;
        color = AppColors.error;
        break;
      case 'humidity':
        icon = Icons.water_drop;
        color = AppColors.secondary;
        break;
      case 'light':
        icon = Icons.lightbulb_outline;
        color = AppColors.warning;
        break;
      default:
        icon = Icons.warning;
        color = AppColors.warning;
    }

    final timeAgo = DateTime.now().difference(alert.timestamp);
    String timeStr;
    if (timeAgo.inMinutes < 1) {
      timeStr = 'Just now';
    } else if (timeAgo.inMinutes < 60) {
      timeStr = '${timeAgo.inMinutes}m ago';
    } else {
      timeStr = '${timeAgo.inHours}h ago';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.body,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              timeStr,
              style: TextStyle(
                color: context.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
