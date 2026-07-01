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
  late Animation<double>    _progress;
  String _step = 'Initializing System...';

  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.addListener(() {
      if (!mounted) return;
      final v = _ctrl.value;
      setState(() {
        if (v < 0.25)       _step = 'Securing Connection...';
        else if (v < 0.5)   _step = 'Retrieving Parking Hubs...';
        else if (v < 0.75)  _step = 'Validating Driver Session...';
        else                _step = 'ITEC System Online';
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

    bool isValid = false;
    if (AuthService.isLoggedIn) {
      isValid = await AuthService.validateToken();
      if (!isValid) await AuthService.logout();
    }

    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            (AuthService.isLoggedIn && isValid) ? const MainLayout() : const LoginScreen(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.bgDeep, AppTheme.primary.withOpacity(0.05)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: Column(children: [
          const Spacer(flex: 3),

          // ── ITEC BRANDING BADGE ────────────────────────────────────
          Stack(alignment: Alignment.center, children: [
            Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2), duration: 1500.ms, curve: Curves.easeInOut).fadeOut(),
            
            Hero(
              tag: 'logo',
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGrad,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppTheme.glowShadow,
                ),
                child: const Icon(Icons.local_parking_rounded, color: Colors.white, size: 56),
              ),
            ).animate().scale(begin: const Offset(0.5, 0.5), duration: 800.ms, curve: Curves.elasticOut),
          ]),

          const SizedBox(height: 32),
          Text('ITEC PARKING',
            style: AppTheme.heading1.copyWith(fontSize: 32, letterSpacing: 2, color: AppTheme.primary),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
          
          Text('RWA',
            style: AppTheme.label.copyWith(letterSpacing: 4, color: AppTheme.textMuted, fontWeight: FontWeight.w900),
          ).animate().fadeIn(delay: 500.ms),

          const Spacer(flex: 2),

          // ── LOADING SYSTEM ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Column(children: [
              const SizedBox(
                width: 40,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(Color(0xFF7A5B40)),
                  minHeight: 2,
                ),
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(_step.toUpperCase(),
                  key: ValueKey(_step),
                  style: AppTheme.label.copyWith(
                    color: const Color(0xFF7A5B40), 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 2,
                    fontSize: 10,
                  )),
              ),
            ]),
          ).animate().fadeIn(delay: 700.ms),

          const SizedBox(height: 80),
          Text('© 2024 ITEC RWANDA', style: AppTheme.label.copyWith(fontSize: 8, color: AppTheme.textHint)),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}
