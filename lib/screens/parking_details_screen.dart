import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/branded_loader.dart';
import 'package:intl/intl.dart';

class ParkingDetailsScreen extends StatefulWidget {
  final ParkingFacility facility;
  const ParkingDetailsScreen({super.key, required this.facility});

  @override State<ParkingDetailsScreen> createState() => _ParkingDetailsScreenState();
}

class _ParkingDetailsScreenState extends State<ParkingDetailsScreen> {
  PricingData? _pricing;
  bool _loading = true;

  @override void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final pricing = await ApiService.getPricingData(widget.facility.recordId);
    if (!mounted) return;
    setState(() {
      _pricing = pricing;
      _loading = false;
    });
  }

  // Opens the device maps app / browser searching for this site by name +
  // address. The API doesn't provide GPS coordinates, so we search by text —
  // which still drops the user straight into turn-by-turn on most devices.
  Future<void> _openInMaps() async {
    final query = Uri.encodeComponent('${widget.facility.fullParkName}, ${widget.facility.address}');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t open maps. Please make sure a maps app or browser is installed.'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t open maps. Please try again.'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override Widget build(BuildContext context) {
    final categories = _pricing?.categories ?? const <PriceCategory>[];

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.facility.fullParkName.toUpperCase(), 
          style: const TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
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
                      border: Border(bottom: BorderSide(color: AppTheme.primary.withValues(alpha: 0.1))),
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
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _openInMaps,
                            icon: const Icon(Icons.navigation_rounded, size: 18, color: Colors.white),
                            label: const Text('NAVIGATE TO SITE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
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

                        if (categories.isEmpty)
                          const _PricingUnavailable().animate().fadeIn()
                        else
                          ...categories.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _CategoryPricingCard(
                              title: categories.length > 1 ? c.name : 'General',
                              category: c,
                              currency: _pricing?.currency ?? 'RWF',
                              onViewFull: c.tiers.length > 5 ? () => _showFullPriceList(context, c) : null,
                            ).animate().fadeIn(),
                          )),

                        const SizedBox(height: 20),
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
  final PriceCategory category;
  final String currency;
  final VoidCallback? onViewFull;
  const _CategoryPricingCard({required this.title, required this.category, this.currency = 'RWF', this.onViewFull});

  @override Widget build(BuildContext context) {
    final moneyFmt = NumberFormat('#,###');
    final sym = currency == 'RWF' ? 'Frw ' : '$currency ';
    // Show up to the first 5 real tiers the backend defines (hours > 0),
    // not a fabricated rate * n projection.
    final previewTiers = category.tiers.where((t) => t.hours > 0).take(5).toList();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF212529))),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 24),
          for (final t in previewTiers)
            _priceItem('${t.hours} Hour${t.hours == 1 ? "" : "s"}', '$sym${moneyFmt.format(t.price)}'),
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

  Widget _priceItem(String label, String value) {
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
  Future<void> _showFullPriceList(BuildContext context, PriceCategory category) async {
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
            child: _buildFullRateBreakdown(category),
          ),
        ),
      ),
    );
  }

  Widget _buildFullRateBreakdown(PriceCategory category) {
    final moneyFmt = NumberFormat('#,###');
    final sym = _pricing?.currency == 'RWF' ? 'Frw ' : '${_pricing?.currency ?? ''} ';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: category.tiers.map((t) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.hours == 0 ? '0-1 Hour' : '${t.hours} Hour${t.hours == 1 ? "" : "s"}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                Text('$sym${moneyFmt.format(t.price)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF7A5B40))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PricingUnavailable extends StatelessWidget {
  const _PricingUnavailable();
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7F2),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      children: [
        Icon(Icons.info_outline_rounded, color: AppTheme.primary.withValues(alpha: 0.5), size: 32),
        const SizedBox(height: 12),
        const Text('Pricing information is temporarily unavailable for this site.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF7A5B40))),
      ],
    ),
  );
}
