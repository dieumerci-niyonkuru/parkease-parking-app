import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/notification_service.dart';
import '../widgets/widgets.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
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
  late final PageController _pageController;
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Widget> get _pages => [
    HomeScreen(onNavigateToTab: (i) => setState(() => _currentIndex = i)),
    const ParkingListScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  String get _pageTitle {
    switch (_currentIndex) {
      case 0: return 'DASHBOARD';
      case 1: return 'PARKING SITE';
      case 2: return 'RECEIPTS';
      case 3: return 'MY ACCOUNT';
      default: return 'ITEC PARKING';
    }
  }

  bool get _isProfileIncomplete {
    final user = AuthService.user;
    return user == null || user.phone.isEmpty || user.phone == '+250 7XX XXX XXX' || user.phone == '—';
  }

  void _triggerHeaderSearch() {
    if (!_isSearching) {
      setState(() => _isSearching = true);
      context.read<AppProvider>().setSearchActive(true);
    }
  }

  @override Widget build(BuildContext context) {
    final profile = ProfileService.profile;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        leadingWidth: 0,
        automaticallyImplyLeading: false,
        title: _isSearching
          ? Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.search_rounded, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    cursorColor: Colors.white,
                    decoration: const InputDecoration(
                      hintText: 'Search sites, plates, receipts...',
                      hintStyle: TextStyle(color: Colors.white60, fontSize: 13),
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: (v) {
                      context.read<AppProvider>().updateSearchQuery(v);
                      setState(() {});
                    },
                  ),
                ),
                if (_searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      context.read<AppProvider>().updateSearchQuery('');
                      setState(() {});
                    },
                    child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                  ),
              ]),
            )
          : Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 0),
                  child: const ItecLogo(size: 32, fontSize: 18),
                ),
                const SizedBox(width: 12),
                Text(_pageTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ],
            ),
        actions: [
          // ── NOTIFICATIONS ─────────────────────────────────────
          IconButton(
            onPressed: () async {
              await Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
              if (mounted) setState(() {}); // refresh unread badge on return
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                if (NotificationService.unreadCount > 0)
                  Positioned(
                    top: -4, right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        NotificationService.unreadCount > 9 ? '9+' : '${NotificationService.unreadCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, height: 1),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (_isSearching) {
                  // Opening search: pre-fill with the current query so the
                  // user can continue where they left off from the inline field.
                  final current = context.read<AppProvider>().searchQuery;
                  _searchCtrl.text = current;
                  _searchCtrl.selection = TextSelection.fromPosition(TextPosition(offset: current.length));
                } else {
                  // Closing search: clear the field and the active query so
                  // lists return to their full, unfiltered state.
                  _searchCtrl.clear();
                  context.read<AppProvider>().updateSearchQuery('');
                }
                context.read<AppProvider>().setSearchActive(_isSearching);
              });
            },
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, size: 22, color: Colors.white),
            tooltip: _isSearching ? 'Close search' : 'Search',
          ),
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.only(right: 8, left: 4),
              child: PopupMenuButton<int>(
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) async {
                  if (val == 0) {
                    setState(() => _currentIndex = 3); // Go to profile
                    _pageController.animateToPage(3, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
                      if (mounted && context.mounted) {
                        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
                      }
                    }
                  }
                },
                icon: Hero(
                  tag: 'main-avatar',
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: profile.profilePic.isNotEmpty
                        ? (kIsWeb
                            ? NetworkImage(profile.profilePic)
                            : FileImage(File(profile.profilePic)) as ImageProvider)
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
          child: Container(color: AppTheme.border.withValues(alpha: 0.5), height: 1),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = i);
        },
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
          if (i == 2 && _isProfileIncomplete) {
            _showProfileRequiredDialog();
            return;
          }
          HapticFeedback.lightImpact();
          _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      ),
    );
  }

  void _showProfileRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Color(0xFF7A5B40)),
            SizedBox(width: 12),
            Text('Action Required', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Text(
          'To access Receipts, you must first complete your profile by linking a phone number.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('LATER', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _currentIndex = 3);
              _pageController.animateToPage(3, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7A5B40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('SET PHONE NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
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
      (Icons.directions_car_rounded,  Icons.directions_car_outlined, 'Parking Site'),
      (Icons.receipt_long_rounded,    Icons.receipt_long_outlined,   'Receipts'),
      (Icons.person_rounded,          Icons.person_outlined,         'Account'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = current == i;
              final item   = items[i];

              return GestureDetector(
                onTap: () {
                  if (!active) HapticFeedback.selectionClick();
                  onTap(i);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? item.$1 : item.$2,
                        color: active ? Colors.white : Colors.white60,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
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
