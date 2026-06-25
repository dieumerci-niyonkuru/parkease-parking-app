import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import '../main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl  = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  bool _isLoading      = false;
  bool _obscurePassword = true;

  @override void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      ),
    );
  }

  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnack('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.login(username, password);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainLayout(),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 350),
        ),
        (_) => false,
      );
    } else {
      _showSnack(result['message'] ?? 'Login failed');
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Logo ───────────────────────────────────────
                Center(
                  child: Column(children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGrad,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.glowShadow,
                      ),
                      child: const Icon(Icons.local_parking_rounded,
                          color: Colors.white, size: 44),
                    ).animate()
                        .scale(duration: 500.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 16),
                    Text('ITEC Parking',
                      style: AppTheme.heading1.copyWith(fontSize: 26),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 6),
                    Text('ITEC Parking',
                      style: AppTheme.body.copyWith(color: AppTheme.textMuted),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 280.ms),
                  ]),
                ),
                const SizedBox(height: 48),

                // ── Card ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    border: Border.all(color: AppTheme.border, width: 0.5),
                    boxShadow: AppTheme.subtleShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome Back',
                          style: AppTheme.heading2,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text('Sign in to manage your parking',
                          style: AppTheme.body,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 28),

                      // Username / phone
                      Text('Username or Phone', style: AppTheme.label),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameCtrl,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Enter username or phone',
                          prefixIcon:
                              Icon(Icons.person_outline_rounded, size: 20),
                        ),
                      ).animate().fadeIn(delay: 350.ms),
                      const SizedBox(height: 18),

                      // Password
                      Text('Password', style: AppTheme.label),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.textMuted, size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ).animate().fadeIn(delay: 420.ms),
                      const SizedBox(height: 28),

                      // Login button
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGrad,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMd)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Text('Sign In',
                                    style: AppTheme.heading4
                                        .copyWith(color: Colors.white, fontSize: 16)),
                          ),
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08),
                const SizedBox(height: 28),

                // ── Register link ───────────────────────────────
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("Don't have an account? ", style: AppTheme.body),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    ),
                    child: Text('Register here',
                      style: AppTheme.body.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      )),
                  ),
                ]).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 16),
                Center(
                  child: Text('© 2024 ITEC Parking · Rwanda',
                    style: AppTheme.label.copyWith(color: AppTheme.textHint)),
                ).animate().fadeIn(delay: 700.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
