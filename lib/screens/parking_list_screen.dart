import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class ParkingListScreen extends StatefulWidget {
  const ParkingListScreen({super.key});
  @override State<ParkingListScreen> createState() => _ParkingListScreenState();
}

class _ParkingListScreenState extends State<ParkingListScreen> {
  List<ParkingFacility> _all      = [];
  List<ParkingFacility> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override void initState()  { super.initState(); _load(); }
  @override void dispose()    { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ApiService.getAllParking();
    if (!mounted) return;
    setState(() { _all = list; _filtered = list; _loading = false; });
  }

  void _onSearch(String q) {
    final query = q.toLowerCase().trim();
    setState(() {
      _filtered = query.isEmpty
          ? _all
          : _all.where((f) =>
              f.fullParkName.toLowerCase().contains(query) ||
              f.address.toLowerCase().contains(query)).toList();
    });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              expandedHeight: 0,
              backgroundColor: AppTheme.bgDeep,
              automaticallyImplyLeading: false,
              title: Row(children: [
                const Icon(Icons.manage_search_rounded,
                    color: AppTheme.textSecond, size: 20),
                const SizedBox(width: 8),
                Text('Parking Locations', style: AppTheme.heading4),
              ]),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search mall or city...',
                      hintStyle:
                          AppTheme.body.copyWith(color: AppTheme.textHint),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.textMuted, size: 20),
                      filled: true,
                      fillColor: AppTheme.bgCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide:
                            const BorderSide(color: AppTheme.primary, width: 1.2),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                    ),
                  ),
                ),
              ),
            ),

            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else if (_filtered.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.search_off_rounded,
                        color: AppTheme.textHint, size: 64),
                    const SizedBox(height: 16),
                    Text('No parking locations found',
                        style: AppTheme.heading4
                            .copyWith(color: AppTheme.textMuted)),
                    const SizedBox(height: 8),
                    Text('Try a different search term', style: AppTheme.body),
                  ]),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    childAspectRatio: 3.2,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _ParkingTile(
                      facility: _filtered[i],
                    ).animate().fadeIn(delay: Duration(milliseconds: i * 40)).slideY(begin: 0.05),
                    childCount: _filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Parking Tile ──────────────────────────────────────────────────
class _ParkingTile extends StatelessWidget {
  final ParkingFacility facility;
  const _ParkingTile({required this.facility});

  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.bgCard,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      border: Border.all(color: AppTheme.border, width: 0.5),
      boxShadow: AppTheme.subtleShadow,
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  facility.fullParkName.toUpperCase(),
                  style: AppTheme.heading4.copyWith(fontSize: 12, letterSpacing: 0.2),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text('GENERAL PARK',
                  style: AppTheme.label.copyWith(color: AppTheme.textMuted, fontSize: 8)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.location_on_rounded, color: AppTheme.danger, size: 13),
            const SizedBox(width: 4),
            Expanded(
              child: Text(facility.address,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecond, fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.directions_car_outlined,
                color: AppTheme.textMuted, size: 13),
            const SizedBox(width: 4),
            Text('${facility.parkingLots} Slots',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecond, fontSize: 11)),
          ]),
        ],
      )),
    ]),
  );
}
