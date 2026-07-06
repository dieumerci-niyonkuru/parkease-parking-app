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
  List<dynamic> _fullTariffs = [];
  bool _loading = true;
  bool _showFullList = false;

  @override void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      ApiService.getPricing(widget.facility.recordId),
      ApiService.getCarCategories(widget.facility.dbId),
      ApiService.getTariffs(),
    ]);
    if (!mounted) return;
    setState(() {
      _pricing = results[0] as Map<String, dynamic>?;
      _categories = results[1] as List<dynamic>;
      _fullTariffs = results[2] as List<dynamic>;
      _loading = false;
    });
  }

  @override Widget build(BuildContext context) {
    final rate = _pricing != null 
        ? (double.tryParse(_pricing!['rate']?.toString() ?? widget.facility.ratePerHour.toString()) ?? widget.facility.ratePerHour)
        : widget.facility.ratePerHour;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: _loading
          ? const BrandedLoader(message: 'Loading real-time rates...')
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── SITE HEADER ───────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7F2), // Premium Cream
                      border: Border(bottom: BorderSide(color: AppTheme.primary.withOpacity(0.1))),
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
                          const Icon(Icons.directions_car_rounded, color: AppTheme.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('${widget.facility.parkingLots} parking spots available', 
                            style: AppTheme.bodySmall.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w800)),
                        ]),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 32),

                  // ── PRICING SECTION ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pricing Information', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF212529))),
                        const SizedBox(height: 24),

                        _CategoryPricingCard(
                          title: 'General',
                          rates: _pricing ?? {},
                          onViewFull: () => _showFullPriceList(context, rate),
                        ).animate().fadeIn(),

                        const SizedBox(height: 40),

                        // ── NAVIGATION ACTIONS ──────────────────────────
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final nav = Navigator.of(context);
                              if (nav.canPop()) {
                                nav.pop();
                              }
                            },
                            icon: const Text('🏠', style: TextStyle(fontSize: 18)),
                            label: const Text('BACK TO DASHBOARD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              side: const BorderSide(color: Colors.white24, width: 1.5),
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                        
                        // ── CONTACT FOOTER ──────────────────────────────
                        _AssistanceFooter(),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CategoryPricingCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> rates;
  final VoidCallback? onViewFull;
  const _CategoryPricingCard({required this.title, required this.rates, this.onViewFull});

  @override Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,###');
    
    // Reterive prices directly from API keys or use the 200 Frw example from user
    final rate = double.tryParse(rates['rate']?.toString() ?? '200') ?? 200.0;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF212529))),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 24),
          _PriceItem('1 Hours', '${moneyFmt.format(rate)}'),
          _PriceItem('2 Hours', '${moneyFmt.format(rate * 2)}'),
          _PriceItem('3 Hours', '${moneyFmt.format(rate * 3)}'),
          _PriceItem('4 Hours', '${moneyFmt.format(rate * 4)}'),
          _PriceItem('5 Hours', '${moneyFmt.format(rate * 5)}'),
          if (onViewFull != null) ...[
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: onViewFull,
                child: Text('View full price list', 
                  style: AppTheme.label.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _PriceItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF212529))),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF7A5B40))),
        ],
      ),
    );
  }
}

extension _ParkingDetailsExtra on _ParkingDetailsScreenState {
  Future<void> _showFullPriceList(BuildContext context, double rate) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Price List', style: TextStyle(fontWeight: FontWeight.w900)),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: _buildFullRateBreakdown(rate),
          ),
        ),
      ),
    );
  }

  Widget _buildFullRateBreakdown(double rate) {
    final moneyFmt = NumberFormat('#,###');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: List.generate(25, (i) {
          final double amount = i * rate;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(i == 0 ? '0-1 Hour' : '$i Hours', 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                Text('${moneyFmt.format(amount)}', 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF7A5B40))),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _AssistanceFooter extends StatelessWidget {
  @override Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.glowShadow,
      ),
      child: Column(
        children: [
          Text('GETTING ASSISTANCE', 
            style: AppTheme.label.copyWith(color: Colors.white, letterSpacing: 2, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          _FooterRow(Icons.phone_in_talk_rounded, 'Quick Call Us:', '+250 788 620 612'),
          const SizedBox(height: 14),
          _FooterRow(Icons.alternate_email_rounded, 'Mail Us On:', 'info@itec.rw'),
          const SizedBox(height: 14),
          _FooterRow(Icons.location_on_rounded, 'Visit Location:', 'KN 1 Rd 4, MUHIMA-Near Post Office\nP.O. Box 4179 KIGALI RWANDA'),
        ],
      ),
    );
  }

  Widget _FooterRow(IconData icon, String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(text, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}
