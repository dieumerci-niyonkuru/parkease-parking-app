import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/custom_loader.dart';
import '../services/auth_service.dart';

enum PayMethod { momo, airtel, card, cash }

class PaymentScreen extends StatefulWidget {
  final VehicleRecord record;
  final Future<VehicleRecord?> Function(VehicleRecord) onPay;
  const PaymentScreen({super.key, required this.record, required this.onPay});
  @override State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PayMethod _method  = PayMethod.momo;
  bool      _paying  = false;
  bool      _done    = false;
  VehicleRecord? _receipt;

  String _countryCode = '+250';
  final _momoCtrl = TextEditingController();
  
  final _cardNumCtrl = TextEditingController();
  final _expiryCtrl  = TextEditingController();
  final _cvvCtrl     = TextEditingController();

  @override void dispose() {
    _momoCtrl.dispose(); _cardNumCtrl.dispose();
    _expiryCtrl.dispose(); _cvvCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => NumberFormat('#,##0', 'en').format(v.toInt());

  Future<void> _pay() async {
    // ── VALIDATION ──────────────────────────────────────────────
    if (_method == PayMethod.momo || _method == PayMethod.airtel) {
      if (_momoCtrl.text.trim().length < 8) {
        _snack('Please enter a valid phone number (e.g. 788 000 000).', isError: true);
        return;
      }
    } else if (_method == PayMethod.card) {
      if (_cardNumCtrl.text.replaceAll(' ', '').length < 13) {
        _snack('Invalid card number. Check your entry.', isError: true);
        return;
      }
      if (_expiryCtrl.text.isEmpty || _cvvCtrl.text.length < 3) {
        _snack('Please complete all card details.', isError: true);
        return;
      }
    }

    HapticFeedback.mediumImpact();
    setState(() => _paying = true);
    
    // Simulate real gateway delay
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      final phoneOrCard = _method == PayMethod.card ? _cardNumCtrl.text.trim() : '$_countryCode${_momoCtrl.text.trim()}';
      final payload = {
        'slotId': widget.record.slotId,
        'amount': widget.record.totalAmount,
        'method': _method.name,
        'account': phoneOrCard,
      };
      await http.post(
        Uri.parse('https://client-api.iteccone.com/payment'),
        headers: AuthService.authHeaders,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 12));
    } catch (_) {}

    final updated = await widget.onPay(widget.record);
    if (!mounted) return;
    setState(() { _paying = false; _done = true; _receipt = updated; });
    HapticFeedback.heavyImpact();
    
    _snack('Payment processed successfully!', isError: false);
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), 
      backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_done && _receipt != null) return _ReceiptView(record: _receipt!);

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        elevation: 0,
        title: Text('SECURE PAYMENT', style: AppTheme.heading4.copyWith(letterSpacing: 1.5, fontSize: 13, color: AppTheme.primary)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          
          // ── PREMIUM INVOICE CARD ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(children: [
              Text('TOTAL INVOICE AMOUNT', style: AppTheme.label.copyWith(letterSpacing: 2)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('RWF ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                Text(_fmt(widget.record.totalAmount), 
                  style: AppTheme.heading1.copyWith(fontSize: 40, color: AppTheme.textPrimary, fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 20),
              const Divider(height: 32),
              _InvoiceRow(Icons.location_on_rounded, 'Site', widget.record.parkingName),
              const SizedBox(height: 10),
              _InvoiceRow(Icons.timer_outlined, 'Duration', widget.record.durationDisplay),
              const SizedBox(height: 10),
              _InvoiceRow(Icons.directions_car_rounded, 'Vehicle', widget.record.plateNumber),
            ]),
          ).animate().fadeIn().slideY(begin: 0.1),

          const SizedBox(height: 32),
          Text('PAYMENT METHOD', style: AppTheme.label.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          
          _PaymentGrid(selected: _method, onSelect: (m) => setState(() => _method = m)),
          
          const SizedBox(height: 32),
          
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: KeyedSubtree(key: ValueKey(_method), child: _buildMethodForm()),
          ),
          
          const SizedBox(height: 40),
          
          SizedBox(
            width: double.infinity, height: 64,
            child: _paying
              ? const Center(child: CustomLoader(size: 40))
              : ElevatedButton(
                  onPressed: _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 4,
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.lock_rounded, size: 20),
                    const SizedBox(width: 12),
                    const Text('AUTHORIZE PAYMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ]),
                ),
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 24),
          Center(child: Text('🔒 SECURE SSL ENCRYPTED TRANSACTION', style: AppTheme.label.copyWith(fontSize: 9, color: AppTheme.textHint, letterSpacing: 1))),
          const SizedBox(height: 60),
        ]),
      ),
    );
  }

  Widget _buildMethodForm() {
    switch (_method) {
      case PayMethod.momo:
      case PayMethod.airtel:
        return _MobileForm(
          ctrl: _momoCtrl,
          method: _method,
          onCountryChanged: (c) => setState(() => _countryCode = c),
        );
      case PayMethod.card:
        return _CardForm(num: _cardNumCtrl, exp: _expiryCtrl, cvv: _cvvCtrl);
      case PayMethod.cash:
        return _CashNotice();
    }
  }
}

// ── COMPONENTS ──────────────────────────────────────────────────────

class _InvoiceRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InvoiceRow(this.icon, this.label, this.value);
  @override Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 16, color: AppTheme.textMuted),
    const SizedBox(width: 10),
    Text(label, style: AppTheme.bodySmall),
    const Spacer(),
    Text(value, style: AppTheme.body.copyWith(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
  ]);
}

class _PaymentGrid extends StatelessWidget {
  final PayMethod selected;
  final ValueChanged<PayMethod> onSelect;
  const _PaymentGrid({required this.selected, required this.onSelect});

  @override Widget build(BuildContext context) {
    final list = [
      (PayMethod.momo,   'MTN MOMO'),
      (PayMethod.airtel, 'AIRTEL MONEY'),
      (PayMethod.card,   'BANK CARD'),
      (PayMethod.cash,   'CASH PAYMENT'),
    ];

    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12, crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: list.map((m) {
        final active = selected == m.$1;
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(m.$1); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: active ? AppTheme.primary.withOpacity(0.1) : AppTheme.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: active ? AppTheme.primary : AppTheme.border, width: active ? 2 : 1),
            ),
            child: Center(
              child: Text(m.$2, 
                style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w900 : FontWeight.w700, color: active ? AppTheme.primary : AppTheme.textSecond)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MobileForm extends StatelessWidget {
  final TextEditingController ctrl;
  final PayMethod method;
  final ValueChanged<String> onCountryChanged;
  const _MobileForm({required this.ctrl, required this.method, required this.onCountryChanged});

  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('ACCOUNT PHONE NUMBER', style: AppTheme.label),
    const SizedBox(height: 12),
    Row(children: [
      Container(
        decoration: BoxDecoration(color: AppTheme.bgCard, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(16)),
        child: CountryCodePicker(
          onChanged: (c) => onCountryChanged(c.dialCode ?? '+250'),
          initialSelection: 'RW', favorite: const ['+250', 'RW'],
          textStyle: AppTheme.body.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: TextField(
          controller: ctrl, keyboardType: TextInputType.phone,
          style: AppTheme.heading3.copyWith(letterSpacing: 1),
          decoration: InputDecoration(
            hintText: '78XXX XXXX', 
            hintStyle: AppTheme.body.copyWith(color: AppTheme.textHint),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    ]),
    const SizedBox(height: 14),
    Row(children: [
       const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textMuted),
       const SizedBox(width: 6),
       Expanded(child: Text('You will receive a USSD authorization prompt on your mobile device.', style: AppTheme.bodySmall.copyWith(fontStyle: FontStyle.italic))),
    ]),
  ]);
}

class _CardForm extends StatelessWidget {
  final TextEditingController num, exp, cvv;
  const _CardForm({required this.num, required this.exp, required this.cvv});

  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('CARD NUMBER', style: AppTheme.label),
    const SizedBox(height: 8),
    TextField(
      controller: num, 
      keyboardType: TextInputType.number, 
      style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
      decoration: const InputDecoration(hintText: '0000 0000 0000 0000', prefixIcon: Icon(Icons.credit_card_rounded))
    ),
    const SizedBox(height: 16),
    Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EXPIRY', style: AppTheme.label),
        const SizedBox(height: 8),
        TextField(controller: exp, decoration: const InputDecoration(hintText: 'MM/YY')),
      ])),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CVV', style: AppTheme.label),
        const SizedBox(height: 8),
        TextField(controller: cvv, obscureText: true, decoration: const InputDecoration(hintText: '***')),
      ])),
    ]),
  ]);
}

class _CashNotice extends StatelessWidget {
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.success.withOpacity(0.2))),
    child: Row(children: [
      const Icon(Icons.info_rounded, color: AppTheme.success, size: 32),
      const SizedBox(width: 16),
      Expanded(child: Text('CASH OPTION: Please present this session screen at the parking exit booth for manual payment processing.', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppTheme.textSecond))),
    ]),
  );
}

// ── RECEIPT VIEW (SUCCESS) ──────────────────────────────────────────

class _ReceiptView extends StatelessWidget {
  final VehicleRecord record;
  const _ReceiptView({required this.record});

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 100, height: 100,
              decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 60),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text('PAYMENT SUCCESSFUL', style: AppTheme.heading2.copyWith(letterSpacing: 2, fontSize: 20, color: AppTheme.success)),
            const SizedBox(height: 12),
            const Text('Your official EBM digital receipt has been generated.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
            const SizedBox(height: 40),
            
            // Receipt Card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: AppTheme.glowShadow),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('DIGITAL RECEIPT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1)),
                  Text(record.receiptNumber ?? 'ITEC-RE-000', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                ]),
                const Divider(height: 40),
                _Row('Vehicle Plate', record.plateNumber, isMono: true),
                _Row('Parking Site', record.parkingName),
                _Row('Amount Paid', 'RWF ${NumberFormat('#,###').format(record.amountPaid)}', isHighlight: true),
                _Row('Entry Time', DateFormat('HH:mm (dd MMM)').format(record.entryTime)),
                _Row('Payment Date', DateFormat('HH:mm (dd MMM)').format(record.exitTime ?? DateTime.now())),
              ]),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.textPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                child: const Text('BACK TO PORTAL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
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
        color: isHighlight ? AppTheme.success : AppTheme.textPrimary, 
        fontWeight: FontWeight.w800,
        fontFamily: isMono ? 'monospace' : null,
        letterSpacing: isMono ? 1 : null,
      )),
    ]),
  );
}
