import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/social_auth_service.dart';
import 'register_screen.dart';
import 'complete_profile_screen.dart';
import 'forgot_password_screen.dart';
import '../main_layout.dart';
import '../../widgets/widgets.dart';

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
  String? _usernameError; // inline validation, friendlier than a popup
  String? _passwordError;

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

  Future<void> _showSnack(String msg, {bool isError = true}) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: (isError ? AppTheme.danger : AppTheme.success).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                  color: isError ? AppTheme.danger : AppTheme.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isError ? 'Oops!' : 'Success',
                style: AppTheme.heading2.copyWith(color: isError ? AppTheme.danger : AppTheme.success),
              ),
              const SizedBox(height: 8),
              Text(msg, textAlign: TextAlign.center, style: AppTheme.body.copyWith(color: AppTheme.textMuted)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isError ? AppTheme.danger : AppTheme.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
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
        _showSnack(result['message'] ?? 'Biometric login failed.');
      }
    }
  }

  void _goToMain() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainLayout(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 350),
      ),
      (_) => false,
    );
  }

  Future<void> _login() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    // Inline validation is gentler than a blocking popup for empty fields.
    final uErr = username.isEmpty ? 'Please enter your username or phone.' : null;
    final pErr = password.isEmpty ? 'Please enter your password.' : null;
    if (uErr != null || pErr != null) {
      setState(() { _usernameError = uErr; _passwordError = pErr; });
      return;
    }
    setState(() { _usernameError = null; _passwordError = null; _isLoading = true; });
    final result = await AuthService.login(username, password);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result['success'] == true) {
      if (_canBio && !AuthService.isBiometricEnabled) {
        _promptEnableBio();
      } else {
        _goToMain();
      }
    } else {
      _showSnack(result['message'] ?? 'Login failed. Please try again.');
    }
  }

  Future<void> _promptEnableBio() async {
    final enabled = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fingerprint_rounded, color: AppTheme.primary, size: 40),
              ),
              const SizedBox(height: 20),
              Text('Enable Fingerprint?', style: AppTheme.heading3.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                'Enable fingerprint login for faster, secure access next time.',
                textAlign: TextAlign.center,
                style: AppTheme.body.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 28),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Later', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Enable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    if (enabled == true) await AuthService.setBiometricEnabled(true);
    _goToMain();
  }

  Future<void> _socialLogin(String provider) async {
    setState(() => _isLoading = true);
    Map<String, dynamic> result;
    switch (provider) {
      case 'Google':
        result = await SocialAuthService.loginWithGoogle();
        break;
      case 'Facebook':
        result = await SocialAuthService.loginWithFacebook();
        break;
      case 'Apple':
        result = await SocialAuthService.loginWithApple();
        break;
      default:
        result = {'success': false, 'message': 'Unknown provider'};
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result['success'] == true) {
      if (result['requires_phone'] == true || (AuthService.user?.phone.isEmpty ?? true)) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CompleteProfileScreen()));
      } else {
        _goToMain();
      }
    } else {
      _showSnack(result['message'] ?? 'Social login failed.');
    }
  }



  @override
  Widget build(BuildContext context) {
    final statusBarH = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F2),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: statusBarH == 0 ? 24 : 12),

              // ── LOGO BADGE ─────────────────────────────────────
              Container(
                width: 84, height: 84,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: const Center(child: ItecLogo(size: 44, fontSize: 24)),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 16),
              const Text('ITEC PARKING',
                style: TextStyle(color: AppTheme.primaryDeep, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 3))
                .animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 4),
              Text('SMART PARKING SOLUTIONS',
                style: TextStyle(color: AppTheme.primary.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2))
                .animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 28),

              // ── FLOATING AUTH CARD ───────────────────────────────
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 30, offset: const Offset(0, 14))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Welcome back', style: AppTheme.heading2.copyWith(fontWeight: FontWeight.w900))
                      .animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
                    const SizedBox(height: 4),
                    Text('Sign in to keep parking, simplified.', style: AppTheme.body.copyWith(color: AppTheme.textMuted))
                      .animate().fadeIn(delay: 280.ms),
                    const SizedBox(height: 26),

                        // ── USERNAME FIELD ──────────────────────────
                        TextField(
                          controller: _usernameCtrl,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) { if (_usernameError != null) setState(() => _usernameError = null); },
                          style: AppTheme.body.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                          decoration: _inputDeco(
                            hint: 'Username or phone',
                            icon: Icons.person_outline_rounded,
                            hasError: _usernameError != null,
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
                        if (_usernameError != null) _FieldError(text: _usernameError!),
                        const SizedBox(height: 16),

                        // ── PASSWORD FIELD ──────────────────────────
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _login(),
                          onChanged: (_) { if (_passwordError != null) setState(() => _passwordError = null); },
                          style: AppTheme.body.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                          decoration: _inputDeco(
                            hint: 'Password',
                            icon: Icons.lock_outline_rounded,
                            hasError: _passwordError != null,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppTheme.textMuted, size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ).animate().fadeIn(delay: 330.ms).slideY(begin: 0.05),
                        if (_passwordError != null) _FieldError(text: _passwordError!),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4)),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                            child: Text('Forgot Password?', style: AppTheme.bodySmall.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // ── SIGN IN BUTTON ───────────────────────────
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Text('SIGN IN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
                          ),
                        ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.05),

                        if (_canBio) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _bioLogin,
                              icon: const Icon(Icons.fingerprint_rounded, color: AppTheme.primary, size: 24),
                              label: Text('Sign in with Fingerprint', style: AppTheme.body.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.25)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                            ),
                          ).animate().fadeIn(delay: 420.ms),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.04),

                  const SizedBox(height: 28),

                  // ── SOCIAL LOGIN ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(children: [
                      const Expanded(child: Divider(color: AppTheme.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('OR CONTINUE WITH', style: AppTheme.label.copyWith(fontSize: 9, color: AppTheme.textMuted)),
                      ),
                      const Expanded(child: Divider(color: AppTheme.border)),
                    ]),
                  ).animate().fadeIn(delay: 460.ms),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialIconButton(
                        icon: Image.asset(
                          'assets/images/app_photos/google_logo.png',
                          width: 22, height: 22,
                          errorBuilder: (_, __, ___) => Container(
                            width: 22, height: 22,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4285F4)),
                            child: const Center(child: Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12))),
                          ),
                        ),
                        onTap: () => _socialLogin('Google'),
                      ).animate().fadeIn(delay: 500.ms),
                      const SizedBox(width: 14),
                      _SocialIconButton(
                        icon: Icon(Icons.facebook_rounded, color: const Color(0xFF1877F2).withValues(alpha: 0.3), size: 24),
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sign in with Facebook is coming soon.'), behavior: SnackBarBehavior.floating),
                        ),
                      ).animate().fadeIn(delay: 530.ms),
                      const SizedBox(width: 14),
                      _SocialIconButton(
                        icon: Icon(Icons.apple_rounded, color: Colors.black.withValues(alpha: 0.3), size: 24),
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sign in with Apple is coming soon.'), behavior: SnackBarBehavior.floating),
                        ),
                      ).animate().fadeIn(delay: 560.ms),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── REGISTER LINK ───────────────────────────────────
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: AppTheme.body.copyWith(color: AppTheme.textMuted),
                        children: [
                          const TextSpan(text: "Don't have an account?  "),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                              child: Text('Create Account', style: AppTheme.body.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 20),
                  const Text('Copyright © 2026 ITEC Parking',
                    style: TextStyle(color: AppTheme.textHint, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  InputDecoration _inputDeco({required String hint, required IconData icon, Widget? suffix, bool hasError = false}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: hasError ? AppTheme.danger.withValues(alpha: 0.05) : const Color(0xFFF7F5F3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: Icon(icon, color: hasError ? AppTheme.danger : AppTheme.textMuted, size: 20),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: hasError ? AppTheme.danger.withValues(alpha: 0.4) : Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: hasError ? AppTheme.danger : AppTheme.primary, width: 1.6)),
      hintStyle: AppTheme.body.copyWith(color: AppTheme.textHint),
    );
  }
}

class _FieldError extends StatelessWidget {
  final String text;
  const _FieldError({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, left: 4, bottom: 2),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 14),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: AppTheme.bodySmall.copyWith(color: AppTheme.danger, fontWeight: FontWeight.w600))),
    ]),
  );
}

class _SocialIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  const _SocialIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(28),
    child: Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Center(child: icon),
    ),
  );
}
