import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';

// Opens the price list as a draggable bottom sheet (rises from the bottom to
// most of the screen; the list scrolls inside it). Preferred over a full page.
void showPriceListSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PriceListSheet(),
  );
}

Future<List<_FacilityPricing>> _loadPricing() async {
  final list = await ApiService.getAllParking();
  final pricingResults = await Future.wait(list.map((f) => ApiService.getPricingData(f.recordId)));
  return [
    for (var i = 0; i < list.length; i++)
      _FacilityPricing(
        facility: list[i],
        hourlyRate: pricingResults[i]?.ratePerHour ?? list[i].ratePerHour,
        dailyRate: pricingResults[i]?.ratePerDay,
      ),
  ];
}

// ── BOTTOM SHEET ─────────────────────────────────────────────────────
class _PriceListSheet extends StatefulWidget {
  const _PriceListSheet();
  @override State<_PriceListSheet> createState() => _PriceListSheetState();
}

class _PriceListSheetState extends State<_PriceListSheet> {
  List<_FacilityPricing> _data = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final data = await _loadPricing();
    if (!mounted) return;
    setState(() { _data = data; _loading = false; });
  }

  @override Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,###');
    final q = _query.toLowerCase().trim();
    final filtered = q.isEmpty
        ? _data
        : _data.where((d) =>
            d.facility.fullParkName.toLowerCase().contains(q) ||
            d.facility.address.toLowerCase().contains(q)).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.bgDeep,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 16, 0),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Parking Rates', style: AppTheme.heading3.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text('Official rates across all ITEC sites', style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted)),
                ]),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // ── PROFESSIONAL SEARCH FIELD ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SearchField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              onClear: () => setState(() { _searchCtrl.clear(); _query = ''; }),
            ),
          ),
          const SizedBox(height: 12),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : filtered.isEmpty
                    ? _EmptyRates(query: _query)
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        children: [
                          ...filtered.asMap().entries.map((e) =>
                            _priceRowWidget(e.value, moneyFmt).animate().fadeIn(delay: Duration(milliseconds: (e.key % 8) * 30))),
                          const SizedBox(height: 4),
                          _infoBoxWidget(),
                        ],
                      ),
          ),
        ]),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchField({required this.controller, required this.onChanged, required this.onClear});

  @override Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: AppTheme.bgCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border),
    ),
    child: Row(children: [
      const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
      const SizedBox(width: 10),
      Expanded(
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: AppTheme.body.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search mall or city...',
            hintStyle: AppTheme.body.copyWith(color: AppTheme.textHint, fontSize: 14),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
      if (controller.text.isNotEmpty)
        GestureDetector(onTap: onClear, child: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 18)),
    ]),
  );
}

class _EmptyRates extends StatelessWidget {
  final String query;
  const _EmptyRates({required this.query});
  @override Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.search_off_rounded, color: AppTheme.textHint.withValues(alpha: 0.4), size: 56),
      const SizedBox(height: 12),
      Text(query.isEmpty ? 'No rates available.' : 'No sites match "$query".',
        style: AppTheme.heading4.copyWith(color: AppTheme.textMuted)),
    ]),
  );
}

// ── FULL-SCREEN VERSION (kept for direct navigation if needed) ────────
class ParkingCostsScreen extends StatefulWidget {
  const ParkingCostsScreen({super.key});
  @override State<ParkingCostsScreen> createState() => _ParkingCostsScreenState();
}

class _ParkingCostsScreenState extends State<ParkingCostsScreen> {
  List<_FacilityPricing> _data = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _loadPricing();
    if (!mounted) return;
    setState(() { _data = data; _loading = false; });
  }

  @override Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,###');
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        elevation: 0,
        title: Text('PARKING RATES', style: AppTheme.heading4.copyWith(letterSpacing: 1.2, color: AppTheme.primary)),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary, size: 20),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                children: [
                  ..._data.map((d) => _priceRowWidget(d, moneyFmt)),
                  const SizedBox(height: 8),
                  _infoBoxWidget(),
                ],
              ),
            ),
    );
  }
}

// ── SHARED ROW / INFO (top-level so the sheet and page reuse them) ────
// A price row styled like the "Getting Assistance" contact card.
Widget _priceRowWidget(_FacilityPricing d, NumberFormat moneyFmt) => Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppTheme.bgCard,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
    boxShadow: AppTheme.subtleShadow,
  ),
  child: Row(children: [
    Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
      child: const Icon(Icons.local_parking_rounded, size: 22, color: AppTheme.primary),
    ),
    const SizedBox(width: 14),
    Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(d.facility.fullParkName.toUpperCase(), maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, height: 1.2)),
        const SizedBox(height: 3),
        Text(d.dailyRate != null ? 'Hourly & daily rates' : 'Standard hourly rate',
          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
      ]),
    ),
    const SizedBox(width: 10),
    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text('Frw ${moneyFmt.format(d.hourlyRate.toInt())}',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.primary)),
      const Text('per hour', style: TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
      if (d.dailyRate != null) ...[
        const SizedBox(height: 4),
        Text('Frw ${moneyFmt.format(d.dailyRate!.toInt())}/day',
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecond, fontWeight: FontWeight.w700)),
      ],
    ]),
  ]),
);

Widget _infoBoxWidget() => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppTheme.primary.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
  ),
  child: Row(children: [
    const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
    const SizedBox(width: 12),
    Expanded(child: Text('Rates are set by the facility management and include all applicable taxes. Data sourced from the ITEC Central Pricing Database.', style: AppTheme.label.copyWith(fontSize: 10, color: AppTheme.textSecond))),
  ]),
);

class _FacilityPricing {
  final ParkingFacility facility;
  final double hourlyRate;
  final double? dailyRate;
  const _FacilityPricing({required this.facility, required this.hourlyRate, this.dailyRate});
}
