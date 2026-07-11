import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/branded_loader.dart';
import '../widgets/pay_now_card.dart';

class ParkingListScreen extends StatefulWidget {
  const ParkingListScreen({super.key});
  @override State<ParkingListScreen> createState() => _ParkingListScreenState();
}

class _ParkingListScreenState extends State<ParkingListScreen> with SingleTickerProviderStateMixin {
  List<ParkingFacility> _all = [];
  bool _loading = true;

  // Pagination (All Sites tab)
  int _currentPage = 0;
  final int _pageSize = 5;

  late final TabController _tabController;

  @override void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ApiService.getAllParking();
    if (!mounted) return;
    setState(() {
      _all = list;
      _loading = false;
    });
  }

  @override Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final query = provider.searchQuery.toLowerCase().trim();
    final isSearching = provider.isSearchActive || query.isNotEmpty;

    final filtered = query.isEmpty
        ? _all
        : _all.where((f) =>
            f.fullParkName.toLowerCase().contains(query) ||
            f.address.toLowerCase().contains(query)).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Column(
        children: [
          // ── HEADER + SUB-TABS ───────────────────────────────
          if (!isSearching)
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Column(children: [
                      Text('PARKING SITE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF212529), letterSpacing: 1)),
                      SizedBox(height: 4),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text('National Management Portal'.toUpperCase(),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 2)),
                  ),
                  const SizedBox(height: 16),
                  // ── PAY NOW (compact) ────────────────────────────
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: PayNowCard(dense: true),
                  ),
                  const SizedBox(height: 14),
                  // ── SUB-TABS ─────────────────────────────────────
                  TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: AppTheme.textMuted,
                    indicatorColor: AppTheme.primary,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: const [
                      Tab(text: 'ALL SITES', icon: Icon(Icons.location_city_rounded, size: 18)),
                      Tab(text: 'RATES', icon: Icon(Icons.payments_rounded, size: 18)),
                    ],
                  ),
                ],
              ),
            ),

          // ── TAB CONTENT ─────────────────────────────────────
          Expanded(
            child: isSearching
                ? _AllSitesTab(
                    filtered: filtered,
                    loading: _loading,
                    currentPage: _currentPage,
                    pageSize: _pageSize,
                    onRefresh: _load,
                    onPageChanged: (p) => setState(() => _currentPage = p),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _AllSitesTab(
                        filtered: filtered,
                        loading: _loading,
                        currentPage: _currentPage,
                        pageSize: _pageSize,
                        onRefresh: _load,
                        onPageChanged: (p) => setState(() => _currentPage = p),
                      ),
                      _RatesTab(facilities: filtered, loading: _loading, onRefresh: _load),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── ALL SITES TAB ───────────────────────────────────────────────────
class _AllSitesTab extends StatelessWidget {
  final List<ParkingFacility> filtered;
  final bool loading;
  final int currentPage;
  final int pageSize;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onPageChanged;
  const _AllSitesTab({
    required this.filtered,
    required this.loading,
    required this.currentPage,
    required this.pageSize,
    required this.onRefresh,
    required this.onPageChanged,
  });

  @override Widget build(BuildContext context) {
    if (loading) return const BrandedLoader(message: 'Syncing facilities...');
    if (filtered.isEmpty) return const _EmptySearch();

    final totalPages = (filtered.length / pageSize).ceil();
    var page = currentPage;
    if (page >= totalPages && totalPages > 0) page = totalPages - 1;
    final start = page * pageSize;
    final end = (start + pageSize) > filtered.length ? filtered.length : (start + pageSize);
    final items = (start < filtered.length) ? filtered.sublist(start, end) : <ParkingFacility>[];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 2),
        child: Row(children: [
          Text('${filtered.length} ${filtered.length == 1 ? "SITE" : "SITES"} AVAILABLE',
            style: AppTheme.label.copyWith(fontWeight: FontWeight.w900, color: AppTheme.textMuted)),
          const Spacer(),
          Text('Tap for details', style: AppTheme.label.copyWith(fontSize: 9, color: AppTheme.textHint)),
        ]),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: AppTheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final f = items[i];
              return _ParkingSiteCard(
                facility: f,
                onTap: () => Navigator.of(context).pushNamed('parking_detail', arguments: f),
              ).animate().fadeIn(delay: Duration(milliseconds: i * 50)).slideX(begin: 0.05);
            },
          ),
        ),
      ),
      if (totalPages > 1)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PageButton(
                  label: 'BACK',
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: page > 0 ? () => onPageChanged(page - 1) : null,
                ),
                Text('PAGE ${page + 1} OF $totalPages',
                  style: AppTheme.label.copyWith(fontWeight: FontWeight.w900, color: AppTheme.primary)),
                _PageButton(
                  label: 'NEXT',
                  icon: Icons.arrow_forward_ios_rounded,
                  isReverse: true,
                  onPressed: (page + 1) < totalPages ? () => onPageChanged(page + 1) : null,
                ),
              ],
            ),
          ),
        ),
    ]);
  }
}

// ── RATES TAB ────────────────────────────────────────────────────────
// A quick per-hour rate reference across every site, sorted cheapest first.
// Full tiered pricing for a specific site is on its details page.
class _RatesTab extends StatelessWidget {
  final List<ParkingFacility> facilities;
  final bool loading;
  final Future<void> Function() onRefresh;
  const _RatesTab({required this.facilities, required this.loading, required this.onRefresh});

  @override Widget build(BuildContext context) {
    if (loading) return const BrandedLoader(message: 'Loading rates...');
    if (facilities.isEmpty) return const _EmptySearch();

    final sorted = [...facilities]..sort((a, b) => a.ratePerHour.compareTo(b.ratePerHour));
    final moneyFmt = NumberFormat('#,###');

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        itemCount: sorted.length,
        itemBuilder: (ctx, i) {
          final f = sorted[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: InkWell(
              onTap: () => Navigator.of(context).pushNamed('parking_detail', arguments: f),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.directions_car_rounded, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(f.fullParkName.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF212529))),
                    const SizedBox(height: 2),
                    Text('${f.parkingLots} spots available', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Frw ${moneyFmt.format(f.ratePerHour)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                  Text('per hour', style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: i * 40)).slideX(begin: 0.05);
        },
      ),
    );
  }
}

class _ParkingSiteCard extends StatelessWidget {
  final ParkingFacility facility;
  final VoidCallback onTap;
  const _ParkingSiteCard({required this.facility, required this.onTap});

  @override Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,###');
    final available = facility.parkingLots > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.directions_car_rounded, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(facility.fullParkName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF212529))),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.location_on_rounded, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(child: Text(facility.address, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600))),
                  ]),
                ]),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primary.withValues(alpha: 0.5), size: 14),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              _chip(Icons.payments_rounded, 'Frw ${moneyFmt.format(facility.ratePerHour)}/hr', AppTheme.primary),
              const SizedBox(width: 8),
              _chip(Icons.local_parking_rounded, available ? '${facility.parkingLots} spots' : 'Full',
                available ? AppTheme.success : AppTheme.textMuted),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 5),
      Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    ]),
  );
}

class _PageButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isReverse;

  const _PageButton({required this.label, required this.icon, this.onPressed, this.isReverse = false});

  @override Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: isReverse ? Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)) : Icon(icon, size: 14),
      label: isReverse ? Icon(icon, size: 14) : Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
      style: TextButton.styleFrom(
        foregroundColor: onPressed != null ? AppTheme.primary : Colors.grey.shade400,
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();
  @override Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.search_off_rounded, color: AppTheme.textHint.withValues(alpha: 0.3), size: 64),
      const SizedBox(height: 16),
      Text('No sites found.', style: AppTheme.heading4.copyWith(color: AppTheme.textMuted)),
    ]),
  );
}
