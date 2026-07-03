import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/app_utils.dart';
import '../widgets/branded_loader.dart';
import '../widgets/widgets.dart';
import 'package:intl/intl.dart';

class ParkingDetailsScreen extends StatefulWidget {
  final ParkingFacility facility;
  const ParkingDetailsScreen({super.key, required this.facility});

  @override State<ParkingDetailsScreen> createState() => _ParkingDetailsScreenState();
}

class _ParkingDetailsScreenState extends State<ParkingDetailsScreen> {
  Map<String, dynamic>? _pricing;
  List<dynamic> _categories = [];
  bool _loading = true;

  @override void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      ApiService.getPricing(widget.facility.recordId),
      ApiService.getCarCategories(widget.facility.dbId),
    ]);
    if (!mounted) return;
    setState(() {
      _pricing = results[0] as Map<String, dynamic>?;
      _categories = results[1] as List<dynamic>;
      _loading = false;
    });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: _loading
          ? const BrandedLoader(message: 'Loading rates...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.location_on_rounded, color: AppTheme.danger, size: 24),
                          const SizedBox(width: 12),
                          Expanded(child: Text(widget.facility.address, style: AppTheme.body)),
                        ]),
                        const SizedBox(height: 16),
                        Row(children: [
                          const Icon(Icons.directions_car_rounded, color: AppTheme.primary, size: 24),
                          const SizedBox(width: 12),
                          Text('${widget.facility.parkingLots} Available Slots', style: AppTheme.body.copyWith(fontWeight: FontWeight.w700)),
                        ]),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),
                  const SizedBox(height: 24),

                  // Pricing Section
                  Text('PRICING & RATES', style: AppTheme.label.copyWith(letterSpacing: 1.2, color: AppTheme.primary)),
                  const SizedBox(height: 12),
                  if (_pricing != null) ...[
                    _PricingCard(pricing: _pricing!),
                    const SizedBox(height: 16),
                  ],
                  _buildRateList(_pricing != null 
                    ? (double.tryParse(_pricing!['rate']?.toString() ?? '200') ?? 200.0)
                    : widget.facility.ratePerHour).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),

                  // Categories Section
                  if (_categories.isNotEmpty) ...[
                    Text('VEHICLE CATEGORIES', style: AppTheme.label.copyWith(letterSpacing: 1.2, color: AppTheme.primary)),
                    const SizedBox(height: 12),
                    ..._categories.map((c) => _CategoryTile(category: c)),
                    const SizedBox(height: 24),
                  ],

                  // Information Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Parking fees are automatically calculated based on your entry time. You can pay your fee using the Quick Pay Portal with your plate number.',
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary, height: 1.4),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final Map<String, dynamic> pricing;
  const _PricingCard({required this.pricing});

  @override Widget build(BuildContext context) {
    final rate = double.tryParse(pricing['rate']?.toString() ?? '200') ?? 200.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
      child: Column(children: [
        _PriceRow('Hourly Rate', '${rate.toInt()} RWF'),
        if (pricing['grace_period'] != null) _PriceRow('Grace Period', '${pricing['grace_period']} mins'),
        if (pricing['daily_max'] != null) _PriceRow('Daily Max', '${pricing['daily_max']} RWF'),
      ]),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  const _PriceRow(this.label, this.value);
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTheme.bodySmall),
      Text(value, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _CategoryTile extends StatelessWidget {
  final dynamic category;
  const _CategoryTile({required this.category});

  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border, width: 0.5)),
    child: Row(children: [
      const Icon(Icons.category_outlined, color: AppTheme.textMuted, size: 20),
      const SizedBox(width: 12),
      Text(category['name'] ?? 'General', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
      const Spacer(),
      if (category['multiplier'] != null)
        Text('x${category['multiplier']}', style: AppTheme.label.copyWith(color: AppTheme.accent)),
    ]),
  );
}

extension _ParkingDetailsExtra on _ParkingDetailsScreenState {
  Widget _buildRateList(double rate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RATE BREAKDOWN (24h)', style: AppTheme.label.copyWith(color: AppTheme.primary, letterSpacing: 1)),
              const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Table(
            children: [
              TableRow(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('Duration', style: AppTheme.label.copyWith(fontSize: 10))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('Fee (RWF)', style: AppTheme.label.copyWith(fontSize: 10), textAlign: TextAlign.right)),
                ],
              ),
              const TableRow(children: [Divider(), Divider()]),
              ...List.generate(25, (i) {
                final fee = AppUtils.calcAmount(Duration(hours: i), rate);
                return TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(i == 0 ? '0-1 Hour' : '$i Hours', style: AppTheme.bodySmall)),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(NumberFormat('#,###').format(fee), style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary), textAlign: TextAlign.right)),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
