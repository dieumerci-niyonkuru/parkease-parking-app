import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
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

  Future<void> _showSnack(String msg, {bool isError = true}) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: isError ? AppTheme.danger : AppTheme.success,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(isError ? 'ERROR' : 'SUCCESS', 
              style: AppTheme.heading3.copyWith(
                letterSpacing: 2, 
                color: isError ? AppTheme.danger : AppTheme.success
              )),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: AppTheme.body.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isError ? AppTheme.danger : AppTheme.success,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 8),
          ],
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

  Future<void> _showComingSoon(String platform) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 64),
            const SizedBox(height: 24),
            Text('COMING SOON', style: AppTheme.heading3.copyWith(letterSpacing: 2, color: AppTheme.primary)),
            const SizedBox(height: 12),
            Text(
              '$platform login is currently under development and will be available in the next update!',
              textAlign: TextAlign.center,
              style: AppTheme.body.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('UNDERSTOOD', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Column(
        children: [
          // ── BRANDED HEADER ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 0),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                const Text('ITEC PARKING', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 4)),
                const SizedBox(height: 4),
                Text('National Parking Management System'.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Rwanda\'s most advanced digital parking portal', style: TextStyle(color: Colors.white54, fontSize: 10, fontStyle: FontStyle.italic)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: const Center(
                    child: Text('SIGN IN', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Logo / Badge ───────────────────────────────────────
                            Center(
                              child: Container(
                                width: 100, height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 12))
                                  ],
                                  border: Border.all(color: Colors.grey.shade100),
                                ),
                                child: const Center(
                                  child: Text('P', style: TextStyle(color: Color(0xFF7A5B40), fontSize: 60, fontWeight: FontWeight.w900)),
                                ),
                              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                            ),
                            const SizedBox(height: 32),

                            // ── Login Card ────────────────────────────────────────
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                                boxShadow: AppTheme.subtleShadow,
                              ),
                              child: Column(
                                children: [
                                  Text('Welcome Back', style: AppTheme.heading2.copyWith(fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 6),
                                  Text('Secure Login to your driver portal', style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted)),
                                  const SizedBox(height: 32),

                                  Align(alignment: Alignment.centerLeft, child: Text('Email or Phone Number', style: AppTheme.label)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _usernameCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    textAlign: TextAlign.center,
                                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                                    decoration: const InputDecoration(
                                      hintText: 'Enter email or phone number',
                                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  Align(alignment: Alignment.centerLeft, child: Text('Password', style: AppTheme.label)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _passwordCtrl,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _login(),
                                    textAlign: TextAlign.center,
                                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                                    decoration: InputDecoration(
                                      hintText: '••••••••',
                                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textMuted, size: 20),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => _showComingSoon('Reset Password'),
                                      child: Text('Forgot Password?', style: AppTheme.bodySmall.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  SizedBox(
                                    width: double.infinity, height: 56,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                          : const Text('SIGN IN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                                    ),
                                  ),

                                  const SizedBox(height: 24),
                                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Text("Don't have an account? ", style: AppTheme.bodySmall),
                                    GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                      child: Text('Register here', style: AppTheme.bodySmall.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900)),
                                    ),
                                  ]),

                                  if (_canBio) ...[
                                    const SizedBox(height: 24),
                                    Center(
                                      child: InkWell(
                                        onTap: _isLoading ? null : _bioLogin,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(children: [
                                            const Icon(Icons.fingerprint_rounded, size: 44, color: Color(0xFF7A5B40)),
                                            const SizedBox(height: 4),
                                            Text('BIO LOGIN', style: AppTheme.label.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 9)),
                                          ]),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

                            const SizedBox(height: 32),
                            const _DividerText(text: 'OR CONTINUE WITH'),
                            const SizedBox(height: 24),

                            _SocialButton(
                              isGoogle: true, 
                              label: 'Continue with Google', 
                              color: const Color(0xFF4285F4), 
                              icon: Icons.g_mobiledata_rounded, 
                              onTap: () => _showComingSoon('Google')
                            ),
                            _SocialButton(
                              label: 'Continue with Apple', 
                              color: Colors.black, 
                              icon: Icons.apple_rounded, 
                              onTap: () => _showComingSoon('Apple')
                            ),
                            _SocialButton(
                              label: 'Continue with Facebook', 
                              color: const Color(0xFF1877F2), 
                              icon: Icons.facebook_rounded, 
                              onTap: () => _showComingSoon('Facebook')
                            ),
                            
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
            ),
          ),

          // ── BRANDED FOOTER ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: const Center(
              child: Text('2026 ITEC Parking . Rwanda', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerText extends StatelessWidget {
  final String text;
  const _DividerText({required this.text});
  @override Widget build(BuildContext context) => Row(children: [
    const Expanded(child: Divider()),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(text, style: AppTheme.label.copyWith(fontSize: 9, color: AppTheme.textMuted))),
    const Expanded(child: Divider()),
  ]);
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  const _ContactRow(this.icon, this.label, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.label.copyWith(fontSize: 9, color: AppTheme.textMuted)),
              const SizedBox(height: 2),
              Text(text, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isGoogle;
  final bool isMicrosoft;
  final bool isGuest;

  const _SocialButton({
    required this.icon, 
    required this.label, 
    required this.color, 
    required this.onTap,
    this.isGoogle = false,
    this.isMicrosoft = false,
    this.isGuest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade200, width: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color(0xFFFFF7F2), // Light cream matching dashboard cards
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isGoogle)
                Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e1/Google_Chrome_icon_%28February_2022%29.svg/1024px-Google_Chrome_icon_%28February_2022%29.svg.png',
                  height: 24,
                  width: 24,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.g_mobiledata_rounded, color: color, size: 28),
                )
              else if (isMicrosoft)
                Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Microsoft_logo.svg/1024px-Microsoft_logo.svg.png',
                  height: 18,
                  width: 18,
                  errorBuilder: (context, error, stackTrace) => Icon(icon, color: color, size: 22),
                )
              else if (isGuest)
                const Icon(Icons.account_circle_outlined, color: Color(0xFF5F6368), size: 24)
              else
                Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Text(
                label, 
                style: const TextStyle(
                  color: Color(0xFF3C4043), 
                  fontWeight: FontWeight.w700, 
                  fontSize: 14,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
