import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/phone_service.dart';
import '../models/models.dart';
import 'plate_lookup_screen.dart';
import 'parking_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ParkingFacility> _facilities = [];
  List<ParkingFacility> _filtered   = [];
  List<PhoneNumber>     _phones     = [];
  bool _loading = true;
  bool _showStats = false;
  final _searchCtrl = TextEditingController();

  @override void initState() { super.initState(); _load(); }
  @override void dispose()   { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final results = await Future.wait([
      ApiService.getAllParking(),
      PhoneService.getPhones(),
    ]);
    if (!mounted) return;
    setState(() {
      _facilities = results[0] as List<ParkingFacility>;
      _filtered   = _facilities;
      _phones     = results[1] as List<PhoneNumber>;
      _loading    = false;
    });
  }

  void _search(String q) {
    final query = q.toLowerCase().trim();
    setState(() {
      _filtered = query.isEmpty
          ? _facilities
          : _facilities.where((f) =>
              f.fullParkName.toLowerCase().contains(query) ||
              f.address.toLowerCase().contains(query)).toList();
    });
  }

  String get _primaryPhone {
    if (_phones.isEmpty) return '—';
    final primary = _phones.where((p) => p.isPrimary).firstOrNull;
    return (primary ?? _phones.first).phone;
  }

  void _bookFacility(ParkingFacility f) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 28),
          const SizedBox(width: 12),
          Text('Reserve Spot', style: AppTheme.heading3),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Facility: ${f.fullParkName}', style: AppTheme.body.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('Location: ${f.address}', style: AppTheme.bodySmall),
            const SizedBox(height: 16),
            const Text('Confirm reservation for your current session?', style: TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: AppTheme.label.copyWith(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Reservation confirmed at ${f.fullParkName}!'),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, elevation: 0),
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }

  @override Widget build(BuildContext context) {
    final user = AuthService.user;
    final firstName = user?.names.split(' ').first ?? 'Driver';

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Premium App Bar ──────────────────────────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: 0,
              backgroundColor: AppTheme.bgDeep,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              title: Row(children: [
                Hero(
                  tag: 'logo',
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGrad,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppTheme.glowShadow,
                    ),
                    child: const Icon(Icons.local_parking_rounded, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ITEC PARKING', style: AppTheme.heading4.copyWith(fontSize: 14, letterSpacing: 1.2, color: AppTheme.primary)),
                  Text('RWANDA NATIONAL PORTAL', style: AppTheme.label.copyWith(fontSize: 9, letterSpacing: 0.5)),
                ]),
              ]),
              actions: [
                IconButton(
                  onPressed: () => setState(() => _showStats = !_showStats),
                  icon: Icon(_showStats ? Icons.insights_rounded : Icons.analytics_outlined, color: AppTheme.primary, size: 24),
                  tooltip: 'Analytics',
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverToBoxAdapter(
              child: _loading
                  ? const SizedBox(height: 500, child: Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3)))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const SizedBox(height: 16),
                        // ── Greeting ─────────────────────────────────
                        Text('Hello, $firstName!', style: AppTheme.heading1).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                        const SizedBox(height: 4),
                        Text(DateFormat("EEEE, d MMMM yyyy").format(DateTime.now()), style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted)).animate().fadeIn(delay: 100.ms),
                        
                        const SizedBox(height: 28),

                        // ── THE HERO CARD: QUICK PAY ──────────────────
                        _QuickPayCard().animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),
                        
                        const SizedBox(height: 28),

                        // ── Stats (Conditional) ──────────────────────
                        if (_showStats) ...[
                          Row(children: [
                            Expanded(child: _StatCard(icon: Icons.phone_android_rounded, iconBg: AppTheme.primary, label: 'LINKED DEVICES', value: _phones.length.toString())),
                            const SizedBox(width: 16),
                            Expanded(child: _StatCard(icon: Icons.map_rounded, iconBg: AppTheme.success, label: 'PARKING HUBS', value: _facilities.length.toString())),
                          ]).animate().fadeIn().slideY(begin: 0.1),
                          const SizedBox(height: 32),
                        ],

                        // ── Search & Filter Row ──────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Parking Hubs', style: AppTheme.heading3),
                            _InlineSearch(controller: _searchCtrl, onChanged: _search),
                          ],
                        ).animate().fadeIn(delay: 300.ms),
                        
                        const SizedBox(height: 16),

                        // ── List of Facilities ────────────────────────
                        AnimationLimiter(
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final f = _filtered[index];
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: _ParkingHubCard(
                                      facility: f,
                                      onBook: () => _bookFacility(f),
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ParkingDetailsScreen(facility: f))),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        if (_filtered.isEmpty)
                          _EmptySearch().animate().fadeIn(),
                          
                        const SizedBox(height: 100), // Extra space for bottom nav
                      ]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CUSTOM WIDGETS ──────────────────────────────────────────────────

class _QuickPayCard extends StatefulWidget {
  @override State<_QuickPayCard> createState() => _QuickPayCardState();
}

class _QuickPayCardState extends State<_QuickPayCard> {
  final _ctrl = TextEditingController();
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D2018), Color(0xFF1A120D)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        boxShadow: AppTheme.glowShadow,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.bolt_rounded, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Quick Pay Portal', style: AppTheme.heading3.copyWith(color: Colors.white, fontSize: 18)),
            Text('Fast vehicle lookup & payment', style: AppTheme.bodySmall.copyWith(color: Colors.white60)),
          ]),
        ]),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 4),
            decoration: InputDecoration(
              hintText: 'RAC 001 A',
              hintStyle: TextStyle(fontFamily: 'monospace', fontSize: 20, color: Colors.white.withOpacity(0.2), letterSpacing: 4),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: const Text('RW', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton(
            onPressed: () {
              final plate = _ctrl.text.trim().toUpperCase();
              if (plate.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => PlateLookupScreen(initialPlate: plate)));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5),
            ),
            child: const Text('SEARCH & PAY NOW'),
          ),
        ),
      ]),
    );
  }
}

class _ParkingHubCard extends StatelessWidget {
  final ParkingFacility facility;
  final VoidCallback onBook;
  final VoidCallback onTap;
  const _ParkingHubCard({required this.facility, required this.onBook, required this.onTap});

  @override Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border.withOpacity(0.5)),
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppTheme.bgDeep, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.location_city_rounded, color: AppTheme.textSecond, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(facility.fullParkName.toUpperCase(), style: AppTheme.heading4.copyWith(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.place_rounded, color: AppTheme.danger, size: 12),
                const SizedBox(width: 4),
                Expanded(child: Text(facility.address, style: AppTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${facility.ratePerHour.toInt()} RWF', style: AppTheme.heading4.copyWith(color: AppTheme.primary, fontSize: 14)),
              const Text('PER HOUR', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
            ]),
          ]),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              const Icon(Icons.airline_seat_recline_extra_rounded, color: AppTheme.success, size: 18),
              const SizedBox(width: 6),
              Text('${facility.parkingLots} Slots Available', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecond, fontWeight: FontWeight.w600)),
            ]),
            ElevatedButton(
              onPressed: onBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.bgDeep, foregroundColor: AppTheme.primary,
                elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppTheme.primary, width: 0.5)),
              ),
              child: const Text('BOOK NOW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label, value;
  const _StatCard({required this.icon, required this.iconBg, required this.label, required this.value});

  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.subtleShadow),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: iconBg, size: 24),
      const SizedBox(height: 14),
      Text(value, style: AppTheme.heading2.copyWith(fontSize: 24, color: AppTheme.textPrimary)),
      const SizedBox(height: 4),
      Text(label, style: AppTheme.label.copyWith(fontSize: 9, color: AppTheme.textMuted)),
    ]),
  );
}

class _InlineSearch extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _InlineSearch({required this.controller, required this.onChanged});

  @override Widget build(BuildContext context) => SizedBox(
    width: 140, height: 38,
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search Site...',
        hintStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textHint),
        prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppTheme.textMuted),
        filled: true, fillColor: AppTheme.bgCard, isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 1)),
      ),
    ),
  );
}

class _EmptySearch extends StatelessWidget {
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60),
    child: Center(
      child: Column(children: [
        Icon(Icons.search_off_rounded, color: AppTheme.textHint.withOpacity(0.5), size: 64),
        const SizedBox(height: 16),
        Text('No results found.', style: AppTheme.heading4.copyWith(color: AppTheme.textMuted)),
        const Text('Try a different parking site.', style: TextStyle(fontSize: 12)),
      ]),
    ),
  );
}
