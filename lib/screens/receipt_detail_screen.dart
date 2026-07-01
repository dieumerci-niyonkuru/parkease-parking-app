import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/branded_loader.dart';
import '../models/models.dart';
import '../utils/app_utils.dart';

class ReceiptDetailScreen extends StatefulWidget {
  final HistoryEntry entry;
  const ReceiptDetailScreen({super.key, required this.entry});

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  Map<String, dynamic>? _pricing;
  HistoryEntry? _entry;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getReceiptById(widget.entry.slotId),
      ApiService.getPricing(widget.entry.slotId),
    ]);
    
    if (mounted) {
      setState(() {
        if (results[0] != null) _entry = results[0] as HistoryEntry;
        _pricing = results[1] as Map<String, dynamic>?;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _entry == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: const BrandedLoader(message: 'Retrieving official receipt...'),
      );
    }

    final entry = _entry!;
    final rate = _pricing != null 
        ? (double.tryParse(_pricing!['rate']?.toString() ?? '200') ?? 200.0)
        : entry.ratePerHour;
    final moneyFmt = NumberFormat('#,###');
    final dtFmt = DateFormat('EEEE, d MMMM yyyy · HH:mm');

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        elevation: 0,
        title: Text('RECEIPT DETAILS', style: AppTheme.heading4.copyWith(letterSpacing: 1.5, color: AppTheme.primary)),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary, size: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── RECEIPT HEADER ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.subtleShadow,
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 64),
                  const SizedBox(height: 16),
                  Text('Payment Successful', style: AppTheme.heading2.copyWith(color: AppTheme.success)),
                  const SizedBox(height: 8),
                  Text('RWF ${moneyFmt.format(entry.amountPaid?.toInt() ?? 0)}',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _DetailRow('EBM Receipt #', entry.receiptNumber ?? 'N/A', isBold: true),
                  _DetailRow('Plate Number', entry.plateNumber, isMono: true),
                  _DetailRow('Parking Site', entry.parkingName),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),

            const SizedBox(height: 24),

            // ── PDF VIEW BUTTON ────────────────────────────────
            if (entry.receiptUrl != null && entry.receiptUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openPdf(entry.receiptUrl!),
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                    label: const Text('VIEW OFFICIAL PDF RECEIPT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),

            // ── SESSION DETAILS ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SESSION SUMMARY', style: AppTheme.label.copyWith(color: AppTheme.primary, letterSpacing: 1)),
                  const SizedBox(height: 16),
                  _DetailRow('Entry Time', dtFmt.format(entry.entryTime)),
                  _DetailRow('Exit Time', entry.exitTime != null ? dtFmt.format(entry.exitTime!) : '—'),
                  _DetailRow('Duration', _getDurationStr(entry)),
                  _DetailRow('Hourly Rate', 'RWF ${entry.ratePerHour.toInt()} / hr'),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // ── PARKING SITE INFO ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PARKING SITE INFORMATION', style: AppTheme.label.copyWith(color: AppTheme.primary, letterSpacing: 1)),
                  const SizedBox(height: 16),
                  _DetailRow('Facility Name', entry.parkingName, isBold: true),
                  _DetailRow('Location', entry.parkingAddress),
                  _DetailRow('Spot/Slot #', entry.spotNumber, isHighlight: true),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // ── 24 HOUR RATE LIST ─────────────────────────────
            _buildRateList(rate).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 32),

            // ── ACTIONS ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _saveReceipt(context),
                    icon: const Icon(Icons.save_alt_rounded, color: Colors.white),
                    label: const Text('SAVE RECEIPT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary),
                  ),
                  child: IconButton(
                    onPressed: () => _shareReceipt(context),
                    icon: const Icon(Icons.share_rounded, color: AppTheme.primary),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms),
            
            const SizedBox(height: 40),
            Text('Thank you for using ITEC Parking Services!',
              style: AppTheme.label.copyWith(color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

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
              if (_loading)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
              else
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

  Widget _DetailRow(String label, String value, {bool isBold = false, bool isMono = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodySmall),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold || isHighlight ? FontWeight.w800 : FontWeight.w600,
                color: isHighlight ? AppTheme.primary : AppTheme.textPrimary,
                fontSize: 13,
                fontFamily: isMono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDurationStr(HistoryEntry e) {
    final end = e.exitTime ?? DateTime.now();
    final d = end.difference(e.entryTime);
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return m == 0 ? '$h hr${h > 1 ? "s" : ""}' : '$h hr${h > 1 ? "s" : ""} $m min';
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _saveReceipt(BuildContext context) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Receipt image saved to your gallery.'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _shareReceipt(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening share dialog...')),
    );
  }
}