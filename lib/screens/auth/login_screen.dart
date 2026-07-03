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
  bool _canBio         = false;

  @override void initState() {
    super.initState();
    _checkBio();
  }

  Future<void> _checkBio() async {
    final can = await AuthService.canUseBiometrics();
    if (mounted) setState(() => _canBio = can);
  }

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

  Future<void> _bioLogin() async {
    final authenticated = await AuthService.authenticateBiometrically();
    if (authenticated) {
      setState(() => _isLoading = true);
      final result = await AuthService.loginWithBiometrics();
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _goToMain();
      } else {
        _showSnack(result['message'] ?? 'Biometric login failed. Please enter password.');
      }
    }
  }

  void _goToMain() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainLayout(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 350),
      ),
      (_) => false,
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
      _goToMain();
    } else {
      _showSnack(result['message'] ?? 'Login failed');
    }
  }

  void _showComingSoon(String platform) {
    _showSnack('Social login via $platform is coming soon!', isError: false);
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
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7A5B40), // Brownish
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: AppTheme.glowShadow,
                      ),
                      child: const Center(
                        child: Text('P', style: TextStyle(color: Colors.white, fontSize: 54, fontWeight: FontWeight.w900)),
                      ),
                    ).animate()
                        .scale(duration: 500.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 20),
                    Text('ITEC PARKING',
                      style: AppTheme.heading1.copyWith(fontSize: 30, letterSpacing: 2, color: const Color(0xFF212529)),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 4),
                    Text('Quickly Pay Parking',
                      style: AppTheme.label.copyWith(color: AppTheme.textMuted, letterSpacing: 1),
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
                          style: AppTheme.heading2.copyWith(fontWeight: FontWeight.w900),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text('Secure Login to your driver portal',
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 28),

                      // Username / phone / email
                      Text('Username, Email or Phone', style: AppTheme.label),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Enter username, email or phone',
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

                      if (_canBio) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: IconButton(
                            onPressed: _isLoading ? null : _bioLogin,
                            icon: const Icon(Icons.fingerprint_rounded, size: 48, color: AppTheme.primary),
                            tooltip: 'Login with Biometrics',
                          ),
                        ).animate().fadeIn(delay: 600.ms),
                        Center(
                          child: Text('Login with biometrics', 
                            style: AppTheme.label.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],

                      const SizedBox(height: 32),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _SocialButton(
                        icon: Icons.g_mobiledata_rounded, 
                        label: 'Continue with Google', 
                        color: const Color(0xFF4285F4), 
                        isGoogle: true,
                        onTap: () => _showComingSoon('Google')
                      ),
                      _SocialButton(icon: Icons.apple_rounded, label: 'Continue with Apple', color: Colors.black, onTap: () => _showComingSoon('Apple')),
                      _SocialButton(icon: Icons.facebook_rounded, label: 'Continue with Facebook', color: Colors.blue.shade800, onTap: () => _showComingSoon('Facebook')),
                      _SocialButton(icon: Icons.window_rounded, label: 'Continue with Microsoft', color: Colors.blue.shade600, onTap: () => _showComingSoon('Microsoft')),
                      _SocialButton(icon: Icons.phone_android_rounded, label: 'Continue with Phone Number', color: AppTheme.primary, onTap: () => _showComingSoon('Phone Number')),
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
                  child: Text('© 2026 ITEC Parking · Rwanda',
                    style: AppTheme.label.copyWith(color: AppTheme.textHint, fontWeight: FontWeight.bold)),
                ).animate().fadeIn(delay: 700.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isGoogle;

  const _SocialButton({
    required this.icon, 
    required this.label, 
    required this.color, 
    required this.onTap,
    this.isGoogle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isGoogle)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_\"G\"_logo.svg/1200px-Google_\"G\"_logo.svg.png',
                    height: 22,
                    width: 22,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.g_mobiledata_rounded, color: color, size: 28),
                  ),
                )
              else
                Icon(icon, color: color, size: 24),
              const SizedBox(width: 14),
              Text(
                label, 
                style: const TextStyle(
                  color: Color(0xFF212529), 
                  fontWeight: FontWeight.w700, 
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
