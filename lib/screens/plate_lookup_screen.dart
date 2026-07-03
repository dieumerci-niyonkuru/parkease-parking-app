import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../services/notification_service.dart';
import '../providers/app_provider.dart';
import '../widgets/branded_loader.dart';
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
    HapticFeedback.lightImpact();
    
    final provider = context.read<AppProvider>();
    await provider.lookupVehicle(plate);
    
    if (mounted) {
      setState(() {
        _record = provider.currentRecord;
        _error  = provider.lookupError;
      });
    }
  }

  Future<VehicleRecord?> _processPayment(VehicleRecord record) async {
    final provider = context.read<AppProvider>();
    final updated = await provider.processPayment(record);
    if (mounted) setState(() => _record = updated);
    return updated;
  }

  @override Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Lookup & Pay', style: AppTheme.heading4.copyWith(letterSpacing: 1.2, color: AppTheme.primary)),
        centerTitle: true,
      ),
      body: Column(children: [
        // ── Search Bar ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1.5),
              boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              Container(
                margin: const EdgeInsets.all(10), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppTheme.bgDeep, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.border)),
                child: Text('RW', style: AppTheme.label.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900)),
              ),
              Expanded(
                child: TextField(
                  controller: _plateCtrl,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  style: AppTheme.mono.copyWith(fontSize: 20, color: const Color(0xFF2D2018), fontWeight: FontWeight.w900),
                  decoration: InputDecoration(
                    hintText: 'RAC 001 A',
                    hintStyle: AppTheme.mono.copyWith(fontSize: 20, color: Colors.black.withOpacity(0.2)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 28),
                onPressed: _search,
              ),
              const SizedBox(width: 8),
            ]),
          ),
        ),

        Expanded(
          child: provider.lookupLoading
            ? const BrandedLoader(message: 'Searching vehicle records...')
            : _error != null
              ? _ErrorView(message: _error!, onRetry: _search)
              : _record == null
                ? _WelcomeView()
                : _RecordDetails(record: _record!, onPay: _processPayment)
        ),
      ]),
    );
  }
}

class _RecordDetails extends StatelessWidget {
  final VehicleRecord record;
  final Future<VehicleRecord?> Function(VehicleRecord) onPay;
  const _RecordDetails({required this.record, required this.onPay});

  @override Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        
        // ── FEE CARD ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: AppTheme.heroGrad,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppTheme.glowShadow,
          ),
          child: Column(children: [
            Text('TOTAL AMOUNT DUE', style: AppTheme.label.copyWith(color: Colors.white70, letterSpacing: 2)),
            const SizedBox(height: 12),
            Text('RWF ${NumberFormat('#,###').format(record.totalAmount)}', 
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'monospace')),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _InfoBit(label: 'DURATION', value: record.durationDisplay),
              _InfoBit(label: 'RATE', value: '${record.ratePerHour.toInt()}/hr'),
              _InfoBit(label: 'SPOT', value: record.spotNumber),
            ]),
          ]),
        ).animate().fadeIn().scale(duration: 400.ms, curve: Curves.easeOutBack),
        
        const SizedBox(height: 24),
        
        // ── PAY BUTTON ──────────────────────────────────────────────
        SizedBox(
          width: double.infinity, height: 64,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => 
                PaymentScreen(record: record, onPay: onPay)));
            },
            icon: const Icon(Icons.payment_rounded, color: Colors.white),
            label: const Text('PAY NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
        
        const SizedBox(height: 32),
        
        // ── VEHICLE & LOCATION DETAILS ──────────────────────────────
        _DetailCard(title: 'YOUR PARKING DETAILS', items: [
          _Row('Plate Number', record.plateNumber, isMono: true),
          _Row('Vehicle Type', record.vehicleType),
          _Row('Make & Color', '${record.vehicleMake} (${record.vehicleColor})'),
          _Row('Entry Time', DateFormat('HH:mm (dd MMM)').format(record.entryTime)),
          _Row('Currently Parked For', record.durationDisplay),
        ]).animate().fadeIn(delay: 450.ms),
        
        const SizedBox(height: 16),
        
        _DetailCard(title: 'PARKING LOCATION', items: [
          _Row('Parking Site', record.parkingName),
          _Row('Address', record.parkingAddress),
          _Row('Slot Number', record.spotNumber, isHighlight: true),
        ]).animate().fadeIn(delay: 550.ms),
        
        const SizedBox(height: 40),
      ]),
    );
  }
}

class _InfoBit extends StatelessWidget {
  final String label, value;
  const _InfoBit({required this.label, required this.value});
  @override Widget build(BuildContext context) => Column(children: [
    Text(label, style: AppTheme.label.copyWith(fontSize: 9, color: Colors.white60)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
  ]);
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _DetailCard({required this.title, required this.items});
  @override Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.bgCard, borderRadius: BorderRadius.circular(20), 
      border: Border.all(color: AppTheme.border, width: 0.5),
      boxShadow: AppTheme.subtleShadow,
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTheme.label.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      const SizedBox(height: 12),
      ...items,
    ]),
  );
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool isMono, isHighlight;
  const _Row(this.label, this.value, {this.isMono = false, this.isHighlight = false});
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTheme.bodySmall),
      Text(value, style: TextStyle(
        color: isHighlight ? AppTheme.primary : AppTheme.textPrimary, 
        fontWeight: FontWeight.w700,
        fontFamily: isMono ? 'monospace' : null,
        letterSpacing: isMono ? 1 : null,
      )),
    ]),
  );
}

class _WelcomeView extends StatelessWidget {
  @override Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.directions_car_filled_rounded, color: AppTheme.textHint.withOpacity(0.5), size: 100),
      const SizedBox(height: 24),
      Text('Ready to pay?', style: AppTheme.heading2),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Text('Enter your vehicle plate number above to retrieve your parking session details instantly.', 
          textAlign: TextAlign.center, style: AppTheme.body),
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
      const SizedBox(height: 20),
      Text('Lookup Failed', style: AppTheme.heading4.copyWith(color: AppTheme.danger)),
      const SizedBox(height: 8),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 50), child: Text(message, textAlign: TextAlign.center, style: AppTheme.body)),
      const SizedBox(height: 24),
      TextButton.icon(
        onPressed: onRetry, 
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('TRY AGAIN', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
    ]),
  );
}
