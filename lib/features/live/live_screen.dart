import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_colors.dart';
import '../../theme/tokens.dart';
import '../../state/providers.dart';
import '../../state/locale_provider.dart';
import '../../state/profile_pic_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/insight_card.dart';
import '../../widgets/gauge.dart';
import '../../models/environment_data.dart';
import '../../services/firebase_service.dart';
import '../profile/notification_screen.dart';

class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(classroomStatsProvider);
    final env = ref.watch(environmentProvider);
    final locale = ref.watch(localeProvider);
    String t(String key) => AppLocalizations.tr(locale, key);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Top Bar ──
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _PulseDot(color: context.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'WIWC',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationScreen()),
                        ),
                        child: _IconBtn(icon: Icons.notifications_none_rounded),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _ProfileAvatar(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Section: Live Dashboard + Wellness ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t('liveDashboard'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: context.textSecondary,
                      ),
                ),
                _WellnessScore(score: _calculateWellness(env)),
              ],
            ),
          ),
        ),

        // ── Status Banner ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
            child: _StatusBanner(env: env),
          ),
        ),

        // ── Students Present (Full-width gauge) ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _GlassCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.people_alt_rounded, color: context.primary, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        t('studentsPresent'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.textSecondary,
                            ),
                      ),
                      const Spacer(),
                      _LiveBadge(),
                    ],
                  ),
                  GaugeWidget(
                    value: stats.studentsPresent,
                    maxValue: 35,
                    label: t('studentsPresent'),
                    sublabel: '♂ ${stats.maleStudents}  ♀ ${stats.femaleStudents}',
                    height: 170,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        // ── Live Captures — Sensor Data ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.sensors_rounded, color: context.primary, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  t('liveCaptures'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          sliver: SliverGrid.count(
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.72,
            children: [
              _SensorCard(
                icon: Icons.thermostat_rounded,
                label: t('temperature'),
                value: env.temperature,
                unit: '°C',
                max: 40,
                color: AppColors.warning,
                trend: '▲ 0.5°',
                onTap: () => _showSensorDetails(context, t('temperature'), env.temperature, '°C', AppColors.warning),
              ),
              _SensorCard(
                icon: Icons.water_drop_rounded,
                label: t('humidity'),
                value: env.humidity,
                unit: '%',
                max: 100,
                color: const Color(0xFF4FC3F7),
                trend: '▼ 2%',
                onTap: () => _showSensorDetails(context, t('humidity'), env.humidity, '%', const Color(0xFF4FC3F7)),
              ),
              _SensorCard(
                icon: Icons.air_rounded,
                label: 'Air Quality',
                value: env.airQuality,
                unit: '%',
                max: 100,
                color: const Color(0xFF2BC89B),
                trend: 'Excellent',
                onTap: () => _showSensorDetails(context, 'Air Quality', env.airQuality, '%', const Color(0xFF2BC89B)),
              ),
            ],
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        // ── Room / Devices row ──
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.25,
            children: [
              InsightCard(
                title: t('roomLabel'),
                value: '${stats.devicesOnlinePercent.toInt()}%',
                subtitle: t('devicesOnline'),
                icon: Icons.sensors_rounded,
                accentColor: AppColors.primary,
                padding: const EdgeInsets.all(AppSpacing.lg),
              ),
              InsightCard(
                title: t('activeNow'),
                value: '${stats.activeNowMin}–${stats.activeNowMax}',
                subtitle: t('studentsActive'),
                icon: Icons.groups_rounded,
                accentColor: AppColors.secondary,
                padding: const EdgeInsets.all(AppSpacing.lg),
              ),
            ],
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        // ── Activity Graph ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.insights_rounded, color: context.secondary, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            t('activityTimeline'),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: context.textSecondary,
                                ),
                          ),
                        ],
                      ),
                      Text(
                        '${t('peak')}: ${stats.peakActivity}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 60,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineTouchData: const LineTouchData(enabled: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: stats.activityGraph
                                .asMap()
                                .entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value))
                                .toList(),
                            isCurved: true,
                            color: context.primary,
                            barWidth: 2.5,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  context.primary.withAlpha(51),
                                  context.primary.withAlpha(0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

        // ── Quick Stats Row (scrollable, NO Expanded) ──
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                _MiniMetric(
                  label: t('focusRate'),
                  value: '${stats.focusRate.toInt()}%',
                  delta: '2.1%',
                  isPositive: true,
                  icon: Icons.center_focus_strong_outlined,
                  accentColor: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                _MiniMetric(
                  label: t('participation'),
                  value: '${stats.participation.toInt()}%',
                  delta: '1.5%',
                  isPositive: true,
                  icon: Icons.trending_up,
                  accentColor: AppColors.secondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                _MiniMetric(
                  label: t('noise'),
                  value: stats.noiseIndex,
                  icon: Icons.volume_down_outlined,
                  accentColor: stats.noiseIndex == 'Low'
                      ? AppColors.primary
                      : AppColors.warning,
                ),
              ],
            ),
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
      ],
    );
  }

  double _calculateWellness(EnvironmentData env) {
    double tempScore = (1.0 - ((env.temperature - 22).abs() / 10)).clamp(0.0, 1.0) * 100;
    double humidityScore = (1.0 - ((env.humidity - 50).abs() / 50)).clamp(0.0, 1.0) * 100;
    double lightScore = (env.lightLevel / 100).clamp(0.0, 1.0) * 100;
    double aqiScore = env.airQuality;

    return (tempScore * 0.3 + humidityScore * 0.2 + lightScore * 0.1 + aqiScore * 0.4);
  }

  void _showSensorDetails(BuildContext context, String title, double value, String unit, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _SensorDetailSheet(title: title, value: value, unit: unit, color: color),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  Extracted Subwidgets (all null-safe, no Expanded in scrollables)
// ══════════════════════════════════════════════════════════════════

/// Pulsing dot indicator
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: AppShadows.glowShadow(widget.color),
          ),
        ),
      ),
    );
  }
}

/// Simple icon button with surface background
class _IconBtn extends StatelessWidget {
  final IconData icon;
  const _IconBtn({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: context.textSecondary, size: 20),
    );
  }
}

/// Profile avatar that syncs with profilePicProvider
class _ProfileAvatar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilePicPath = ref.watch(profilePicProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'T';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T';

    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.secondaryGradient,
      ),
      child: profilePicPath != null && File(profilePicPath).existsSync()
          ? ClipOval(
              child: Image.file(
                File(profilePicPath),
                fit: BoxFit.cover,
                width: 36,
                height: 36,
              ),
            )
          : user?.photoURL != null
              ? ClipOval(
                  child: Image.network(
                    user!.photoURL!,
                    fit: BoxFit.cover,
                    width: 36,
                    height: 36,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(initial, style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14,
                      )),
                    ),
                  ),
                )
              : Center(
                  child: Text(initial, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14,
                  )),
                ),
    );
  }
}

/// Wellness score badge
class _WellnessScore extends StatelessWidget {
  final double score;
  const _WellnessScore({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.primary.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.primary.withAlpha(51)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 3,
              backgroundColor: context.surfaceLight,
              color: context.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Wellness: ${score.toInt()}%',
            style: TextStyle(
              color: context.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// LIVE badge with subtle pulse
class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Transform.scale(
        scale: _scale.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: context.primary.withAlpha(31),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'LIVE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
          ),
        ),
      ),
    );
  }
}

/// Reusable glass card
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
      decoration: BoxDecoration(
        gradient: context.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.cardBorder, width: 0.5),
        boxShadow: context.isDark
            ? AppShadows.cardShadow
            : [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

/// Status banner
class _StatusBanner extends StatelessWidget {
  final EnvironmentData env;
  const _StatusBanner({required this.env});

  @override
  Widget build(BuildContext context) {
    String message = 'System operating nominally.';
    IconData icon = Icons.check_circle_outline_rounded;
    Color color = context.primary;

    if (env.temperature > 30) {
      message = 'High temperature detected. Recommend cooling.';
      icon = Icons.warning_amber_rounded;
      color = AppColors.warning;
    } else if (env.airQuality < 70) {
      message = 'Air quality is declining. Consider ventilation.';
      icon = Icons.air_rounded;
      color = AppColors.secondary;
    } else if (env.lightLevel < 30) {
      message = 'Low light levels. Smart lighting adjusted.';
      icon = Icons.lightbulb_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(26)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini metric card — fixed width (NOT Expanded) for horizontal scroll
class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final String? delta;
  final bool isPositive;
  final IconData? icon;
  final Color? accentColor;

  const _MiniMetric({
    required this.label,
    required this.value,
    this.delta,
    this.isPositive = true,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? context.primary;
    return Container(
      width: 140,
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
                Icon(icon, size: 14, color: accent),
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
                      color: accent,
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
    );
  }
}

/// Sensor detail bottom sheet
class _SensorDetailSheet extends StatelessWidget {
  final String title;
  final double value;
  final String unit;
  final Color color;

  const _SensorDetailSheet({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${value.toInt()}',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: color),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                child: Text(unit, style: const TextStyle(fontSize: 20, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text('24h Trend', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3), FlSpot(2, 4), FlSpot(4, 3.5), FlSpot(6, 5),
                      FlSpot(8, 4.5), FlSpot(10, 6), FlSpot(12, 5.5),
                    ],
                    isCurved: true,
                    color: color,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withAlpha(26),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

/// Sensor Card Widget — circular progress with animated fill
class _SensorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final String unit;
  final double max;
  final Color color;
  final String trend;
  final VoidCallback? onTap;

  const _SensorCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.max,
    required this.color,
    required this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withAlpha(20),
              context.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: color.withAlpha(51),
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(38),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                Text(
                  trend,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.sm),
  
            Expanded(
               child: Stack(
                 alignment: Alignment.center,
                 children: [
                   SizedBox(
                     width: 60,
                     height: 60,
                     child: CircularProgressIndicator(
                       value: 1.0,
                       strokeWidth: 4,
                       color: context.surfaceLight,
                       strokeCap: StrokeCap.round,
                     ),
                   ),
                   SizedBox(
                     width: 60,
                     height: 60,
                     child: TweenAnimationBuilder<double>(
                       tween: Tween<double>(begin: 0, end: value / max),
                       duration: const Duration(seconds: 2),
                       curve: Curves.easeOutCubic,
                       builder: (context, val, _) {
                         return CircularProgressIndicator(
                           value: val,
                           strokeWidth: 4,
                           color: color,
                           strokeCap: StrokeCap.round,
                         );
                       },
                     ),
                   ),
                   Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Text(
                         '${value.toInt()}',
                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
                               fontWeight: FontWeight.bold,
                               color: context.textPrimary,
                               fontSize: 18,
                             ),
                       ),
                       Text(
                         unit,
                         style: Theme.of(context).textTheme.labelSmall?.copyWith(
                               color: context.textMuted,
                               fontSize: 10,
                             ),
                       ),
                     ],
                   ),
                 ],
               ),
            ),
            
            const SizedBox(height: AppSpacing.sm),
  
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
