import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../state/providers.dart';
import '../../state/theme_provider.dart';
import '../../state/locale_provider.dart';
import '../../state/class_providers.dart';
import '../../l10n/app_localizations.dart';
import '../live/live_screen.dart';
import '../controls/controls_screen.dart';
import '../assistant/assistant_screen.dart';
import '../profile/profile_screen.dart';
import 'class_selection_screen.dart';

/// Wraps existing tabs (Live, Controls, AI, Profile) inside a class context.
/// Shows class name in a top bar with "Leave Class" action.
class ClassDashboardShell extends ConsumerWidget {
  final String classId;
  final String className;

  const ClassDashboardShell({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(selectedTabProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final locale = ref.watch(localeProvider);
    String t(String key) => AppLocalizations.tr(locale, key);

    final navBg = isDark ? AppColors.surface : AppColorsLight.surface;
    final navBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final navActive = isDark ? AppColors.primary : AppColorsLight.primary;
    final navInactive = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppGradients.backgroundGradient
              : const LinearGradient(
                  colors: [Color(0xFFF5F7FA), Color(0xFFEDF2F7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: IndexedStack(
          index: currentTab,
          children: const [
            LiveScreen(),
            ControlsScreen(),
            AssistantScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: navBorder, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.show_chart_rounded,
                  label: t('live'),
                  isActive: currentTab == 0,
                  activeColor: navActive,
                  inactiveColor: navInactive,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 0,
                ),
                _NavItem(
                  icon: Icons.tune_rounded,
                  label: t('controls'),
                  isActive: currentTab == 1,
                  activeColor: navActive,
                  inactiveColor: navInactive,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
                ),
                // Center FAB — Leave class
                _LeaveClassButton(
                  classId: classId,
                  className: className,
                ),
                _NavItem(
                  icon: Icons.auto_awesome,
                  label: t('ai'),
                  isActive: currentTab == 2,
                  activeColor: navActive,
                  inactiveColor: navInactive,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  label: t('profile'),
                  isActive: currentTab == 3,
                  activeColor: navActive,
                  inactiveColor: navInactive,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Leave Class Center Button ──
class _LeaveClassButton extends ConsumerWidget {
  final String classId;
  final String className;

  const _LeaveClassButton({required this.classId, required this.className});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showLeaveDialog(context, ref),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF2BC89B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(80),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.meeting_room_outlined, color: Colors.white, size: 26),
      ),
    );
  }

  void _showLeaveDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1F2B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.meeting_room_outlined, color: AppColors.warning, size: 24),
            const SizedBox(width: 8),
            const Expanded(child: Text('Leave Class')),
          ],
        ),
        content: Text(
          'Leave "$className" and make it available to other teachers?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Leave class
              await ref.read(classSessionServiceProvider).leaveClass();
              ref.read(activeClassIdProvider.notifier).state = null;
              ref.read(selectedTabProvider.notifier).state = 0;
            },
            child: const Text('Leave', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Nav Item (same as AppShell) ──
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 22,
              shadows: isActive
                  ? [Shadow(color: activeColor.withValues(alpha: 0.5), blurRadius: 12)]
                  : null,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
