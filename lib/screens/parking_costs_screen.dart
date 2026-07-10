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
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Standard Rates', style: AppTheme.heading2),
                  const SizedBox(height: 8),
                  Text('Official hourly rates for all ITEC-enabled parking facilities across Rwanda.', style: AppTheme.bodySmall),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SingleChildScrollView(
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(3),
                              1: FlexColumnWidth(1),
                              2: FlexColumnWidth(1),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1)),
                                children: [
                                  _headerCell('FACILITY'),
                                  _headerCell('RATE/HR', align: TextAlign.right),
                                  _headerCell('RATE/DAY', align: TextAlign.right),
                                ],
                              ),
                              ..._data.map((d) => TableRow(
                                children: [
                                  _dataCell(d.facility.fullParkName),
                                  _dataCell('${moneyFmt.format(d.hourlyRate.toInt())} RWF', align: TextAlign.right, isBold: true),
                                  _dataCell(d.dailyRate != null ? '${moneyFmt.format(d.dailyRate!.toInt())} RWF' : '—', align: TextAlign.right),
                                ],
                              )),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.05),
                  ),
                  const SizedBox(height: 20),
                  _infoBox(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _headerCell(String text, {TextAlign align = TextAlign.left}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Text(text, style: AppTheme.label.copyWith(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 10, letterSpacing: 1)),
  );

  Widget _dataCell(String text, {TextAlign align = TextAlign.left, bool isBold = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    child: Text(text, textAlign: align, style: AppTheme.body.copyWith(
      fontSize: 13,
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
      color: isBold ? AppTheme.primary : AppTheme.textPrimary,
    )),
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
