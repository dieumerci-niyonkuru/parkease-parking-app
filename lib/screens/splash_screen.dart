import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import 'main_layout.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  String _step = 'Initializing...';

  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _ctrl.addListener(() {
      if (!mounted) return;
      final v = _ctrl.value;
      setState(() {
        if (v < 0.25)       _step = 'Securing Connection...';
        else if (v < 0.5)   _step = 'Retrieving Parking Sites...';
        else if (v < 0.75)  _step = 'Validating Driver Session...';
        else                _step = 'Smart Parking Solutions';
      });
    });
    _ctrl.forward();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      AuthService.restore(),
      NotificationService.init(),
      ProfileService.load(),
    ]);

    bool isValid = true; 
    bool bioSuccess = false;

    if (AuthService.isLoggedIn) {
      final check = await AuthService.validateToken();
      if (check == false) {
        isValid = false;
        await AuthService.logout();
      }
    } else if (AuthService.isBiometricEnabled && await AuthService.canUseBiometrics() && await AuthService.hasStoredCredentials()) {
      // ── BIOMETRIC LOGIN FLOW ──────────────────────────────
      setState(() => _step = 'Biometric Login...'.toUpperCase());
      bioSuccess = await AuthService.authenticateBiometrically();
      if (bioSuccess) {
        final result = await AuthService.loginWithBiometrics();
        if (result['success'] != true) {
          bioSuccess = false;
        }
      }
    }

    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            (AuthService.isLoggedIn && (isValid || bioSuccess)) ? const MainLayout() : const LoginScreen(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary, // Brand Brown Background
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.primary,
        ),
        child: Column(children: [
          const Spacer(flex: 3),

          // ── BRANDING BADGE (Large white square with P) ─────────────
          Hero(
            tag: 'logo',
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: const Center(
                child: Text('P', style: TextStyle(color: Color(0xFF7A5B40), fontSize: 64, fontWeight: FontWeight.w900)),
              ),
            ),
          ).animate().scale(begin: const Offset(0.5, 0.5), duration: 800.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 32),
          const Text('ITEC PARKING',
            style: TextStyle(color: Colors.white, fontSize: 28, letterSpacing: 4, fontWeight: FontWeight.w900),
          ).animate().fadeIn(delay: 300.ms),
          
          const SizedBox(height: 4),
          const Text('Smart Parking Solutions',
            style: TextStyle(color: Colors.white70, letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.w700),
          ).animate().fadeIn(delay: 500.ms),

          const Spacer(flex: 2),

          // ── LOADING INDICATOR ──────────────────────────────────────
          Column(children: [
            const SizedBox(
              width: 40, height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(height: 32),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(_step,
                key: ValueKey(_step),
                style: const TextStyle(
                  color: Colors.white70, 
                  fontWeight: FontWeight.w800, 
                  letterSpacing: 1,
                  fontSize: 11,
                )),
            ),
          ]).animate().fadeIn(delay: 700.ms),

          const SizedBox(height: 64),
        ]),
      ),
    );
  }
}
