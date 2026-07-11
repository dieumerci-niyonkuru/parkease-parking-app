import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/phone_service.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/branded_loader.dart';
import '../widgets/pay_now_card.dart';
import 'phone_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;
  const HomeScreen({super.key, this.onNavigateToTab});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ParkingFacility> _facilities = [];
  List<PhoneNumber>     _phones     = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override void initState() { super.initState(); _load(); }

  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

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
                          const Text('ITEC Parking',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    // ── INLINE SEARCH FIELD ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(children: [
                          const SizedBox(width: 14),
                          Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, letterSpacing: 0.5),
                              decoration: InputDecoration(
                                hintText: 'Search parking sites...',
                                hintStyle: TextStyle(color: AppTheme.textHint, fontSize: 13, fontWeight: FontWeight.w500),
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
                              child: const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 18),
                              ),
                            ),
                        ]),
                      ),
                    ).animate().fadeIn(delay: 120.ms),
                    const SizedBox(height: 4),
                    // ── PAY NOW HERO ─────────────────────────────
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 12, 24, 16),
                      child: PayNowCard(),
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
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
                        
                        // ── OVERVIEW STATS (always visible) ──────────
                        Text('Overview', style: AppTheme.heading3),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: GestureDetector(
                            onTap: () => widget.onNavigateToTab?.call(1),
                            child: _StatCard(icon: Icons.local_parking_rounded, iconBg: AppTheme.primary, label: 'PARKING SITES', value: _facilities.length.toString()),
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneScreen())),
                            child: _StatCard(icon: Icons.phone_android_rounded, iconBg: AppTheme.success, label: 'LINKED PHONES', value: _phones.length.toString()),
                          )),
                        ]).animate().fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 28),

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
      Row(children: [
        Icon(icon, color: iconBg, size: 24),
        const Spacer(),
        Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted.withValues(alpha: 0.4), size: 12),
      ]),
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
