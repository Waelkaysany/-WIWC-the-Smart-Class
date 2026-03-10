import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/glass_container.dart';
import 'superadmin_shell.dart';

class SuperAdminLoginScreen extends StatefulWidget {
  const SuperAdminLoginScreen({super.key});

  @override
  State<SuperAdminLoginScreen> createState() => _SuperAdminLoginScreenState();
}

class _SuperAdminLoginScreenState extends State<SuperAdminLoginScreen>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  late AnimationController _bgCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _superUsername = 'Kyotaka';
  static const _superPassword = 'Kyotaka123';

  // Gold/amber accent for SuperAdmin
  static const _gold = Color(0xFFF59E0B);
  static const _goldLight = Color(0xFFFCD34D);
  static const _goldDark = Color(0xFFB45309);

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _bgCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_usernameController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    // Simulate authentication delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Accept both 'Kyotaka' and 'Kyotaka@gmail.com' as username
    final inputUser = _usernameController.text.trim();
    final inputPass = _passwordController.text.trim();
    final usernameMatch = inputUser == _superUsername ||
        inputUser.toLowerCase() == _superUsername.toLowerCase() ||
        inputUser.toLowerCase() == '${_superUsername.toLowerCase()}@gmail.com';

    if (usernameMatch && inputPass == _superPassword) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SuperAdminShell()),
        );
      }
    } else {
      setState(() => _error = 'Invalid credentials. Access denied.');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      body: Stack(
        children: [
          _SuperAdminBackground(controller: _bgCtrl),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      _buildBranding(),
                      const SizedBox(height: 48),
                      _buildLoginCard(),
                      const SizedBox(height: 24),
                      _buildBackButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_gold, _goldDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.35),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.shield_rounded, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_goldLight, _gold, _goldDark],
          ).createShader(bounds),
          child: const Text(
            'SuperAdmin',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'WIWC COMMAND CENTER • RESTRICTED ACCESS',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return GlassContainer(
      blur: 20,
      opacity: 0.06,
      padding: const EdgeInsets.all(28),
      borderRadius: 28,
      border: Border.all(color: _gold.withValues(alpha: 0.1), width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Access Command Center',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your SuperAdmin credentials',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
          ),
          const SizedBox(height: 28),

          _buildField(
            controller: _usernameController,
            hint: 'Username',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _passwordController,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gold, _goldDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Access Command Center',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, size: 12, color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(width: 6),
                Text(
                  'Encrypted • WIWC Enterprise',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 14),
          prefixIcon: Icon(icon, color: _gold.withValues(alpha: 0.5), size: 20),
          suffixIcon: isPassword
              ? GestureDetector(
                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white.withValues(alpha: 0.25),
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return TextButton.icon(
      onPressed: () => Navigator.of(context).pop(),
      icon: Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white.withValues(alpha: 0.4)),
      label: Text(
        'Back to Teacher Login',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
      ),
    );
  }
}

class _SuperAdminBackground extends StatelessWidget {
  final AnimationController controller;
  const _SuperAdminBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _GoldMeshPainter(controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _GoldMeshPainter extends CustomPainter {
  final double progress;
  _GoldMeshPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * math.pi;

    // Gold blob top-right
    _drawBlob(canvas,
      Offset(size.width * 0.8 + 40 * math.sin(t), size.height * 0.15 + 60 * math.cos(t)),
      size.width * 0.7,
      const Color(0xFFF59E0B).withValues(alpha: 0.12),
    );

    // Purple blob bottom-left
    _drawBlob(canvas,
      Offset(size.width * 0.15 + 50 * math.cos(t), size.height * 0.85 + 30 * math.sin(t)),
      size.width * 0.9,
      const Color(0xFF8B5CF6).withValues(alpha: 0.08),
    );

    // Gold accent center-right
    _drawBlob(canvas,
      Offset(size.width * 0.7 + 30 * math.sin(t + 1.5), size.height * 0.5 + 60 * math.cos(t + 1.5)),
      size.width * 0.5,
      const Color(0xFFD97706).withValues(alpha: 0.06),
    );
  }

  void _drawBlob(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
