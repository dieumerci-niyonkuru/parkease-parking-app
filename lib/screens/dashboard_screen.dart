import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../providers/app_provider.dart';
import '../widgets/widgets.dart';
import 'plate_lookup_screen.dart';
import 'history_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'parking_costs_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;
  int _notifCount = 0;

  void _onNotifChanged() =>
    setState(() => _notifCount = NotificationService.unreadCount);

  @override void initState() {
    super.initState();
    _notifCount = NotificationService.unreadCount;
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: IndexedStack(index: _tab, children: [
        _HomeTab(
          notifCount: _notifCount,
          onNotifTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()))
            .then((_) => _onNotifChanged()),
        ),
        const PlateLookupScreen(initialPlate: ''),
        const HistoryScreen(),
        const ProfileScreen(),
      ]),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        notifCount: _notifCount,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int current, notifCount;
  final void Function(int) onTap;
  const _BottomNav({required this.current, required this.notifCount, required this.onTap});

  @override Widget build(BuildContext context) {
    final items = [
      (Icons.dashboard_rounded,  Icons.dashboard_outlined,   'Dashboard'),
      (Icons.local_parking_rounded, Icons.local_parking_outlined, 'Parking'),
      (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Receipts'),
      (Icons.person_rounded,     Icons.person_outline_rounded,'Profile'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = current == i;
              final item   = items[i];
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.primary.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Stack(clipBehavior: Clip.none, children: [
                      Icon(active ? item.$1 : item.$2,
                        color: active ? AppTheme.primary : AppTheme.textMuted, size: 24),
                      // notification dot on Home tab
                      if (i == 0 && notifCount > 0)
                        Positioned(top: -3, right: -3,
                          child: Container(width: 8, height: 8,
                            decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle))),
                    ]),
                    const SizedBox(height: 3),
                    Text(item.$3, style: TextStyle(
                      color: active ? AppTheme.primary : AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    )),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final int notifCount;
  final VoidCallback onNotifTap;
  const _HomeTab({required this.notifCount, required this.onNotifTap});
  @override State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _plateCtrl = TextEditingController();
  List<ParkingFacility> _facilities = [];
  List<HistoryEntry>    _history    = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }
  @override void dispose()   { _plateCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final results = await Future.wait([ApiService.getAllParking(), ApiService.getReceipts()]);
    if (!mounted) return;
    setState(() {
      _facilities = results[0] as List<ParkingFacility>;
      _history    = results[1] as List<HistoryEntry>;
      _loading    = false;
    });
  }

  void _lookup() {
    final plate = _plateCtrl.text.trim().toUpperCase();
    if (plate.isEmpty) return;
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PlateLookupScreen(initialPlate: plate),
    )).then((_) => _load());
  }

  @override Widget build(BuildContext context) {
    final profile = ProfileService.profile;
    final provider = context.watch<AppProvider>();
    final active = provider.activeSession;
    final recentPaid = _history.where((h) => h.status == 'paid').length;
    final recentParked = _history.where((h) => h.status == 'parked').length;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────
          SliverAppBar(
            pinned: true, floating: true,
            expandedHeight: 0,
            backgroundColor: AppTheme.bgDeep,
            automaticallyImplyLeading: false,
            title: Row(children: [
              Container(width: 34, height: 34,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGrad,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.local_parking_rounded, color: Colors.black, size: 20)),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ITEC Parking', style: AppTheme.heading4.copyWith(fontSize: 15)),
                Text('Rwanda', style: AppTheme.label),
              ]),
              const Spacer(),
              GestureDetector(
                onTap: () {
                   // Quick view profile
                },
                child: CircleAvatar(
                  radius: 19,
                  backgroundColor: AppTheme.bgSurface,
                  backgroundImage: profile.profilePic.isNotEmpty
                      ? FileImage(File(profile.profilePic))
                      : null,
                  child: profile.profilePic.isEmpty
                      ? const Icon(Icons.person_outline_rounded, color: AppTheme.textSecond, size: 20)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: widget.onNotifTap,
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Icon(Icons.notifications_outlined, color: AppTheme.textSecond, size: 20)),
                  if (widget.notifCount > 0)
                    Positioned(top: -4, right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                        child: Text(
                          widget.notifCount > 9 ? '9+' : '${widget.notifCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                      )),
                ]),
              ),
            ]),
          ),

          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Greeting ─────────────────────────────────
              Text(
                profile.hasData ? 'Hello, ${profile.name.split(' ').first}!' : 'Hello!',
                style: AppTheme.heading2,
              ).animate().fadeIn(duration: 350.ms),
              const SizedBox(height: 4),
              Text(
                DateFormat("EEEE, d MMM yyyy · HH:mm").format(DateTime.now()),
                style: AppTheme.bodySmall.copyWith(color: AppTheme.primary),
              ).animate().fadeIn(delay: 80.ms),
              const SizedBox(height: 24),

              // ── ACTIVE SESSION CARD (IF ANY) ──────────────
              if (active != null) ...[
                ActiveSessionCard(
                  record: active,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PlateLookupScreen(initialPlate: active.plateNumber),
                  )).then((_) => _load()),
                ).animate().fadeIn().slideY(begin: 0.1),
                const SizedBox(height: 24),
              ],

              // ── MAIN PLATE LOOKUP CARD ────────────────────
              _PlateLookupCard(ctrl: _plateCtrl, onLookup: _lookup)
                .animate().fadeIn(delay: 120.ms).slideY(begin: 0.08),
              const SizedBox(height: 20),

              // ── Quick stats ───────────────────────────────
              if (!_loading) ...[
                Row(children: [
                  Expanded(child: _MiniStat(
                    label: 'Facilities', value: '${_facilities.length}',
                    icon: Icons.location_on_rounded, color: AppTheme.accent)),
                  const SizedBox(width: 10),
                  Expanded(child: _MiniStat(
                    label: 'Paid', value: '$recentPaid',
                    icon: Icons.check_circle_rounded, color: AppTheme.success)),
                  const SizedBox(width: 10),
                  Expanded(child: _MiniStat(
                    label: 'Parked', value: '$recentParked',
                    icon: Icons.directions_car_rounded, color: AppTheme.warning)),
                ]).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParkingCostsScreen())),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('VIEW ALL PARKING COSTS', style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.bold, fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ).animate().fadeIn(delay: 230.ms),
                const SizedBox(height: 24),
              ],

              // ── How it works ──────────────────────────────
              _HowItWorks().animate().fadeIn(delay: 260.ms),
              const SizedBox(height: 24),

              // ── Recent searches ───────────────────────────
              if (_history.isNotEmpty) ...[
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Recent', style: AppTheme.heading4),
                  GestureDetector(
                    onTap: () {}, // switch to history tab handled in parent
                    child: Text('See all', style: AppTheme.bodySmall.copyWith(color: AppTheme.primary))),
                ]),
                const SizedBox(height: 12),
                ..._history.take(3).map((h) => _RecentCard(entry: h,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PlateLookupScreen(initialPlate: h.plateNumber),
                  )).then((_) => _load()),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.04)),
              ],

              // ── System status ─────────────────────────────
              const SizedBox(height: 8),
              _StatusBar().animate().fadeIn(delay: 360.ms),
            ]),
          )),
        ],
      ),
    );
  }
}

// ── Plate Lookup Card (HERO) ─────────────────────────────────────
class _PlateLookupCard extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onLookup;
  const _PlateLookupCard({required this.ctrl, required this.onLookup});

  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1F35), Color(0xFF0A1A1A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
        boxShadow: [BoxShadow(
          color: AppTheme.primary.withOpacity(0.08),
          blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 20)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Find Your Vehicle', style: AppTheme.heading4),
            Text('Enter plate number to check & pay', style: AppTheme.bodySmall),
          ]),
        ]),
        const SizedBox(height: 16),
        // Plate input
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.border),
          ),
          child: TextField(
            controller: ctrl,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onLookup(),
            style: const TextStyle(
              fontFamily: 'monospace', fontSize: 20,
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
              letterSpacing: 3,
            ),
            decoration: InputDecoration(
              hintText: 'RAC 001 A',
              hintStyle: const TextStyle(
                fontFamily: 'monospace', fontSize: 20,
                color: AppTheme.textHint, letterSpacing: 3,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text('RW', style: AppTheme.label.copyWith(color: AppTheme.primary)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 50,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGrad,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: ElevatedButton.icon(
              onPressed: onLookup,
              icon: const Icon(Icons.search_rounded, color: Colors.black, size: 20),
              label: Text('Check & Pay',
                style: AppTheme.heading4.copyWith(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Mini Stat ─────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.icon, required this.color});

  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.bgCard,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 8),
      Text(value, style: AppTheme.heading3.copyWith(color: color)),
      Text(label, style: AppTheme.bodySmall),
    ]),
  );
}

// ── How It Works ─────────────────────────────────────────────────
class _HowItWorks extends StatelessWidget {
  @override Widget build(BuildContext context) {
    final steps = [
      (Icons.directions_car_outlined, 'Enter Plate', 'Type your Rwanda plate number above'),
      (Icons.info_outline_rounded,    'See Details', 'View parking site, entry time & fee'),
      (Icons.payment_rounded,         'Pay Easily',  'Pay via MoMo, Airtel, card or cash'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('How it works', style: AppTheme.heading4),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: List.generate(steps.length, (i) {
          final step = steps[i];
          return Expanded(child: Row(children: [
            Expanded(child: Column(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Icon(step.$1, color: AppTheme.primary, size: 18)),
              const SizedBox(height: 8),
              Text(step.$2, style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(step.$3, style: AppTheme.label, textAlign: TextAlign.center, maxLines: 2),
            ])),
            if (i < steps.length - 1)
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint, size: 18),
          ]));
        })),
      ),
    ]);
  }
}

// ── Recent Card ───────────────────────────────────────────────────
class _RecentCard extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback onTap;
  const _RecentCard({required this.entry, required this.onTap});

  @override Widget build(BuildContext context) {
    final color = entry.status.statusColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.directions_car_rounded, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry.plateNumber, style: AppTheme.body.copyWith(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w700,
              fontFamily: 'monospace', letterSpacing: 1.5)),
            Text('${entry.parkingName} · ${entry.durationDisplay}',
              style: AppTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatusBadge(label: entry.status.statusLabel, color: color),
            const SizedBox(height: 4),
            Text(DateFormat('HH:mm').format(entry.searchedAt), style: AppTheme.label),
          ]),
        ]),
      ),
    );
  }
}

// ── Status Bar ────────────────────────────────────────────────────
class _StatusBar extends StatelessWidget {
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.bgCard,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
    ),
    child: Row(children: [
      Container(width: 7, height: 7,
        decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle))
        .animate(onPlay: (c) => c.repeat())
        .scaleXY(begin: 1, end: 1.5, duration: 900.ms)
        .then().scaleXY(begin: 1.5, end: 1, duration: 900.ms),
      const SizedBox(width: 10),
      Text('ITEC System Online', style: AppTheme.bodySmall.copyWith(color: AppTheme.primary)),
      const Spacer(),
      Text(DateFormat('HH:mm').format(DateTime.now()), style: AppTheme.label),
    ]),
  );
}
