import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/main_layout.dart';
import 'screens/auth/login_screen.dart';
import 'screens/history_screen.dart';
import 'providers/app_provider.dart';
import 'app_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  AppTheme.setSystemUI();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const ITECParkingApp(),
    ),
  );
}

class ITECParkingApp extends StatelessWidget {
  const ITECParkingApp({super.key});

  @override Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ITEC Parking',
      navigatorKey: AppNavigation.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
      routes: {
        '/main':     (context) => const MainLayout(),
        '/login':    (context) => const LoginScreen(),
        '/receipts': (context) => const HistoryScreen(),
      },
    );
  }
}
