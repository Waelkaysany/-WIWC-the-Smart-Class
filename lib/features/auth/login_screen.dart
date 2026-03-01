import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../app.dart';
import '../../widgets/glass_container.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSignUp = false;
  String _selectedRole = 'teacher'; // Always teacher as per requirement
  String? _error;

  late AnimationController _bgAnimationController;
  late AnimationController _contentFadeController;
  late Animation<double> _contentFadeAnimation;

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _contentFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _contentFadeAnimation = CurvedAnimation(
      parent: _contentFadeController,
      curve: Curves.easeOut,
    );

    _contentFadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _bgAnimationController.dispose();
    _contentFadeController.dispose();
    super.dispose();
  }




  Future<void> _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      if (_isSignUp) {
        await auth.signUp(
          _emailController.text.trim(), 
          _passwordController.text,
          role: _selectedRole,
        );
      } else {
        await auth.signIn(_emailController.text.trim(), _passwordController.text);
      }

      // AuthWrapper will handle navigation automatically
    } catch (e) {
      final errStr = e.toString();
      String msg = 'An error occurred';
      if (errStr.contains('user-not-found')) {
        msg = 'No account found. Try Sign Up!';
      } else if (errStr.contains('wrong-password') || errStr.contains('invalid-credential')) {
        msg = 'Wrong email or password';
      } else if (errStr.contains('email-already-in-use')) {
        msg = 'Account already exists. Try Login!';
      } else if (errStr.contains('weak-password')) {
        msg = 'Password must be at least 6 characters';
      } else if (errStr.contains('invalid-email')) {
        msg = 'Invalid email address';
      } else if (errStr.contains('network')) {
        msg = 'No internet connection';
      } else if (errStr.contains('no-app') || errStr.contains('core/not-initialized')) {
        msg = 'Firebase Configuration Error. Please check setup.';
      }
      if (mounted) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A), // Deep obsidian background
      body: Stack(
        children: [
          // ── Background: Animated Mesh Blobs ──
          _AnimatedMeshBackground(controller: _bgAnimationController),

          // ── Content: Glassmorphic Container ──
          SafeArea(
            child: FadeTransition(
              opacity: _contentFadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Logo & Title
                        _buildBranding(),
                        const SizedBox(height: 48),

                        // Login Card
                        _buildLoginCard(),

                        const SizedBox(height: 32),
                        // Toggle Auth Mode
                        _buildAuthToggle(),
                        const SizedBox(height: 40),
                      ],
                    ),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Hero(
            tag: 'logo',
            child: Icon(
              Icons.auto_awesome,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFAFA2FF), AppColors.primary],
          ).createShader(bounds),
          child: const Text(
            'WIWC',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          'SMART CLASSROOM ECOSYSTEM',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return GlassContainer(
      blur: 24,
      opacity: 0.08,
      padding: const EdgeInsets.all(32),
      borderRadius: 32,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.1),
        width: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSignUp ? 'Create Account' : 'Welcome Back',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSignUp ? 'Join the future of education' : 'Sign in to your dashboard',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),


          // Email Field
          _buildTextField(
            controller: _emailController,
            hint: 'Email Address',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),

          // Password Field
          _buildTextField(
            controller: _passwordController,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13),
            ),
          ],

          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF8A7CFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isSignUp ? 'Sign Up' : 'Continue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
          suffixIcon: isPassword
              ? GestureDetector(
                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white.withValues(alpha: 0.3),
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


  Widget _buildAuthToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
        GestureDetector(
          onTap: () => setState(() {
            _isSignUp = !_isSignUp;
            _error = null;
          }),
          child: Text(
            _isSignUp ? 'Log in' : 'Create one',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}


class _AnimatedMeshBackground extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedMeshBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _MeshPainter(controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double progress;
  _MeshPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Top Right Blob
    final p1 = Offset(
      size.width * 0.8 + 50 * math.sin(progress * 2 * math.pi),
      size.height * 0.2 + 80 * math.cos(progress * 2 * math.pi),
    );
    _drawBlob(canvas, p1, size.width * 0.8, const Color(0xFF6B5CE7).withValues(alpha: 0.2));

    // Bottom Left Blob
    final p2 = Offset(
      size.width * 0.2 + 60 * math.cos(progress * 2 * math.pi),
      size.height * 0.8 + 40 * math.sin(progress * 2 * math.pi),
    );
    _drawBlob(canvas, p2, size.width * 1.0, AppColors.primary.withValues(alpha: 0.15));

    // Middle Right Blob
    final p3 = Offset(
      size.width * 0.9 + 40 * math.sin((progress + 0.5) * 2 * math.pi),
      size.height * 0.5 + 100 * math.cos((progress + 0.5) * 2 * math.pi),
    );
    _drawBlob(canvas, p3, size.width * 0.7, const Color(0xFF2BC89B).withValues(alpha: 0.1));
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

