import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';
import 'plate_lookup_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryEntry> _receipts = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ApiService.getReceipts();
    if (!mounted) return;
    setState(() { _receipts = list; _loading = false; });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        automaticallyImplyLeading: false,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Receipts & History', style: AppTheme.heading4),
            Text('Official EBM Receipts', style: AppTheme.label.copyWith(color: AppTheme.success)),
          ]),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : _receipts.isEmpty
          ? _EmptyReceipts()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _receipts.length,
              itemBuilder: (context, index) {
                final r = _receipts[index];
                return _ReceiptCard(receipt: r)
                  .animate().fadeIn(delay: Duration(milliseconds: index * 50)).slideX(begin: -0.05);
              },
            ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final HistoryEntry receipt;
  const _ReceiptCard({required this.receipt});

  @override Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlateLookupScreen(initialPlate: receipt.plateNumber))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border, width: 0.5),
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.receipt_long_rounded, color: AppTheme.success, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(receipt.parkingName, style: AppTheme.heading4.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(receipt.plateNumber, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, letterSpacing: 1, fontSize: 13, color: AppTheme.textPrimary)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('RWF ${NumberFormat('#,###').format(receipt.amountPaid ?? 0)}', style: AppTheme.heading4.copyWith(color: AppTheme.primary)),
                const SizedBox(height: 2),
                Text(DateFormat('dd MMM yyyy').format(receipt.exitTime ?? receipt.entryTime), style: AppTheme.label),
              ]),
            ]),
          ),
          const Divider(height: 1, color: AppTheme.border),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppTheme.bgSurface.withOpacity(0.3), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusLg))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(receipt.durationDisplay, style: AppTheme.bodySmall),
              ]),
              TextButton.icon(
                onPressed: () {
                  if (receipt.receiptNumber != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Opening EBM Receipt: ${receipt.receiptNumber}'),
                      backgroundColor: AppTheme.primary,
                    ));
                  }
                }, // View EBM
                icon: const Icon(Icons.file_download_outlined, size: 16, color: AppTheme.primary),
                label: Text('EBM RECEIPT', style: AppTheme.bodySmall.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _EmptyReceipts extends StatelessWidget {
  @override Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_rounded, color: AppTheme.textHint, size: 64),
        const SizedBox(height: 16),
        Text('No receipts found', style: AppTheme.heading4.copyWith(color: AppTheme.textMuted)),
        const SizedBox(height: 8),
        Text('Your parking payments will appear here.', style: AppTheme.body),
      ]),
    );
  }
}
