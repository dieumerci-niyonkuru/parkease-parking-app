import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'home_screen.dart';
import 'parking_list_screen.dart';
import 'plate_lookup_screen.dart';
import 'history_screen.dart';
import 'receipt_detail_screen.dart';
import 'parking_details_screen.dart';
import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;
  const MainLayout({super.key, this.initialIndex = 0});

  @override State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    const HomeScreen(),
    const ParkingListScreen(),
    const PlateLookupScreen(initialPlate: ''),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  String get _pageTitle {
    switch (_currentIndex) {
      case 0: return 'DASHBOARD';
      case 1: return 'PARKING SITE';
      case 2: return 'PLATE LOOKUP';
      case 3: return 'RECEIPTS';
      case 4: return 'MY ACCOUNT';
      default: return 'ITEC PARKING';
    }
  }

  void _triggerHeaderSearch() {
    if (!_isSearching) {
      setState(() => _isSearching = true);
      context.read<AppProvider>().setSearchActive(true);
    }
  }

  @override Widget build(BuildContext context) {
    final profile = ProfileService.profile;
    final user = AuthService.user;
    final firstName = user?.names.split(' ').first ?? 'Driver';
    final dateStr = DateFormat("EEEE, d MMMM").format(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.primary, // Fixed Brand Color on top
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        leadingWidth: 0,
        automaticallyImplyLeading: false,
        title: _isSearching 
          ? TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Type search here...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) {
                context.read<AppProvider>().updateSearchQuery(v);
              },
            )
          : Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('P', style: TextStyle(color: Color(0xFF7A5B40), fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 12),
                if (_currentIndex == 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome Back', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      Text(firstName.toLowerCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, height: 1.1)),
                      Text(dateStr, style: const TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.w600)),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ITEC PARKING', style: TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
                      Text(_pageTitle, style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
              ],
            ),
        actions: [
          IconButton(
            onPressed: () {
              if (_currentIndex != 0) {
                setState(() => _currentIndex = 0);
              } else {
                final nav = _navigatorKeys[0].currentState;
                if (nav != null && nav.canPop()) {
                  nav.popUntil((r) => r.isFirst);
                }
              }
              setState(() {});
            },
            icon: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
            tooltip: 'Back to Home',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                context.read<AppProvider>().setSearchActive(_isSearching);
              });
            },
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, size: 22, color: Colors.white),
          ),
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.only(right: 8, left: 4),
              child: PopupMenuButton<int>(
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) async {
                  if (val == 0) {
                    setState(() => _currentIndex = 4); // Go to profile (index 4)
                  } else if (val == 1) {
                    // ── LOGOUT CONFIRMATION DIALOG ──────────────────
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.bgCard,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        title: Text('Sign Out', style: AppTheme.heading3),
                        content: const Text('Are you sure you want to exit the ITEC Portal?', style: TextStyle(fontSize: 14)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('CANCEL', style: AppTheme.label.copyWith(color: AppTheme.textMuted)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.danger,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('SIGN OUT'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await AuthService.logout();
                      if (mounted) {
                        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
                      }
                    }
                  }
                },
                icon: Hero(
                  tag: 'main-avatar',
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: profile.profilePic.isNotEmpty
                        ? FileImage(File(profile.profilePic))
                        : null,
                    child: profile.profilePic.isEmpty
                        ? const Icon(Icons.person_rounded, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 0,
                    child: Row(children: [
                      const Icon(Icons.person_outline_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text('My Profile', style: AppTheme.body),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 1,
                    child: Row(children: [
                      const Icon(Icons.logout_rounded, size: 20, color: AppTheme.danger),
                      const SizedBox(width: 12),
                      Text('Logout', style: AppTheme.body.copyWith(color: AppTheme.danger)),
                    ]),
                  ),
                ],
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.border.withOpacity(0.5), height: 1),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(_pages.length, (index) {
          return Navigator(
            key: _navigatorKeys[index],
            onGenerateInitialRoutes: (navigator, initialRoute) {
              return [
                MaterialPageRoute(builder: (context) => _pages[index]),
              ];
            },
            onGenerateRoute: (settings) {
              Widget builder;
              switch (settings.name) {
                case 'receipt_detail':
                  builder = ReceiptDetailScreen(entry: settings.arguments as HistoryEntry);
                  break;
                case 'parking_detail':
                  builder = ParkingDetailsScreen(facility: settings.arguments as ParkingFacility);
                  break;
                case 'plate_lookup':
                  builder = PlateLookupScreen(initialPlate: settings.arguments as String);
                  break;
                case 'trigger_search':
                  // This is a special trigger to open the search bar
                  _triggerHeaderSearch();
                  builder = _pages[index];
                  break;
                default:
                  builder = _pages[index];
              }
              return MaterialPageRoute(builder: (context) => builder);
            },
          );
        }),
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
      (Icons.home_rounded,            Icons.home_outlined,           'Home'),
      (Icons.directions_car_rounded,  Icons.directions_car_outlined, 'ParkingSites'),
      (Icons.electric_bolt_rounded,   Icons.electric_bolt_outlined,  'Quick Pay'),
      (Icons.receipt_long_rounded,    Icons.receipt_long_outlined,   'Receipts'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary, // Matches the top bar color
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -4))],
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
                    color: active ? Colors.white.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? item.$1 : item.$2,
                        color: active ? Colors.white : Colors.white60,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(item.$3,
                        style: TextStyle(
                          color: active ? Colors.white : Colors.white60,
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
