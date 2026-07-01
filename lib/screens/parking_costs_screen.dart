import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class ParkingCostsScreen extends StatefulWidget {
  const ParkingCostsScreen({super.key});
  @override State<ParkingCostsScreen> createState() => _ParkingCostsScreenState();
}

class _ParkingCostsScreenState extends State<ParkingCostsScreen> {
  List<ParkingFacility> _facilities = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ApiService.getAllParking();
    if (!mounted) return;
    setState(() { _facilities = list; _loading = false; });
  }

  @override Widget build(BuildContext context) {
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
                  Text('Hourly rates for all ITEC-enabled parking facilities across Rwanda.', style: AppTheme.bodySmall),
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
                              1: FlexColumnWidth(2),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1)),
                                children: [
                                  _HeaderCell('FACILITY'),
                                  _HeaderCell('COST / HOUR', align: TextAlign.right),
                                ],
                              ),
                              ..._facilities.map((f) => TableRow(
                                children: [
                                  _DataCell(f.fullParkName),
                                  _DataCell('${f.ratePerHour.toInt()} RWF', align: TextAlign.right, isBold: true),
                                ],
                              )),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.05),
                  ),
                  const SizedBox(height: 20),
                  _InfoBox(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _HeaderCell(String text, {TextAlign align = TextAlign.left}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Text(text, style: AppTheme.label.copyWith(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 10, letterSpacing: 1)),
  );

  Widget _DataCell(String text, {TextAlign align = TextAlign.left, bool isBold = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    child: Text(text, textAlign: align, style: AppTheme.body.copyWith(
      fontSize: 13, 
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
      color: isBold ? AppTheme.primary : AppTheme.textPrimary,
    )),
  );

  Widget _InfoBox() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.primary.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text('Rates are set by the facility management and include all applicable taxes.', style: AppTheme.label.copyWith(fontSize: 10, color: AppTheme.textSecond))),
    ]),
  );
}
