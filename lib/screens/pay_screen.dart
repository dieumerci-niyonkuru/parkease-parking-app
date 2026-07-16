import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/branded_loader.dart';
import 'payment_screen.dart';

class PayScreen extends StatefulWidget {
  const PayScreen({super.key});
  @override State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  final _plateCtrl = TextEditingController();
  ParkingFacility? _selectedSite;
  VehicleRecord? _record;
  String? _error;
  bool _isLoading = false;

  @override void dispose() {
    _plateCtrl.dispose();
    super.dispose();
  }

  // Sentinel distinguishes "user explicitly picked All Sites" (clear the
  // selection) from "sheet dismissed with nothing picked" (leave it alone).
  static const Object _allSitesSentinel = Object();

  Future<void> _showSitePicker(List<ParkingFacility> sites) async {
    String query = '';
    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filtered = query.isEmpty
              ? sites
              : sites.where((s) => s.fullParkName.toLowerCase().contains(query.toLowerCase())).toList();
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.75,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Select Parking Site', style: AppTheme.heading3.copyWith(fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: true,
                      onChanged: (v) => setSheetState(() => query = v),
                      decoration: InputDecoration(
                        hintText: 'Search sites...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        filled: true,
                        fillColor: AppTheme.bgDeep,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      children: [
                        if (query.isEmpty)
                          ListTile(
                            leading: const Icon(Icons.travel_explore_rounded, color: AppTheme.primary),
                            title: const Text('All Sites (Auto-Scan)', style: TextStyle(fontWeight: FontWeight.w800)),
                            selected: _selectedSite == null,
                            selectedTileColor: AppTheme.primary.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onTap: () => Navigator.pop(ctx, _allSitesSentinel),
                          ),
                        ...filtered.map((s) => ListTile(
                          leading: const Icon(Icons.local_parking_rounded, color: AppTheme.primary),
                          title: Text(s.fullParkName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: s.address.isNotEmpty ? Text(s.address, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                          selected: _selectedSite?.recordId == s.recordId,
                          selectedTileColor: AppTheme.primary.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onTap: () => Navigator.pop(ctx, s),
                        )),
                        if (filtered.isEmpty && query.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: Text('No sites match "$query"', style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted))),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result == _allSitesSentinel) {
      setState(() => _selectedSite = null);
    } else if (result is ParkingFacility) {
      setState(() => _selectedSite = result);
    }
  }

  Future<void> _search() async {
    final plate = _plateCtrl.text.trim().toUpperCase();
    if (plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plate number'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
      _record = null;
    });

    HapticFeedback.lightImpact();
    
    final provider = context.read<AppProvider>();
    // We'll use a custom lookup here that supports dbId if selected
    try {
      final result = await provider.lookupWithSite(plate, dbId: _selectedSite?.dbId);
      if (mounted) {
        setState(() {
          _record = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lookup failed. Check your connection or plate number.';
          _isLoading = false;
        });
      }
    }
  }

  @override Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final sites = provider.facilities;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            color: Colors.white,
            child: Column(
              children: [
                const Text('Pay Parking Fee',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryDeep, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text('Settle your unpaid parking sessions'.toUpperCase(), 
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 1.5)),
                const SizedBox(height: 16),

                // ── Site Selector ──────────────────────────────────
                InkWell(
                  onTap: () => _showSitePicker(sites),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDeep,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(children: [
                      const Icon(Icons.local_parking_rounded, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedSite?.fullParkName ?? 'All Sites (Auto-Scan)',
                          style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.expand_more_rounded, color: AppTheme.textMuted, size: 20),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Plate Input ────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgDeep,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Row(children: [
                    Container(
                      margin: const EdgeInsets.all(10), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.border)),
                      child: Text('RW', style: AppTheme.label.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 10)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _plateCtrl,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        style: AppTheme.mono.copyWith(fontSize: 18, color: AppTheme.textPrimary, fontWeight: FontWeight.w900, letterSpacing: 1),
                        decoration: InputDecoration(
                          hintText: 'Enter Plate Number',
                          hintStyle: AppTheme.body.copyWith(color: AppTheme.textHint, fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                      onPressed: _search,
                    ),
                  ]),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
              ? const BrandedLoader(message: 'Retrieving parking session...')
              : _error != null
                ? _ErrorDisplay(message: _error!, onRetry: _search)
                : _record == null
                  ? _EmptyState()
                  : _SessionDetails(record: _record!),
          ),
        ],
      ),
    );
  }
}

class _SessionDetails extends StatelessWidget {
  final VehicleRecord record;
  const _SessionDetails({required this.record});

  @override Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(children: [
        // ── Main Card ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(record.parkingName.toUpperCase(), 
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
            ),
            const SizedBox(height: 14),
            Text('AMOUNT DUE', style: AppTheme.label.copyWith(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('RWF ${NumberFormat('#,###').format(record.totalAmount)}', 
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.primaryDeep)),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            
            _RowInfo(label: 'Entry Time', value: DateFormat('HH:mm, dd MMM').format(record.entryTime)),
            if (record.exitTime != null)
              _RowInfo(label: 'Exit Time', value: DateFormat('HH:mm, dd MMM').format(record.exitTime!)),
            _RowInfo(label: 'Duration', value: record.durationDisplay),
            _RowInfo(label: 'Plate No', value: record.plateNumber, isMono: true),
            _RowInfo(label: 'Spot No', value: record.spotNumber, isHighlight: true),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: record.payable ? () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => 
                    PaymentScreen(record: record, onPay: (r) async {
                      final updated = await context.read<AppProvider>().processPayment(r);
                      return updated;
                    })));
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('PROCEED TO PAYMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
            if (!record.payable) ...[
              const SizedBox(height: 12),
              Text(record.blockMessage ?? 'Postpaid account. Settle with attendant.',
                style: const TextStyle(color: AppTheme.danger, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ]),
        ).animate().fadeIn().slideY(begin: 0.1),
        
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _RowInfo extends StatelessWidget {
  final String label, value;
  final bool isMono, isHighlight;
  const _RowInfo({required this.label, required this.value, this.isMono = false, this.isHighlight = false});

  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted)),
        Text(value, style: TextStyle(
          color: isHighlight ? AppTheme.primary : AppTheme.textPrimary,
          fontWeight: FontWeight.w800,
          fontFamily: isMono ? 'monospace' : null,
          fontSize: isMono ? 15 : 14,
        )),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  @override Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.payment_rounded, color: AppTheme.textHint.withValues(alpha: 0.3), size: 80),
      const SizedBox(height: 14),
      Text('Find Your Session', style: AppTheme.heading3),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text('Enter your plate number and optionally select your parking site to see what you owe.',
          textAlign: TextAlign.center, style: AppTheme.bodySmall),
      ),
    ]),
  );
}

class _ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorDisplay({required this.message, required this.onRetry});

  @override Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.info_outline_rounded, color: AppTheme.warning, size: 48),
        const SizedBox(height: 16),
        Text('No Active Session', style: AppTheme.heading4),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: AppTheme.bodySmall),
        const SizedBox(height: 16),
        TextButton(onPressed: onRetry, child: const Text('TRY AGAIN', style: TextStyle(fontWeight: FontWeight.w900))),
      ]),
    ),
  );
}
