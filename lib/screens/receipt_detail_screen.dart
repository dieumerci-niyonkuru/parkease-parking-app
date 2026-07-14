import 'dart:io';
import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../widgets/branded_loader.dart';
import '../models/models.dart';


class ReceiptDetailScreen extends StatefulWidget {
  final HistoryEntry entry;
  const ReceiptDetailScreen({super.key, required this.entry});

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
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
    final refreshed = await ApiService.getReceiptById(widget.entry.slotId);
    if (mounted) {
      setState(() {
        if (refreshed != null) _entry = refreshed;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _entry == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: BrandedLoader(message: 'Loading your receipt...'),
      );
    }

    final entry = _entry!;
    final moneyFmt = NumberFormat('#,###');
    final dtFmt = DateFormat('EEEE, d MMMM yyyy · HH:mm');

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('RECEIPT DETAILS', style: AppTheme.heading4.copyWith(letterSpacing: 1.2, color: AppTheme.primary)),
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
                  _detailRow('EBM Receipt #', entry.receiptNumber ?? 'N/A', isBold: true),
                  _detailRow('Plate Number', entry.plateNumber, isMono: true),
                  _detailRow('Parking Site', entry.parkingName),
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
                    onPressed: () => _openPdf(context, entry.receiptUrl!),
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
                  _detailRow('Entry Time', dtFmt.format(entry.entryTime)),
                  _detailRow('Exit Time', entry.exitTime != null ? dtFmt.format(entry.exitTime!) : '—'),
                  _detailRow('Duration', _getDurationStr(entry)),
                  _detailRow('Hourly Rate', 'RWF ${entry.ratePerHour.toInt()} / hr'),
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
                  _detailRow('Facility Name', entry.parkingName, isBold: true),
                  _detailRow('Location', entry.parkingAddress),
                  _detailRow('Spot/Slot #', entry.spotNumber, isHighlight: true),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

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

  Widget _detailRow(String label, String value, {bool isBold = false, bool isMono = false, bool isHighlight = false}) {
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

  Future<void> _openPdf(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No app found to open this receipt. Try installing a PDF viewer or browser.'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Couldn\'t open the receipt. Please try again.'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveReceipt(BuildContext context) async {
    HapticFeedback.mediumImpact();
    try {
      final entry = _entry!;
      if (entry.receiptUrl != null && entry.receiptUrl!.isNotEmpty) {
        final uri = Uri.parse(entry.receiptUrl!);
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final dir = await getApplicationDocumentsDirectory();
          final filename = 'receipt_${entry.receiptNumber ?? entry.slotId}.pdf';
          final file = File('${dir.path}/$filename');
          await file.writeAsBytes(response.bodyBytes);
          if (mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Receipt saved to your device.'),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        }
      } else {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This receipt doesn\'t have a downloadable PDF yet.'),
              backgroundColor: AppTheme.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Couldn\'t save the receipt. Please try again.'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _shareReceipt(BuildContext context) async {
    HapticFeedback.lightImpact();
    try {
      final entry = _entry!;
      final text = '''
ITEC Parking Receipt
--------------------
EBM Receipt #: ${entry.receiptNumber ?? 'N/A'}
Plate: ${entry.plateNumber}
Site: ${entry.parkingName}
Amount: RWF ${NumberFormat('#,###').format(entry.amountPaid?.toInt() ?? 0)}
Duration: ${_getDurationStr(entry)}
''';
      await Share.share(text);
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Couldn\'t share the receipt. Please try again.'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}