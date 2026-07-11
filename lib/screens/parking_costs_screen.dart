import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';

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
    final list = await ApiService.getAllParking();
    final results = <_FacilityPricing>[];
    final pricingFutures = list.map((f) => ApiService.getPricingData(f.recordId)).toList();
    final pricingResults = await Future.wait(pricingFutures);
    for (var i = 0; i < list.length; i++) {
      final pricing = pricingResults[i];
      results.add(_FacilityPricing(
        facility: list[i],
        hourlyRate: pricing?.ratePerHour ?? list[i].ratePerHour,
        dailyRate: pricing?.ratePerDay,
      ));
    }
    if (!mounted) return;
    setState(() { _data = results; _loading = false; });
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
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary, size: 22),
            tooltip: 'Refresh Rates',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Standard Rates', style: AppTheme.heading2),
                      const SizedBox(height: 8),
                      Text('Official hourly rates for all ITEC-enabled parking facilities across Rwanda.', style: AppTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    color: AppTheme.primary,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      children: [
                        ..._data.asMap().entries.map((e) =>
                          _priceRow(e.value, moneyFmt).animate().fadeIn(delay: Duration(milliseconds: e.key * 40)).slideY(begin: 0.05)),
                        const SizedBox(height: 8),
                        _infoBox(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // A price row styled like the "Getting Assistance" contact card:
  // rounded icon badge + facility name + the rate value.
  Widget _priceRow(_FacilityPricing d, NumberFormat moneyFmt) => Container(
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

  Widget _infoBox() => Container(
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
}

class _FacilityPricing {
  final ParkingFacility facility;
  final double hourlyRate;
  final double? dailyRate;
  const _FacilityPricing({required this.facility, required this.hourlyRate, this.dailyRate});
}
