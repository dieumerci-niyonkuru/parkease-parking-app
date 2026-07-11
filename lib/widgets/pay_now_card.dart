import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../screens/payment_screen.dart';

/// The primary "Pay Now" action, shared by the Home dashboard and the
/// Parking Site tab. Tapping it opens the "Pay for Parking" dialog which
/// validates the plate and, on success, goes straight to the payment screen.
///
/// [dense] renders a compact single-row bar (used in the Parking Site header);
/// the default is the full hero card (used on Home).
class PayNowCard extends StatelessWidget {
  final bool dense;
  const PayNowCard({super.key, this.dense = false});

  void _open(BuildContext context) =>
      showDialog(context: context, builder: (_) => const _PayDialog());

  @override
  Widget build(BuildContext context) {
    if (dense) return _buildDense(context);
    return _buildHero(context);
  }

  // ── Full hero card (Home) ──────────────────────────────────────────
  Widget _buildHero(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 22, offset: const Offset(0, 12))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 56, height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(18)),
              child: const Text('💰', style: TextStyle(fontSize: 30)),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pay Parking Fees', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text('Enter your plate number and pay in seconds.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500, height: 1.3)),
              ]),
            ),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: () => _open(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('PAY NOW  💰',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5, color: AppTheme.primary)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Compact bar (Parking Site header) ──────────────────────────────
  Widget _buildDense(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: const Text('💰', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Pay Parking Fees', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
              SizedBox(height: 1),
              Text('Pay instantly by plate number', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Text('PAY NOW', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
          ),
        ]),
      ),
    );
  }
}

// ── PAY FOR PARKING DIALOG ────────────────────────────────────────────
// Captures the plate, validates it against the payment API, shows inline
// errors, and on a valid, payable match goes straight to the payment screen.
class _PayDialog extends StatefulWidget {
  const _PayDialog();
  @override State<_PayDialog> createState() => _PayDialogState();
}

class _PayDialogState extends State<_PayDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _checkout() async {
    final plate = _ctrl.text.trim().toUpperCase();
    if (plate.isEmpty) {
      setState(() => _error = 'Please enter a plate number.');
      return;
    }
    setState(() { _error = null; _loading = true; });

    final provider = context.read<AppProvider>();
    await provider.lookupVehicle(plate);
    if (!mounted) return;

    final record = provider.currentRecord;
    if (record == null) {
      setState(() { _loading = false; _error = provider.lookupError ?? 'Plate not found or not currently parked.'; });
      return;
    }
    if (!record.payable) {
      setState(() { _loading = false; _error = record.blockMessage ?? 'This vehicle is on a company/postpaid account. Please contact the parking attendant.'; });
      return;
    }

    // Valid & payable → proceed straight to the payment method screen.
    final nav = Navigator.of(context);
    nav.pop(); // close dialog
    nav.push(MaterialPageRoute(
      builder: (_) => PaymentScreen(record: record, onPay: (r) => provider.processPayment(r)),
    ));
  }

  @override Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.directions_car_rounded, color: AppTheme.primary, size: 22),
            const SizedBox(width: 10),
            const Expanded(child: Text('Pay for Parking',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.textPrimary))),
            GestureDetector(
              onTap: _loading ? null : () => Navigator.pop(context),
              child: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 22),
            ),
          ]),
          const SizedBox(height: 20),
          Text('PLATE NUMBER', style: AppTheme.label.copyWith(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            autofocus: true,
            enabled: !_loading,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.go,
            onChanged: (_) { if (_error != null) setState(() => _error = null); },
            onSubmitted: (_) => _checkout(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, letterSpacing: 1),
            decoration: InputDecoration(
              hintText: 'E.G. RAD 123 A',
              hintStyle: const TextStyle(color: AppTheme.textHint, letterSpacing: 1),
              filled: true,
              fillColor: AppTheme.bgDeep,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _error != null ? AppTheme.danger : AppTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _error != null ? AppTheme.danger : AppTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _error != null ? AppTheme.danger : AppTheme.primary, width: 1.5)),
            ),
          ),

          // Inline validation error (matches the reference: red text under the field)
          if (_error != null) ...[
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 15),
              const SizedBox(width: 6),
              Expanded(child: Text(_error!, style: AppTheme.bodySmall.copyWith(color: AppTheme.danger, fontWeight: FontWeight.w600))),
            ]),
          ],

          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: _loading ? null : () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _loading ? null : _checkout,
              icon: _loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.search_rounded, size: 18),
              label: Text(_loading ? 'Checking...' : 'Checkout', style: const TextStyle(fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.6),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
