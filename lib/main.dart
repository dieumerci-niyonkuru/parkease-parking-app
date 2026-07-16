import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/main_layout.dart';
import 'screens/auth/login_screen.dart';
import 'screens/history_screen.dart';
import 'providers/app_provider.dart';
import 'providers/theme_provider.dart';
import 'app_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  AppTheme.setSystemUI();
  final themeProvider = ThemeProvider();
  await themeProvider.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const ITECParkingApp(),
    ),
  );
}

class ITECParkingApp extends StatelessWidget {
  const ITECParkingApp({super.key});

  @override Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().mode;
    return MaterialApp(
      title: 'ITEC Parking',
      navigatorKey: AppNavigation.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // Clamp system font scaling so very large accessibility text sizes
      // can't overflow or hide content on any screen, while still honouring
      // moderate scaling for readability.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.25),
          ),
          child: child!,
        );
      },
      home: const SplashScreen(),
      routes: {
        '/main':     (context) => const MainLayout(),
        '/login':    (context) => const LoginScreen(),
        '/receipts': (context) => const HistoryScreen(),
      },
    );
  }
}
