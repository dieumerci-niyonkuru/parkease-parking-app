import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';

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
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        title: Text(widget.facility.fullParkName, style: AppTheme.heading4),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
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
                  if (_pricing != null)
                    _PricingCard(pricing: _pricing!)
                  else
                    Text('Standard rates apply: 500 RWF per hour.', style: AppTheme.body),
                  const SizedBox(height: 24),

                  // Categories Section
                  if (_categories.isNotEmpty) ...[
                    Text('VEHICLE CATEGORIES', style: AppTheme.label.copyWith(letterSpacing: 1.2, color: AppTheme.primary)),
                    const SizedBox(height: 12),
                    ..._categories.map((c) => _CategoryTile(category: c)),
                    const SizedBox(height: 24),
                  ],

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking confirmed!')));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Book Spot Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
      child: Column(children: [
        _PriceRow('Hourly Rate', '${pricing['rate'] ?? 500} RWF'),
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
