import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/phone_service.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/branded_loader.dart';

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

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override Widget build(BuildContext context) {
    final query = context.watch<AppProvider>().searchQuery;
    final user = AuthService.user;
    final firstName = user?.names.split(' ').first ?? 'Driver';

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
                color: AppTheme.bgDeep,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── WELCOME MESSAGE ─────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Welcome, $firstName',
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 4),
                    // Vehicle Lookup Card
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 16, 24, 20),
                      child: _QuickPayCard(),
                    ),
                  ],
                ),
              ),
            ),

            // ── MAIN CONTENT ─────────────────────────────────────
            SliverToBoxAdapter(
              child: _loading
                  ? const SizedBox(height: 300, child: BrandedLoader(message: 'Retrieving Parking Sites...'))
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
                            decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3))),
                            child: Row(children: [
                              const Icon(Icons.cloud_off_rounded, color: AppTheme.warning, size: 20),
                              const SizedBox(width: 12),
                              Expanded(child: Text('You are offline. Displaying saved parking sites from your last visit.', style: AppTheme.label.copyWith(color: AppTheme.warning, fontWeight: FontWeight.bold))),
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
                            Expanded(child: _StatCard(icon: Icons.map_rounded, iconBg: AppTheme.success, label: 'PARKING SITES', value: _facilities.length.toString())),
                          ]).animate().fadeIn().slideY(begin: 0.1),
                          const SizedBox(height: 32),
                        ],

                        const Text('Parking Sites', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF212529))),
                        const SizedBox(height: 16),

                        // ── List of Facilities ────────────────────────
                        ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayFacilities.length,
                          itemBuilder: (context, index) {
                            final f = displayFacilities[index];
                            return _ParkingHubCard(
                              facility: f,
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  'parking_detail',
                                  arguments: f,
                                );
                              },
                            ).animate().fadeIn(
                              delay: Duration(milliseconds: index * 50),
                            ).slideY(begin: 0.1);
                            },
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
  static const _recentKey = 'recent_plates_v1';
  List<String> _recent = [];

  @override void initState() { super.initState(); _loadRecent(); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _recent = prefs.getStringList(_recentKey) ?? []);
  }

  Future<void> _saveRecent(String plate) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_recentKey) ?? [];
    list.remove(plate);          // move to front if it already exists
    list.insert(0, plate);
    final trimmed = list.take(4).toList(); // keep the 4 most recent
    await prefs.setStringList(_recentKey, trimmed);
    if (mounted) setState(() => _recent = trimmed);
  }

  void _search([String? preset]) {
    final plate = (preset ?? _ctrl.text).trim().toUpperCase();
    if (plate.isEmpty) return;
    _saveRecent(plate);
    Navigator.of(context).pushNamed('plate_lookup', arguments: plate);
  }

  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.directions_car_rounded, color: Color(0xFF7A5B40), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text('Check Parking Fees', style: TextStyle(color: Color(0xFF212529), fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ]),
        const SizedBox(height: 6),
        Text('Enter your vehicle plate number to see and pay parking charges instantly.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500, height: 1.35)),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _search(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF212529),
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: 'RAC 001 A',
              hintStyle: TextStyle(
                fontSize: 20,
                color: Colors.grey.shade400, // Brighter for better readability
                letterSpacing: 2,
              ),
              border: InputBorder.none,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text('🔍', style: TextStyle(fontSize: 20)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: _ctrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.grey.shade500, size: 20),
                      onPressed: () => setState(() => _ctrl.clear()),
                      tooltip: 'Clear',
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton(
            onPressed: _search,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('SEARCH & PAY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
          ),
        ),

        // ── RECENT PLATES ───────────────────────────────────
        if (_recent.isNotEmpty) ...[
          const SizedBox(height: 18),
          Row(children: [
            Icon(Icons.history_rounded, size: 15, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text('RECENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1)),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _recent.map((plate) => GestureDetector(
              onTap: () => _search(plate),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.directions_car_rounded, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(plate, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1)),
                ]),
              ),
            )).toList(),
          ),
        ],
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7F2), // Light peach/cream from mockup
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car_rounded, color: AppTheme.primary, size: 24),
                const SizedBox(width: 14),
                const Text('Parking Site', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF212529))),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted.withValues(alpha: 0.5), size: 16),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 16),
            _mockupRow('Parking Site', facility.fullParkName.toUpperCase()),
            _mockupRow('Location', facility.address),
            _mockupRow('Available Spots', facility.parkingLots.toString(), isHighlight: true),
          ],
        ),
      ),
    );
  }

  Widget _mockupRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              value, 
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.w800, 
                color: isHighlight ? const Color(0xFF7A5B40) : Colors.grey.shade800,
              ),
            ),
          ),
        ],
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
        Icon(Icons.search_off_rounded, color: AppTheme.textHint.withValues(alpha: 0.3), size: 64),
        const SizedBox(height: 16),
        Text('No results found.', style: AppTheme.heading4.copyWith(color: AppTheme.textMuted)),
        const Text('Try a different search term.', style: TextStyle(fontSize: 12)),
      ]),
    ),
  );
}
