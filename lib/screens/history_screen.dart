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

  @override void initState() { 
    super.initState(); 
    _load(); 
  }

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
        elevation: 0,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PAYMENT HISTORY', style: AppTheme.heading4.copyWith(letterSpacing: 1.2, color: AppTheme.primary, fontSize: 13)),
            Text('Official EBM Digital Receipts', style: AppTheme.label.copyWith(fontSize: 9, color: AppTheme.success, fontWeight: FontWeight.w800)),
          ]),
        ]),
        actions: [
          IconButton(
            onPressed: _load, 
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textMuted),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primary,
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3))
          : _receipts.isEmpty
            ? _EmptyReceipts()
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: _receipts.length,
                itemBuilder: (context, index) {
                  final r = _receipts[index];
                  return _ReceiptCard(receipt: r)
                    .animate().fadeIn(delay: Duration(milliseconds: index * 40)).slideY(begin: 0.1);
                },
              ),
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
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border.withOpacity(0.5), width: 1),
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.verified_rounded, color: AppTheme.success, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(receipt.parkingName, style: AppTheme.heading4.copyWith(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(receipt.plateNumber, style: AppTheme.mono.copyWith(fontSize: 14, letterSpacing: 1.5, color: AppTheme.textPrimary)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('RWF ${NumberFormat('#,###').format(receipt.amountPaid ?? 0)}', 
                  style: AppTheme.heading4.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(DateFormat('dd MMM, HH:mm').format(receipt.exitTime ?? receipt.entryTime), style: AppTheme.label.copyWith(fontSize: 9)),
              ]),
            ]),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.bgDeep.withOpacity(0.4), 
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(receipt.durationDisplay, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              ]),
              TextButton.icon(
                onPressed: () {
                  if (receipt.receiptNumber != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('EBM Receipt ${receipt.receiptNumber} ready for download.'),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
                icon: const Icon(Icons.cloud_download_rounded, size: 16, color: AppTheme.primary),
                label: Text('EBM RECEIPT', style: AppTheme.label.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 10)),
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
        Icon(Icons.receipt_long_rounded, color: AppTheme.textHint.withOpacity(0.3), size: 100),
        const SizedBox(height: 24),
        Text('No transaction history', style: AppTheme.heading3.copyWith(color: AppTheme.textMuted)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Text('All your official parking payments and digital receipts will appear here.', 
            textAlign: TextAlign.center, style: AppTheme.bodySmall),
        ),
      ]),
    );
  }
}
