import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../services/notification_service.dart';
import '../widgets/widgets.dart';
import 'payment_screen.dart';

class PlateLookupScreen extends StatefulWidget {
  final String initialPlate;
  const PlateLookupScreen({super.key, this.initialPlate = ''});
  @override State<PlateLookupScreen> createState() => _PlateLookupScreenState();
}

class _PlateLookupScreenState extends State<PlateLookupScreen> {
  final _plateCtrl = TextEditingController();
  VehicleRecord? _record;
  bool _loading = false;
  String? _error;

  @override void initState() {
    super.initState();
    _plateCtrl.text = widget.initialPlate;
    if (widget.initialPlate.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override void dispose() { _plateCtrl.dispose(); super.dispose(); }

  Future<void> _search() async {
    final plate = _plateCtrl.text.trim().toUpperCase();
    if (plate.isEmpty) return;
    setState(() { _loading = true; _error = null; _record = null; });
    HapticFeedback.lightImpact();

    try {
      final found = await ApiService.lookupVehicle(plate);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _record  = found;
        _error   = found == null ? 'Vehicle not found. Please check the plate number.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'An error occurred during search.'; });
    }
  }

  Future<VehicleRecord?> _processPayment(VehicleRecord record) async {
    final receipt  = 'ITEC-PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final exitTime = DateTime.now();
    final paid     = record.totalAmount;

    final updated = record.copyWith(
      status: VehicleStatus.paid,
      amountPaid: paid,
      receiptNumber: receipt,
      exitTime: exitTime,
    );

    await HistoryService.save(updated);
    await NotificationService.notifyPaymentSuccess(updated);
    HapticFeedback.heavyImpact();
    
    if (mounted) setState(() => _record = updated);
    return updated;
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        title: Text('Quick Pay & Check', style: AppTheme.heading4),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(children: [
        // ── Search Bar ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.primary.withOpacity(0.5), width: 1.5),
              boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.1), blurRadius: 10)],
            ),
            child: Row(children: [
              Container(
                margin: const EdgeInsets.all(8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.bgDeep, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.border)),
                child: const Text('RW', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              Expanded(
                child: TextField(
                  controller: _plateCtrl,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: 3),
                  decoration: const InputDecoration(
                    hintText: 'RAC 001 A',
                    hintStyle: TextStyle(fontFamily: 'monospace', fontSize: 20, color: AppTheme.textHint, letterSpacing: 2),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.search_rounded, color: AppTheme.primary), onPressed: _search),
            ]),
          ),
        ),

        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _error != null
              ? _ErrorView(message: _error!, onRetry: _search)
              : _record == null
                ? _WelcomeView()
                : _RecordResult(record: _record!, onPay: _processPayment)
        ),
      ]),
    );
  }
}

class _RecordResult extends StatelessWidget {
  final VehicleRecord record;
  final Future<VehicleRecord?> Function(VehicleRecord) onPay;
  const _RecordResult({required this.record, required this.onPay});

  @override Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Quick Fee Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0D1F35), Color(0xFF0A1A1A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: Column(children: [
            Text('AMOUNT DUE', style: AppTheme.label.copyWith(letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('RWF ${NumberFormat('#,###').format(record.totalAmount)}', 
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppTheme.primary, fontFamily: 'monospace')),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.border),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _MiniInfo(label: 'DURATION', value: record.durationDisplay),
              _MiniInfo(label: 'LOCATION', value: record.parkingName),
              _MiniInfo(label: 'SPOT', value: record.spotNumber),
            ]),
          ]),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        
        const SizedBox(height: 24),
        
        // Pay Button
        SizedBox(
          width: double.infinity, height: 60,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => 
                PaymentScreen(record: record, onPay: onPay)));
            },
            icon: const Icon(Icons.payment_rounded, color: Colors.black),
            label: const Text('PAY SECURELY NOW', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd))),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
        
        const SizedBox(height: 32),
        
        // Vehicle details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(AppTheme.radiusLg), border: Border.all(color: AppTheme.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('VEHICLE DETAILS', style: AppTheme.label.copyWith(color: AppTheme.primary)),
            const SizedBox(height: 12),
            _DetailRow('Plate Number', record.plateNumber),
            _DetailRow('Vehicle', '${record.vehicleMake} ${record.vehicleType}'),
            _DetailRow('Entry Time', DateFormat('HH:mm (dd MMM)').format(record.entryTime)),
            _DetailRow('Parking Site', record.parkingAddress),
          ]),
        ).animate().fadeIn(delay: 450.ms),
      ]),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label, value;
  const _MiniInfo({required this.label, required this.value});
  @override Widget build(BuildContext context) => Column(children: [
    Text(label, style: AppTheme.label.copyWith(fontSize: 9)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
  ]);
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTheme.bodySmall),
      Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _WelcomeView extends StatelessWidget {
  @override Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.directions_car_rounded, color: AppTheme.textHint, size: 80),
      const SizedBox(height: 20),
      Text('Ready to Pay?', style: AppTheme.heading2),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text('Enter your vehicle plate number above to check parking duration and pay instantly.', textAlign: TextAlign.center, style: AppTheme.body),
      ),
    ]),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 64),
      const SizedBox(height: 16),
      Text('No Record Found', style: AppTheme.heading4),
      const SizedBox(height: 8),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Text(message, textAlign: TextAlign.center, style: AppTheme.body)),
      const SizedBox(height: 20),
      TextButton(onPressed: onRetry, child: const Text('Try Again', style: TextStyle(color: AppTheme.primary))),
    ]),
  );
}
