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
    final rate = _pricing != null 
        ? (double.tryParse(_pricing!['rate']?.toString() ?? '200') ?? 200.0)
        : widget.facility.ratePerHour;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: _loading
          ? const BrandedLoader(message: 'Loading rates...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── SITE HEADER ───────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7F2), // Matching the dashboard card color
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.facility.fullParkName.toUpperCase(), 
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF212529))),
                        const SizedBox(height: 12),
                        Row(children: [
                          const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(widget.facility.address, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700))),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
                          const SizedBox(width: 8),
                          Text('${widget.facility.parkingLots} parking spots available', 
                            style: AppTheme.bodySmall.copyWith(color: AppTheme.success, fontWeight: FontWeight.w800)),
                        ]),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 32),

                  // ── PRICING SECTION ───────────────────────────────
                  const Text('Pricing Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF212529))),
                  const SizedBox(height: 20),

                  _CategoryPricingCard(
                    title: 'Small Car',
                    rate: rate,
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

class _CategoryPricingCard extends StatelessWidget {
  final String title;
  final double rate;
  const _CategoryPricingCard({required this.title, required this.rate});

  @override Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,###');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF212529))),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 20),
          _PriceItem('First Hour', '${moneyFmt.format(rate)} Frw'),
          _PriceItem('Second Hour', '${moneyFmt.format(rate * 2)} Frw'),
          _PriceItem('Third Hour', '${moneyFmt.format(rate * 3)} Frw'),
          _PriceItem('Fifth Hour', '${moneyFmt.format((5 - 3) * (rate * 5))} Frw'), // Logic from API for 5h+
          _PriceItem('Full Day (24h)', '${moneyFmt.format((24 - 3) * (rate * 5))} Frw'),
          const SizedBox(height: 16),
          Center(
            child: Text('View full price list', 
              style: AppTheme.label.copyWith(color: const Color(0xFF7A5B40), fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _PriceItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF212529))),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF7A5B40))),
        ],
      ),
    );
  }
}
