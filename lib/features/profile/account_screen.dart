import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_colors.dart';
import '../../theme/tokens.dart';
import '../../services/firebase_service.dart';
import '../../state/locale_provider.dart';
import '../../state/profile_pic_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../state/theme_provider.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isNameSaving = false;
  bool _isPasswordSaving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _nameMessage;
  String? _passwordMessage;
  bool? _nameSuccess;
  bool? _passwordSuccess;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(
      text: user?.displayName ?? user?.email?.split('@').first ?? '',
    );
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked != null) {
      final file = File(picked.path);
      await ref.read(profilePicProvider.notifier).saveProfilePic(file);
    }
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() {
      _isNameSaving = true;
      _nameMessage = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(_nameController.text.trim());
        await user.reload();
        final db = ref.read(databaseServiceProvider);
        await db.updateUserProfile(user.uid, {'name': _nameController.text.trim()});
      }
      final locale = ref.read(localeProvider);
      setState(() {
        _nameSuccess = true;
        _nameMessage = AppLocalizations.tr(locale, 'nameUpdated');
      });
    } catch (e) {
      setState(() {
        _nameSuccess = false;
        _nameMessage = e.toString();
      });
    } finally {
      setState(() => _isNameSaving = false);
    }
  }

  Future<void> _updatePassword() async {
    final locale = ref.read(localeProvider);
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _passwordSuccess = false;
        _passwordMessage = AppLocalizations.tr(locale, 'fillAllFields');
      });
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _passwordSuccess = false;
        _passwordMessage = AppLocalizations.tr(locale, 'passwordMismatch');
      });
      return;
    }

    setState(() {
      _isPasswordSaving = true;
      _passwordMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_newPasswordController.text);
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() {
          _passwordSuccess = true;
          _passwordMessage = AppLocalizations.tr(locale, 'passwordUpdated');
        });
      }
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
        msg = 'Current password is incorrect';
      } else if (msg.contains('weak-password')) {
        msg = 'New password must be at least 6 characters';
      }
      setState(() {
        _passwordSuccess = false;
        _passwordMessage = msg;
      });
    } finally {
      setState(() => _isPasswordSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final user = FirebaseAuth.instance.currentUser;
    final profilePicPath = ref.watch(profilePicProvider);
    String t(String key) => AppLocalizations.tr(locale, key);

    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Guest';
    final initials = displayName.length >= 2
        ? displayName.substring(0, 2).toUpperCase()
        : displayName.toUpperCase();

    return Scaffold(
      backgroundColor: context.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
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
                t('accountTitle'),
                style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),

            // ── Profile Picture Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxl),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: AppGradients.secondaryGradient,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: profilePicPath != null && File(profilePicPath).existsSync()
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(32),
                                    child: Image.file(File(profilePicPath), fit: BoxFit.cover, width: 100, height: 100),
                                  )
                                : user?.photoURL != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(32),
                                        child: Image.network(user!.photoURL!, fit: BoxFit.cover),
                                      )
                                    : Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 32,
                                          ),
                                        ),
                                      ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppGradients.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: AppShadows.glowShadow(AppColors.primary),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(t('profilePicture'),
                        style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(t('tapToChange'), style: TextStyle(color: context.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ),

            // ── Personal Info Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('personalInfo'),
                        style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: context.cardBorder, width: 0.5),
                        boxShadow: context.isDark
                            ? null
                            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email (read-only)
                          Text(t('email'), style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: context.surfaceLight,
                              borderRadius: BorderRadius.circular(AppRadius.button),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.email_outlined, size: 18, color: context.textSecondary),
                                const SizedBox(width: 10),
                                Text(
                                  user?.email ?? 'guest@wiwc.com',
                                  style: TextStyle(color: context.textSecondary, fontSize: 14),
                                ),
                                const Spacer(),
                                Icon(Icons.lock_outline, size: 14, color: context.textSecondary),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Display Name
                          Text(t('displayName'), style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _nameController,
                            style: TextStyle(color: context.textPrimary),
                            decoration: InputDecoration(
                              hintText: t('enterName'),
                              hintStyle: TextStyle(color: context.textSecondary),
                              prefixIcon: Icon(Icons.person_outline, color: context.textSecondary, size: 20),
                              filled: true,
                              fillColor: context.surfaceLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.button),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.button),
                                borderSide: BorderSide(color: context.primary, width: 1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                          if (_nameMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _nameMessage!,
                              style: TextStyle(
                                color: _nameSuccess == true ? context.success : context.error,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppGradients.primaryGradient,
                                borderRadius: BorderRadius.circular(AppRadius.button),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isNameSaving ? null : _saveName,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.button),
                                  ),
                                ),
                                child: _isNameSaving
                                    ? const SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        t('save'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Password Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xxxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('security'),
                        style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: context.cardBorder, width: 0.5),
                        boxShadow: context.isDark
                            ? null
                            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: context.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.lock_rounded, color: context.warning, size: 20),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(t('changePassword'),
                                  style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _PasswordField(
                            controller: _currentPasswordController,
                            hint: t('currentPassword'),
                            obscure: _obscureCurrent,
                            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _PasswordField(
                            controller: _newPasswordController,
                            hint: t('newPassword'),
                            obscure: _obscureNew,
                            onToggle: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _PasswordField(
                            controller: _confirmPasswordController,
                            hint: t('confirmPassword'),
                            obscure: _obscureConfirm,
                            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                          if (_passwordMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _passwordMessage!,
                              style: TextStyle(
                                color: _passwordSuccess == true ? context.success : context.error,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.warning, Color(0xFFFF9E43)],
                                ),
                                borderRadius: BorderRadius.circular(AppRadius.button),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.warning.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isPasswordSaving ? null : _updatePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.button),
                                  ),
                                ),
                                child: _isPasswordSaving
                                    ? const SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        t('updatePassword'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: context.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.textSecondary),
        prefixIcon: Icon(Icons.lock_outline, color: context.textSecondary, size: 20),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: context.textSecondary,
            size: 20,
          ),
        ),
        filled: true,
        fillColor: context.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: context.primary, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
