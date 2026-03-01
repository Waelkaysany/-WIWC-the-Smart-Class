import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_colors.dart';
import '../../theme/tokens.dart';
import '../../state/providers.dart';
import '../../state/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/device_tile.dart';
import '../../widgets/category_pills.dart';
import '../../widgets/device_control_sheet.dart';
import '../../widgets/animations.dart';

class ControlsScreen extends ConsumerWidget {
  const ControlsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesProvider);
    final env = ref.watch(environmentProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final selectedScene = ref.watch(selectedSceneProvider);
    final locale = ref.watch(localeProvider);
    String t(String key) => AppLocalizations.tr(locale, key);

    final categories = [
      t('all'), t('lights'), t('door'), t('projector'),
      t('ac'), t('speaker'), t('board'), t('windows'),
    ];

    // Map localized category back to filter key
    final categoryKeys = ['All', 'Lights', 'Door', 'Projector', 'AC', 'Speaker', 'Board', 'Windows'];
    final catKeyMap = Map.fromIterables(categories, categoryKeys);

    final scenes = [t('lectureMode'), t('examMode'), t('presentationMode'), t('breakMode')];
    final sceneKeys = ['Lecture Mode', 'Exam Mode', 'Presentation Mode', 'Break Mode'];
    final sceneKeyMap = Map.fromIterables(scenes, sceneKeys);

    // Find localized selected category
    final localizedSelectedCat = categoryKeys.indexOf(selectedCat) >= 0
        ? categories[categoryKeys.indexOf(selectedCat)]
        : categories[0];

    final filterKey = catKeyMap[localizedSelectedCat] ?? 'All';
    final filteredDevices = filterKey == 'All'
        ? devices
        : devices.where((d) => d.category == filterKey).toList();

    // Find localized selected scene
    final localizedSelectedScene = selectedScene != null && sceneKeys.indexOf(selectedScene!) >= 0
        ? scenes[sceneKeys.indexOf(selectedScene!)]
        : null;

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
              child: FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  t('controls'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
          ),
        ),

        // ── Classroom Status Card ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
            child: FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: context.statusCardGradient,
                  borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                  border: Border.all(
                    color: context.isDark
                        ? context.primary.withValues(alpha: 0.15)
                        : context.cardBorder,
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.isDark
                          ? context.primary.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.meeting_room_outlined,
                            color: context.primary, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          t('classroomStatus'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatusItem(
                          icon: Icons.thermostat_outlined,
                          label: t('temp'),
                          value: '${env.temperature.toInt()}°C',
                          color: AppColors.warning,
                        ),
                        _StatusItem(
                          icon: Icons.water_drop_outlined,
                          label: t('humidity'),
                          value: '${env.humidity.toInt()}%',
                          color: const Color(0xFF4FC3F7),
                        ),
                        _StatusItem(
                          icon: Icons.light_mode_outlined,
                          label: t('light'),
                          value: '${env.lightLevel.toInt()}%',
                          color: AppColors.primary,
                        ),
                        _StatusItem(
                          icon: Icons.people_outline,
                          label: t('students'),
                          value: '${env.studentsPresent}',
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Category Pills ──
        SliverToBoxAdapter(
          child: FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: CategoryPills(
              categories: categories,
              selected: localizedSelectedCat,
              onSelected: (cat) {
                final key = catKeyMap[cat] ?? 'All';
                ref.read(selectedCategoryProvider.notifier).state = key;
              },
            ),
          ),
        ),

        // ── Device Grid ──
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.82,
            children: filteredDevices.asMap().entries.map((entry) {
              final index = entry.key;
              final device = entry.value;
              return FadeInUp(
                delay: Duration(milliseconds: 400 + (index * 50)),
                child: GestureDetector(
                  onTap: () => showDeviceControlSheet(
                    context,
                    device: device,
                    onToggle: () =>
                        ref.read(devicesProvider.notifier).toggle(device.id),
                  onBrightnessChanged: device.brightness != null
                      ? (val) => ref
                          .read(devicesProvider.notifier)
                          .setBrightness(device.id, val)
                      : null,
                  onModeChanged: device.mode != null
                      ? (mode) => ref
                          .read(devicesProvider.notifier)
                          .setMode(device.id, mode)
                      : null,
                  ),
                  child: DeviceTile(
                    icon: device.icon,
                    name: device.name,
                    subtitle: device.subtitle,
                    isOn: device.isOn,
                    brightness: device.brightness,
                    onToggle: () =>
                        ref.read(devicesProvider.notifier).toggle(device.id),
                    onBrightnessChanged: device.brightness != null
                        ? (val) => ref
                            .read(devicesProvider.notifier)
                            .setBrightness(device.id, val)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // ── Scenes ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.sm),
            child: FadeInUp(
              delay: const Duration(milliseconds: 800),
              child: Text(
                t('scenes'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FadeInUp(
            delay: const Duration(milliseconds: 900),
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                itemCount: scenes.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final scene = scenes[index];
                  final sceneKey = sceneKeys[index];
                  final isActive = sceneKey == selectedScene;
                  return GestureDetector(
                    onTap: () {
                      ref.read(selectedSceneProvider.notifier).state =
                          isActive ? null : sceneKey;
                      if (!isActive) {
                        ref.read(devicesProvider.notifier).applyScene(sceneKey);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        gradient:
                            isActive ? AppGradients.secondaryGradient : null,
                        color: isActive ? null : context.surfaceLight,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: isActive
                            ? AppShadows.glowShadow(AppColors.secondary)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          scene,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isActive
                                    ? Colors.white
                                    : context.textSecondary,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.xxxl),
        ),
      ],
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.textMuted,
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}
