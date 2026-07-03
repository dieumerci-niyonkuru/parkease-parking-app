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
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 4,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.facility.fullParkName.toUpperCase(), 
          style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
      ),
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
                          const Icon(Icons.local_parking_rounded, color: AppTheme.primary, size: 18),
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

                        // Dynamically build cards for each category from the API
                        if (_categories.isEmpty)
                          _CategoryPricingCard(
                          title: 'General',
                          rates: _pricing ?? {},
                          onViewFull: () => setState(() => _showFullList = !_showFullList),
                        ).animate().fadeIn()
                        else
                          ..._categories.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _CategoryPricingCard(
                              title: c['name'] ?? 'Vehicle',
                              rates: c,
                              onViewFull: () => setState(() => _showFullList = !_showFullList),
                            ).animate().fadeIn(delay: 200.ms),
                          )),

                        if (_showFullList && _fullTariffs.isNotEmpty) ...[
                          const Divider(height: 48),
                          const Text('Comprehensive Price List', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF212529))),
                          const SizedBox(height: 16),
                          ..._fullTariffs.map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CategoryPricingCard(
                              title: t['parking_name'] ?? t['name'] ?? 'Other Site',
                              rates: t,
                            ),
                          )),
                        ],

                        const SizedBox(height: 40),

                        // ── NAVIGATION ACTIONS ──────────────────────────
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                            icon: const Icon(Icons.dashboard_rounded, color: Colors.white),
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
    
    // Reterive prices directly from API keys
    final p1 = double.tryParse(rates['first_hour']?.toString() ?? rates['rate']?.toString() ?? '300') ?? 300.0;
    final p2 = double.tryParse(rates['second_hour']?.toString() ?? (p1 * 1.6).toString()) ?? 500.0;
    final p3 = double.tryParse(rates['third_hour']?.toString() ?? (p1 * 2.3).toString()) ?? 700.0;
    final p5 = double.tryParse(rates['fifth_hour']?.toString() ?? '2000') ?? 2000.0;
    final pd = double.tryParse(rates['full_day']?.toString() ?? rates['daily_max']?.toString() ?? '20000') ?? 20000.0;

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
          _PriceItem('First Hour', '${moneyFmt.format(p1)} Frw'),
          _PriceItem('Second Hour', '${moneyFmt.format(p2)} Frw'),
          _PriceItem('Third Hour', '${moneyFmt.format(p3)} Frw'),
          _PriceItem('Fifth Hour', '${moneyFmt.format(p5)} Frw'),
          _PriceItem('Full Day (24h)', '${moneyFmt.format(pd)} Frw'),
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
