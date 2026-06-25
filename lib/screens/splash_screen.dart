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
  String _step = 'Starting…';

  @override void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600));
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.addListener(() {
      if (!mounted) return;
      final v = _ctrl.value;
      setState(() {
        if (v < 0.3)       _step = 'Starting ITEC Parking…';
        else if (v < 0.6)  _step = 'Loading parking data…';
        else if (v < 0.85) _step = 'Almost ready…';
        else                _step = 'Ready!';
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

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            (AuthService.isLoggedIn && isValid) ? const MainLayout() : const LoginScreen(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(children: [
        // Decorative circles
        Positioned(
          top: -120, left: -80,
          child: Container(width: 350, height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withOpacity(0.06))),
        ),
        Positioned(
          bottom: -80, right: -60,
          child: Container(width: 280, height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withOpacity(0.04))),
        ),

        SafeArea(
          child: Column(children: [
            const Spacer(flex: 2),

            // Logo
            Container(
              width: 92, height: 92,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGrad,
                borderRadius: BorderRadius.circular(26),
                boxShadow: AppTheme.glowShadow,
              ),
              child: const Icon(Icons.local_parking_rounded,
                  color: Colors.white, size: 50),
            )
                .animate()
                .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 700.ms,
                    curve: Curves.elasticOut)
                .fadeIn(),
            const SizedBox(height: 22),

            Text('ITEC Parking',
              style: AppTheme.heading1.copyWith(fontSize: 32),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
            const SizedBox(height: 8),

            Text('Rwanda National Parking System',
              style: AppTheme.body.copyWith(color: AppTheme.textMuted),
            ).animate().fadeIn(delay: 400.ms),

            const Spacer(flex: 2),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: Column(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (_, __) => LinearProgressIndicator(
                      value: _progress.value,
                      backgroundColor: AppTheme.bgDark,
                      valueColor:
                          const AlwaysStoppedAnimation(AppTheme.primary),
                      minHeight: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(_step,
                    key: ValueKey(_step),
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.textMuted)),
                ),
              ]),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 60),
          ]),
        ),
      ]),
    );
  }
}
