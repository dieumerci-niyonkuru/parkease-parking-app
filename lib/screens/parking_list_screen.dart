import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

enum _SiteSort { recommended, mostAvailable, cheapest, nameAZ }

class _ParkingListScreenState extends State<ParkingListScreen> with SingleTickerProviderStateMixin {
  List<ParkingFacility> _all = [];
  bool _loading = true;
  _SiteSort _sort = _SiteSort.recommended;

  // Pagination (All Sites tab)
  int _currentPage = 0;
  final int _pageSize = 5;

  void _changeSort(_SiteSort s) => setState(() { _sort = s; _currentPage = 0; });

  List<ParkingFacility> _applySort(List<ParkingFacility> list) {
    final sorted = [...list];
    switch (_sort) {
      case _SiteSort.recommended:
        break; // keep API order
      case _SiteSort.mostAvailable:
        sorted.sort((a, b) => b.parkingLots.compareTo(a.parkingLots));
      case _SiteSort.cheapest:
        sorted.sort((a, b) => a.ratePerHour.compareTo(b.ratePerHour));
      case _SiteSort.nameAZ:
        sorted.sort((a, b) => a.fullParkName.toLowerCase().compareTo(b.fullParkName.toLowerCase()));
    }
    return sorted;
  }

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

    final matched = query.isEmpty
        ? _all
        : _all.where((f) =>
            f.fullParkName.toLowerCase().contains(query) ||
            f.address.toLowerCase().contains(query)).toList();
    final filtered = _applySort(matched);

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
                    child: Text('Find and pay for parking near you'.toUpperCase(),
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
                      Tab(text: 'ALL SITES', icon: Icon(Icons.directions_car_rounded, size: 18)),
                      Tab(text: 'BROWSE', icon: Icon(Icons.local_parking_rounded, size: 18)),
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
                    sort: _sort,
                    onSortChanged: _changeSort,
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
                        sort: _sort,
                        onSortChanged: _changeSort,
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
  final _SiteSort sort;
  final ValueChanged<_SiteSort> onSortChanged;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onPageChanged;
  const _AllSitesTab({
    required this.filtered,
    required this.loading,
    required this.currentPage,
    required this.pageSize,
    required this.sort,
    required this.onSortChanged,
    required this.onRefresh,
    required this.onPageChanged,
  });

  @override Widget build(BuildContext context) {
    if (loading) return const BrandedLoader(message: 'Loading parking sites...');
    if (filtered.isEmpty) return const _EmptySearch();

    final totalPages = (filtered.length / pageSize).ceil();
    var page = currentPage;
    if (page >= totalPages && totalPages > 0) page = totalPages - 1;
    final start = page * pageSize;
    final end = (start + pageSize) > filtered.length ? filtered.length : (start + pageSize);
    final items = (start < filtered.length) ? filtered.sublist(start, end) : <ParkingFacility>[];

    return Column(children: [
      // ── SORT / FILTER CHIPS ─────────────────────────────
      SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          children: [
            _SortChip(label: 'Recommended', active: sort == _SiteSort.recommended, onTap: () => onSortChanged(_SiteSort.recommended)),
            _SortChip(label: 'Most Available', icon: Icons.local_parking_rounded, active: sort == _SiteSort.mostAvailable, onTap: () => onSortChanged(_SiteSort.mostAvailable)),
            _SortChip(label: 'Cheapest', icon: Icons.payments_rounded, active: sort == _SiteSort.cheapest, onTap: () => onSortChanged(_SiteSort.cheapest)),
            _SortChip(label: 'Name A–Z', icon: Icons.sort_by_alpha_rounded, active: sort == _SiteSort.nameAZ, onTap: () => onSortChanged(_SiteSort.nameAZ)),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 2),
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

    final sorted = [...facilities]..sort((a, b) => a.fullParkName.compareTo(b.fullParkName));

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        itemCount: sorted.length,
        itemBuilder: (ctx, i) {
          final f = sorted[i];
          final available = f.parkingLots > 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.directions_car_rounded, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(f.fullParkName.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF212529))),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.local_parking_rounded, size: 12, color: available ? AppTheme.success : AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(available ? '${f.parkingLots} spots available' : 'Full',
                        style: TextStyle(fontSize: 11, color: available ? Colors.grey.shade600 : AppTheme.textMuted, fontWeight: FontWeight.w600)),
                    ]),
                  ]),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primary.withValues(alpha: 0.4), size: 14),
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
              _chip(Icons.local_parking_rounded, available ? '${facility.parkingLots} spots available' : 'Full',
                available ? AppTheme.success : AppTheme.textMuted),
              const SizedBox(width: 8),
              _chip(Icons.touch_app_rounded, 'Tap for rates & details', AppTheme.primary),
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

class _SortChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;
  const _SortChip({required this.label, this.icon, required this.active, required this.onTap});

  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppTheme.primary : AppTheme.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: active ? Colors.white : AppTheme.textMuted),
            const SizedBox(width: 5),
          ],
          Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w800,
            color: active ? Colors.white : AppTheme.textSecond,
          )),
        ]),
      ),
    ),
  );
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
