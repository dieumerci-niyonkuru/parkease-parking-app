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

class PlateLookupScreen extends StatefulWidget {
  final String initialPlate;
  const PlateLookupScreen({super.key, this.initialPlate = ''});
  @override State<PlateLookupScreen> createState() => _PlateLookupScreenState();
}

class _PlateLookupScreenState extends State<PlateLookupScreen> {
  final _plateCtrl = TextEditingController();
  VehicleRecord? _record;
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
      body: Column(children: [
        // ── Search Header ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          color: Colors.white,
          child: Column(
            children: [
              Row(children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary, size: 20),
                  tooltip: 'Back',
                ),
                const Expanded(
                  child: Text('Type your plate number', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF212529), letterSpacing: 1)),
                ),
                const SizedBox(width: 20),
              ]),
              const SizedBox(height: 4),
              Text('Instant Multi-Site Search'.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 2)),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgDeep,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 1.5),
                ),
                child: Row(children: [
                  Container(
                    margin: const EdgeInsets.all(10), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.border)),
                    child: Text('RW', style: AppTheme.label.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _plateCtrl,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.search,
                      textAlign: TextAlign.center,
                      onSubmitted: (_) => _search(),
                      style: AppTheme.mono.copyWith(fontSize: 20, color: const Color(0xFF2D2018), fontWeight: FontWeight.w900, letterSpacing: 2),
                      decoration: InputDecoration(
                        hintText: 'RAC 001 A',
                        hintStyle: AppTheme.mono.copyWith(fontSize: 20, color: Colors.black.withValues(alpha: 0.1), letterSpacing: 2),
                        border: InputBorder.none,
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
            ],
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
            color: AppTheme.primary,
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

        // ── PAY BUTTON (or postpaid notice) ─────────────────────────
        if (record.payable)
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
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2)
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.warning),
              const SizedBox(width: 12),
              Expanded(child: Text(
                record.blockMessage ?? 'This vehicle is on a company/postpaid account. Please contact the parking attendant to settle.',
                style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppTheme.textSecond),
              )),
            ]),
          ).animate().fadeIn(delay: 300.ms),

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
      Icon(Icons.directions_car_filled_rounded, color: AppTheme.textHint.withValues(alpha: 0.5), size: 100),
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
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.search_off_rounded, color: AppTheme.warning, size: 44),
        ),
        const SizedBox(height: 20),
        Text('No Result Found', style: AppTheme.heading4.copyWith(color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: AppTheme.body.copyWith(color: AppTheme.textMuted)),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('TRY AGAIN', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ]),
    ),
  );
}
