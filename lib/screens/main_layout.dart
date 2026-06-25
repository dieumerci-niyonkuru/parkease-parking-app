import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'plate_lookup_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;
  const MainLayout({super.key, this.initialIndex = 0});

  @override State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    const HomeScreen(),
    const PlateLookupScreen(initialPlate: ''),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _PremiumBottomNav(
        current: _currentIndex,
        onTap: (i) {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = i);
        },
      ),
    );
  }
}

class _PremiumBottomNav extends StatelessWidget {
  final int current;
  final void Function(int) onTap;
  const _PremiumBottomNav({required this.current, required this.onTap});

  @override Widget build(BuildContext context) {
    const items = [
      (Icons.dashboard_rounded,       Icons.dashboard_outlined,      'Portal'),
      (Icons.bolt_rounded,            Icons.bolt_outlined,           'Quick Pay'),
      (Icons.receipt_long_rounded,    Icons.receipt_long_outlined,   'Receipts'),
      (Icons.person_rounded,          Icons.person_outline_rounded,  'Account'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(top: BorderSide(color: AppTheme.border.withOpacity(0.5), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = current == i;
              final item   = items[i];

              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.primary.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? item.$1 : item.$2,
                        color: active ? AppTheme.primary : AppTheme.textMuted,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(item.$3,
                        style: TextStyle(
                          color: active ? AppTheme.primary : AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                          letterSpacing: 0.2,
                        )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
