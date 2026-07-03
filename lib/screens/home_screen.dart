import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/phone_service.dart';
import '../services/profile_service.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/branded_loader.dart';
import 'plate_lookup_screen.dart';
import 'parking_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ParkingFacility> _facilities = [];
  List<PhoneNumber>     _phones     = [];
  bool _loading = true;
  bool _showStats = false;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final results = await Future.wait([
      ApiService.getAllParking(),
      PhoneService.getPhones(),
    ]);
    if (!mounted) return;
    setState(() {
      _facilities = results[0] as List<ParkingFacility>;
      _phones     = results[1] as List<PhoneNumber>;
      _loading    = false;
    });
  }

  @override Widget build(BuildContext context) {
    final user = AuthService.user;
    final firstName = user?.names.split(' ').first ?? 'Driver';
    final query = context.watch<AppProvider>().searchQuery;

    final displayFacilities = query.isEmpty 
      ? _facilities 
      : _facilities.where((f) => 
          f.fullParkName.toLowerCase().contains(query) || 
          f.address.toLowerCase().contains(query)).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: AppTheme.bgDeep, // Using the light grey background
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Welcome Back', 
                                style: AppTheme.heading1.copyWith(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF212529)),
                              ),
                              const SizedBox(width: 8),
                              const Text('👋', style: TextStyle(fontSize: 28)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            firstName.toLowerCase(), 
                            style: AppTheme.heading1.copyWith(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat("EEEE, d MMMM").format(DateTime.now()), 
                            style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    
                    // Vehicle Lookup Card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: const _QuickPayCard(),
                    ),
                  ],
                ),
              ),
            ),

            // ── MAIN CONTENT ─────────────────────────────────────
            SliverToBoxAdapter(
              child: _loading
                  ? const SizedBox(height: 300, child: BrandedLoader(message: 'Retrieving Parking Hubs...'))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const SizedBox(height: 24),
                        if (!ApiService.lastFetchSuccessful)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.warning.withOpacity(0.3))),
                            child: Row(children: [
                              const Icon(Icons.cloud_off_rounded, color: AppTheme.warning, size: 20),
                              const SizedBox(width: 12),
                              Expanded(child: Text('You are offline. Displaying saved parking hubs from your last visit.', style: AppTheme.label.copyWith(color: AppTheme.warning, fontWeight: FontWeight.bold))),
                            ]),
                          ).animate().fadeIn(),
                        
                        // ── Stats Header ─────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Parking Overview', style: AppTheme.heading3),
                            IconButton(
                              onPressed: () => setState(() => _showStats = !_showStats),
                              icon: Icon(_showStats ? Icons.insights_rounded : Icons.analytics_outlined, color: AppTheme.primary, size: 24),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),

                        // ── Stats (Conditional) ──────────────────────
                        if (_showStats) ...[
                          Row(children: [
                            Expanded(child: _StatCard(icon: Icons.phone_android_rounded, iconBg: AppTheme.primary, label: 'LINKED DEVICES', value: _phones.length.toString())),
                            const SizedBox(width: 16),
                            Expanded(child: _StatCard(icon: Icons.map_rounded, iconBg: AppTheme.success, label: 'PARKING HUBS', value: _facilities.length.toString())),
                          ]).animate().fadeIn().slideY(begin: 0.1),
                          const SizedBox(height: 32),
                        ],

                        Text('Parking Hubs', style: AppTheme.heading3),
                        const SizedBox(height: 16),

                        // ── List of Facilities ────────────────────────
                        AnimationLimiter(
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: displayFacilities.length,
                            itemBuilder: (context, index) {
                              final f = displayFacilities[index];
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: _ParkingHubCard(
                                      facility: f,
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ParkingDetailsScreen(facility: f))),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        if (displayFacilities.isEmpty)
                          const _EmptySearch().animate().fadeIn(),
                          
                        const SizedBox(height: 120), // Extra space for bottom nav
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
  const _QuickPayCard();
  @override State<_QuickPayCard> createState() => _QuickPayCardState();
}

class _QuickPayCardState extends State<_QuickPayCard> {
  final _ctrl = TextEditingController();
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.directions_car_rounded, color: AppTheme.primary, size: 24),
          const SizedBox(width: 12),
          Text('VEHICLE LOOKUP', style: AppTheme.label.copyWith(color: const Color(0xFF212529), fontWeight: FontWeight.w900, letterSpacing: 1)),
        ]),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgDeep,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              fontFamily: 'monospace', 
              fontSize: 22, 
              fontWeight: FontWeight.w900, 
              color: AppTheme.textPrimary,
              letterSpacing: 4,
            ),
            decoration: InputDecoration(
              hintText: 'RAC 001 A',
              hintStyle: TextStyle(
                fontFamily: 'monospace', 
                fontSize: 22, 
                color: AppTheme.textHint.withOpacity(0.5), 
                letterSpacing: 4,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12), 
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.border.withOpacity(0.4), borderRadius: BorderRadius.circular(8)),
                child: const Text('RW', style: TextStyle(color: AppTheme.textSecond, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 60,
          child: ElevatedButton(
            onPressed: () {
              final plate = _ctrl.text.trim().toUpperCase();
              if (plate.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => PlateLookupScreen(initialPlate: plate)));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('SEARCH & PAY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
          ),
        ),
      ]),
    );
  }
}

class _ParkingHubCard extends StatelessWidget {
  final ParkingFacility facility;
  final VoidCallback onTap;
  const _ParkingHubCard({required this.facility, required this.onTap});

  @override Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.bgDeep,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_city_rounded, color: AppTheme.textPrimary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(facility.fullParkName.toUpperCase(), 
                        style: AppTheme.heading4.copyWith(fontSize: 13, fontWeight: FontWeight.w800)),
                      Text(facility.address, 
                        style: AppTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${facility.ratePerHour.toInt()} RWF', 
                      style: AppTheme.heading4.copyWith(fontSize: 14)),
                    const Text('PER HOUR', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: AppTheme.success, size: 16),
                    const SizedBox(width: 6),
                    Text('${facility.parkingLots} slots', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                Text('VIEW RATES', style: AppTheme.label.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 10)),
              ],
            ),
          ],
        ),
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

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60),
    child: Center(
      child: Column(children: [
        Icon(Icons.search_off_rounded, color: AppTheme.textHint.withOpacity(0.3), size: 64),
        const SizedBox(height: 16),
        Text('No results found.', style: AppTheme.heading4.copyWith(color: AppTheme.textMuted)),
        const Text('Try a different search term.', style: TextStyle(fontSize: 12)),
      ]),
    ),
  );
}
