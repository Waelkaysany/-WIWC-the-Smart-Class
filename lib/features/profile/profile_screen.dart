import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../services/firebase_service.dart';
import '../../state/class_providers.dart';
import '../../state/theme_provider.dart';
import '../../state/locale_provider.dart';
import '../../state/profile_pic_provider.dart';
import '../../l10n/app_localizations.dart';
import 'notification_screen.dart';
import 'account_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final isDark = ref.watch(isDarkModeProvider);
    final locale = ref.watch(localeProvider);
    final profilePicPath = ref.watch(profilePicProvider);
    String t(String key) => AppLocalizations.tr(locale, key);

    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Guest';
    final initials = displayName.length >= 2
        ? displayName.substring(0, 2).toUpperCase()
        : displayName.toUpperCase();

    // Theme-aware colors
    final bgCard = isDark
        ? const LinearGradient(colors: [Color(0xFF1E2A3A), Color(0xFF162030)], begin: Alignment.topLeft, end: Alignment.bottomRight)
        : const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFF7F9FC)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    final surfaceColor = isDark ? AppColors.surface : Colors.white;
    final borderColor = isDark ? AppColors.cardBorder : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimary : const Color(0xFF1A202C);
    final textSecondary = isDark ? AppColors.textSecondary : const Color(0xFF718096);
    final textMuted = isDark ? AppColors.textMuted : const Color(0xFFA0AEC0);
    final surfaceLight = isDark ? AppColors.surfaceLight : const Color(0xFFF0F4F8);

    final bg = isDark ? const Color(0xFF0F1115) : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 0.5),
                  ),
                  child: Icon(Icons.arrow_back_ios_new, size: 16, color: textPrimary),
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        automaticallyImplyLeading: false,
        title: Text(
          t('profile'),
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Profile Card ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: bgCard,
                  borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                  border: Border.all(
                    color: isDark
                        ? AppColors.secondary.withValues(alpha: 0.15)
                        : const Color(0xFFE2E8F0),
                    width: 0.5,
                  ),
                  boxShadow: isDark
                      ? null
                      : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AppGradients.secondaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppShadows.glowShadow(AppColors.secondary),
                      ),
                      child: profilePicPath != null && File(profilePicPath).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(File(profilePicPath), fit: BoxFit.cover, width: 64, height: 64),
                            )
                          : user?.photoURL != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(user!.photoURL!, fit: BoxFit.cover),
                                )
                              : Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user != null ? t('smartClassroomAdmin') : t('guestMode'),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primary,
                                ),
                          ),
                          if (user?.email != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              user!.email!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.edit_outlined,
                          color: textSecondary, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Stats Row ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                _StatBox(label: t('classes'), value: '12', color: AppColors.primary, isDark: isDark),
                const SizedBox(width: AppSpacing.md),
                _StatBox(label: t('students'), value: '384', color: AppColors.secondary, isDark: isDark),
                const SizedBox(width: AppSpacing.md),
                _StatBox(label: t('reports'), value: '47', color: AppColors.warning, isDark: isDark),
              ],
            ),
          ),
        ),

        // ── Settings List ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.sm),
            child: Text(
              t('settings'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: borderColor, width: 0.5),
                boxShadow: isDark
                    ? null
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  _SettingsItem(
                    icon: Icons.person_outline,
                    label: t('account'),
                    isDark: isDark,
                    trailing: Icon(Icons.chevron_right, color: textMuted, size: 20),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AccountScreen()),
                    ),
                  ),
                  _divider(borderColor),

                  // Classroom Devices
                  _SettingsItem(
                    icon: Icons.devices_other,
                    label: t('classroomDevices'),
                    isDark: isDark,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '8 ${t('devices')}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  _divider(borderColor),
                  // Notifications
                  _SettingsItem(
                    icon: Icons.notifications_none,
                    label: t('notifications'),
                    isDark: isDark,
                    trailing: Icon(Icons.chevron_right, color: textMuted, size: 20),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationScreen()),
                    ),
                  ),
                  _divider(borderColor),
                  // Privacy & Security
                  _SettingsItem(
                    icon: Icons.shield_outlined,
                    label: t('privacySecurity'),
                    isDark: isDark,
                    trailing: Icon(Icons.chevron_right, color: textMuted, size: 20),
                  ),
                  _divider(borderColor),
                  // Appearance
                  _SettingsItem(
                    icon: Icons.palette_outlined,
                    label: t('appearance'),
                    isDark: isDark,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isDark ? t('dark') : t('light'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: textSecondary,
                            ),
                      ),
                    ),
                    onTap: () => _showAppearanceSheet(context, ref, isDark, t),
                  ),
                  _divider(borderColor),
                  // Language
                  _SettingsItem(
                    icon: Icons.language,
                    label: t('language'),
                    isDark: isDark,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        locale == 'en' ? t('english') : t('french'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: textSecondary,
                            ),
                      ),
                    ),
                    onTap: () => _showLanguageSheet(context, ref, locale, t),
                  ),
                  _divider(borderColor),
                  // Help & Support
                  _SettingsItem(
                    icon: Icons.help_outline,
                    label: t('helpSupport'),
                    isDark: isDark,
                    trailing: Icon(Icons.chevron_right, color: textMuted, size: 20),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Logout Button ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
            child: GestureDetector(
              onTap: () => _showLogoutDialog(context, ref, t),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: _SettingsItem(
                  icon: Icons.logout,
                  label: t('logout'),
                  iconColor: AppColors.error,
                  labelColor: AppColors.error,
                  isDark: isDark,
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.error, size: 20),
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.xxxl),
        ),
      ],
    ),
    );
  }

  // ── Appearance Bottom Sheet ──
  void _showAppearanceSheet(BuildContext context, WidgetRef ref, bool isDark, String Function(String) t) {
    final sheetBg = isDark ? AppColors.surface : Colors.white;
    final borderCol = isDark ? AppColors.cardBorder : const Color(0xFFE2E8F0);
    final textPri = isDark ? AppColors.textPrimary : const Color(0xFF1A202C);
    final textSec = isDark ? AppColors.textSecondary : const Color(0xFF718096);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: borderCol, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: textSec.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(t('chooseTheme'), style: TextStyle(color: textPri, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: _ThemeOption(
                    icon: Icons.dark_mode_rounded,
                    label: t('dark'),
                    isSelected: isDark,
                    gradient: const [Color(0xFF1A1F2B), Color(0xFF0F1115)],
                    onTap: () {
                      ref.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _ThemeOption(
                    icon: Icons.light_mode_rounded,
                    label: t('light'),
                    isSelected: !isDark,
                    gradient: const [Color(0xFFF5F7FA), Color(0xFFE2E8F0)],
                    iconColor: const Color(0xFFD69E2E),
                    onTap: () {
                      ref.read(themeModeProvider.notifier).setTheme(ThemeMode.light);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Language Bottom Sheet ──
  void _showLanguageSheet(BuildContext context, WidgetRef ref, String locale, String Function(String) t) {
    final isDark = ref.read(isDarkModeProvider);
    final sheetBg = isDark ? AppColors.surface : Colors.white;
    final borderCol = isDark ? AppColors.cardBorder : const Color(0xFFE2E8F0);
    final textPri = isDark ? AppColors.textPrimary : const Color(0xFF1A202C);
    final textSec = isDark ? AppColors.textSecondary : const Color(0xFF718096);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: borderCol, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: textSec.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(t('chooseLanguage'), style: TextStyle(color: textPri, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xxl),
            _LanguageOption(
              flag: '🇺🇸',
              label: 'English',
              isSelected: locale == 'en',
              isDark: isDark,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale('en');
                Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _LanguageOption(
              flag: '🇫🇷',
              label: 'Français',
              isSelected: locale == 'fr',
              isDark: isDark,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale('fr');
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref, String Function(String) t) {
    final isDark = ref.read(isDarkModeProvider);
    final surfaceColor = isDark ? AppColors.surface : Colors.white;
    final borderColor = isDark ? AppColors.cardBorder : const Color(0xFFE2E8F0);
    final textPri = isDark ? AppColors.textPrimary : const Color(0xFF1A202C);
    final textSec = isDark ? AppColors.textSecondary : const Color(0xFF718096);
    final textMuted = isDark ? AppColors.textMuted : const Color(0xFFA0AEC0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: borderColor, width: 0.5),
        ),
        title: Text(t('logout'), style: TextStyle(color: textPri)),
        content: Text(
          t('logoutConfirm'),
          style: TextStyle(color: textSec),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t('cancel'), style: TextStyle(color: textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // signOut() now handles class session cleanup internally.
              // AuthWrapper will reactively navigate to LoginScreen.
              await ref.read(authServiceProvider).signOut();
            },
            child: Text(t('logout'), style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  static Widget _divider(Color color) {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      color: color,
      indent: 56,
    );
  }
}

// ── Theme Option Card ──
class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final List<Color> gradient;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.gradient,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, spreadRadius: 0)]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: iconColor ?? Colors.white),
            const SizedBox(height: AppSpacing.md),
            Text(
              label,
              style: TextStyle(
                color: gradient[0].computeLuminance() > 0.5 ? const Color(0xFF1A202C) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Language Option ──
class _LanguageOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.surfaceLight : const Color(0xFFF0F4F8);
    final textPrimary = isDark ? AppColors.textPrimary : const Color(0xFF1A202C);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 12)]
              : null,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: AppSpacing.lg),
            Text(label, style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
            const Spacer(),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Box ──
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.surface : Colors.white;
    final borderColor = isDark ? AppColors.cardBorder : const Color(0xFFE2E8F0);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: borderColor, width: 0.5),
          boxShadow: isDark
              ? null
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings Item ──
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final Color? iconColor;
  final Color? labelColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.isDark,
    this.trailing,
    this.iconColor,
    this.labelColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : const Color(0xFF1A202C);
    final textSecondary = isDark ? AppColors.textSecondary : const Color(0xFF718096);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? textSecondary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: iconColor ?? textSecondary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: labelColor ?? textPrimary,
                    ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
