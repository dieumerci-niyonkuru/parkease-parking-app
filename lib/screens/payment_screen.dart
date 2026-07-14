import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/branded_loader.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

enum PayMethod { momo, airtel, card, cash, other }

class PaymentScreen extends StatefulWidget {
  final VehicleRecord record;
  final Future<VehicleRecord?> Function(VehicleRecord) onPay;
  const PaymentScreen({super.key, required this.record, required this.onPay});
  @override State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PayMethod? _method;
  bool      _paying  = false;
  bool      _done    = false;
  VehicleRecord? _receipt;

  String _countryCode = '+250';
  final _phoneCtrl = TextEditingController();
  
  final _cardNumCtrl = TextEditingController();
  final _expiryCtrl  = TextEditingController();
  final _cvvCtrl     = TextEditingController();

  @override void dispose() {
    _phoneCtrl.dispose(); _cardNumCtrl.dispose();
    _expiryCtrl.dispose(); _cvvCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => NumberFormat('#,##0', 'en').format(v.toInt());

  String _payStatus = '';

  Future<void> _pay(String payerPhone) async {
    final r = widget.record;

    if (r.dbId == null || r.pInId == null || (r.paymentType ?? '').isEmpty) {
      _snack('This vehicle can\'t be paid here right now. Please look up the plate again.', isError: true);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() { _paying = true; _payStatus = 'Sending payment request...'; });

    // 1) Initiate the mobile-money charge.
    final init = await ApiService.paymentInitiate(
      dbId: r.dbId!,
      plateNo: r.plateNumber,
      pInId: r.pInId!,
      paymentType: r.paymentType!,
      payerPhone: payerPhone,
    );
    if (!mounted) return;
    if (init['success'] != true) {
      setState(() { _paying = false; _payStatus = ''; });
      _snack(init['message']?.toString() ?? 'Couldn\'t start the payment. Please try again.', isError: true);
      return;
    }

    final reqRef = init['reqRef']?.toString();
    final dbId = (init['dbId'] as int?) ?? r.dbId!;
    if (reqRef == null) {
      setState(() { _paying = false; _payStatus = ''; });
      _snack('Couldn\'t start the payment. Please try again.', isError: true);
      return;
    }

    setState(() => _payStatus = 'Approve the prompt on $payerPhone...');

    // 2) Poll for completion (up to ~2 minutes). Returns the server-charged
    //    amount on success, or null on failure/timeout.
    final charged = await _pollStatus(dbId, reqRef);
    if (!mounted) return;

    if (charged == null) {
      setState(() { _paying = false; _payStatus = ''; });
      _snack('Payment not completed. If you were charged, it will reflect shortly.', isError: true);
      return;
    }

    // 3) Success → build the receipt using the EXACT amount the server charged
    //    (the authoritative API figure, reflecting the current parked time).
    final updated = await widget.onPay(r);
    if (!mounted) return;
    final base = updated ?? r;
    setState(() {
      _paying = false;
      _done = true;
      _receipt = charged > 0 ? base.copyWith(amountPaid: charged) : base;
      _payStatus = '';
    });
    HapticFeedback.heavyImpact();
    _snack('Payment successful!', isError: false);
  }

  // Polls /payment/status until SUCCESSFUL (returns the charged amount) or
  // FAILED/timeout (returns null).
  Future<double?> _pollStatus(int dbId, String reqRef) async {
    const maxAttempts = 24;      // 24 x 5s ≈ 2 minutes
    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return null;
      final st = await ApiService.paymentStatus(dbId, reqRef);
      final state = st['state']?.toString();
      if (state == 'SUCCESSFUL') {
        return (st['charged'] as double?) ?? (st['amount'] as double?) ?? 0;
      }
      if (state == 'FAILED' || state == 'CANCELLED') return null;
      if (mounted) setState(() => _payStatus = 'Waiting for confirmation... (${i + 1})');
    }
    return null;
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

  void _showMethodPicker() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Payment Method', style: AppTheme.heading3.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              _MethodOption(
                icon: Icons.phone_iphone_rounded, label: 'MTN MoMo',
                onTap: () { Navigator.pop(ctx); _onMethodSelected(PayMethod.momo); },
              ),
              _MethodOption(
                icon: Icons.phone_iphone_rounded, label: 'Airtel Money',
                onTap: () { Navigator.pop(ctx); _onMethodSelected(PayMethod.airtel); },
              ),
              _MethodOption(
                icon: Icons.credit_card_rounded, label: 'Bank Card',
                onTap: () { Navigator.pop(ctx); _onMethodSelected(PayMethod.card); },
              ),
              _MethodOption(
                icon: Icons.payments_rounded, label: 'Cash Payment',
                onTap: () { Navigator.pop(ctx); _onMethodSelected(PayMethod.cash); },
              ),
              _MethodOption(
                icon: Icons.more_horiz_rounded, label: 'Other / Not Listed',
                onTap: () { Navigator.pop(ctx); _onMethodSelected(PayMethod.other); },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('CANCEL', style: AppTheme.label.copyWith(color: AppTheme.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMethodSelected(PayMethod method) {
    setState(() => _method = method);
    if (method == PayMethod.momo || method == PayMethod.airtel || method == PayMethod.other) {
      _showPhoneEntry();
    } else if (method == PayMethod.card) {
      _showCardEntry();
    } else if (method == PayMethod.cash) {
      _showCashConfirmation();
    }
  }

  void _showCardEntry() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter Card Details', style: AppTheme.heading3.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Pay securely with your credit/debit card', style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted)),
              const SizedBox(height: 24),
              TextField(
                controller: _cardNumCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Card Number', prefixIcon: Icon(Icons.credit_card_rounded)),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextField(controller: _expiryCtrl, decoration: const InputDecoration(hintText: 'MM/YY'))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _cvvCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'CVV'))),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _snack('Card payment isn\'t available yet. Please use Mobile Money.', isError: true);
                  },
                  child: const Text('CONFIRM & PAY', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('CANCEL', style: AppTheme.label.copyWith(color: AppTheme.textMuted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCashConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.payments_rounded, size: 48, color: AppTheme.primary),
              const SizedBox(height: 16),
              Text('Cash Payment', style: AppTheme.heading3.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Text(
                'Please present this screen to the parking attendant at the exit booth to settle your fee in cash.',
                textAlign: TextAlign.center,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  child: const Text('UNDERSTOOD', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhoneEntry() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter Phone Number', style: AppTheme.heading3.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Prompt will be sent to this number', style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted)),
              const SizedBox(height: 24),
              Row(children: [
                Container(
                  decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(12)),
                  child: CountryCodePicker(
                    onChanged: (c) => setState(() => _countryCode = c.dialCode ?? '+250'),
                    initialSelection: 'RW', favorite: const ['+250', 'RW'],
                    textStyle: AppTheme.body.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl, keyboardType: TextInputType.phone,
                    autofocus: true,
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w900),
                    decoration: const InputDecoration(hintText: '78XXX XXXX'),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final num = _phoneCtrl.text.trim();
                    if (num.length < 8) {
                       _snack('Please enter a valid phone number.', isError: true);
                       return;
                    }
                    Navigator.pop(ctx);
                    _pay('$_countryCode$num');
                  },
                  child: const Text('CONFIRM & PAY', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('CANCEL', style: AppTheme.label.copyWith(color: AppTheme.textMuted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_done && _receipt != null) return _ReceiptView(record: _receipt!);

    final user = AuthService.user;
    final firstName = user?.names.split(' ').firstOrNull ?? 'Driver';
    final dateStr = DateFormat("EEEE, d MMMM").format(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        leadingWidth: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: const Center(
                child: Text('P', style: TextStyle(color: Color(0xFF7A5B40), fontSize: 18, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SECURE PAYMENT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                Text(firstName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, height: 1.1)),
                Text(dateStr, style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
            tooltip: 'Cancel Payment',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              // ── INVOICE CARD ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
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

              const SizedBox(height: 48),
              
              if (_paying)
                BrandedLoader(message: _payStatus.isEmpty ? 'Processing your payment...' : _payStatus)
              else ...[
                Text('CHOOSE PAYMENT METHOD', style: AppTheme.label.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 16),
                
                // ── SELECTION BUTTON ───────────────────────────
                GestureDetector(
                  onTap: _showMethodPicker,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primary, width: 2),
                      boxShadow: AppTheme.subtleShadow,
                    ),
                    child: Row(children: [
                      Icon(_method == null ? Icons.payment_rounded : _methodIcon(_method!), color: AppTheme.primary, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _method == null ? 'Select Payment Method' : _methodLabel(_method!),
                          style: AppTheme.body.copyWith(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary),
                    ]),
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity, height: 60,
                  child: ElevatedButton(
                    onPressed: _method == null ? _showMethodPicker : () => _showPhoneEntry(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 4,
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(_method == null ? Icons.touch_app_rounded : Icons.lock_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text(_method == null ? 'START PAYMENT' : 'PAY NOW', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ]),
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ],
              
              const SizedBox(height: 40),
              Center(child: Text('🔒 SECURE SSL ENCRYPTED TRANSACTION', style: AppTheme.label.copyWith(fontSize: 9, color: AppTheme.textHint, letterSpacing: 1))),
            ],
          ),
        ),
      ),
    );
  }

  IconData _methodIcon(PayMethod m) {
    switch (m) {
      case PayMethod.momo:   return Icons.phone_iphone_rounded;
      case PayMethod.airtel: return Icons.phone_iphone_rounded;
      case PayMethod.card:   return Icons.credit_card_rounded;
      case PayMethod.cash:   return Icons.payments_rounded;
      case PayMethod.other:  return Icons.more_horiz_rounded;
    }
  }

  String _methodLabel(PayMethod m) {
    switch (m) {
      case PayMethod.momo:   return 'MTN MoMo';
      case PayMethod.airtel: return 'Airtel Money';
      case PayMethod.card:   return 'Bank Card';
      case PayMethod.cash:   return 'Cash Payment';
      case PayMethod.other:  return 'Other / Not Listed';
    }
  }
}

class _MethodOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MethodOption({required this.icon, required this.label, required this.onTap});

  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgDeep,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(width: 16),
          Text(label, style: AppTheme.body.copyWith(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textHint, size: 14),
        ]),
      ),
    ),
  );
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
    decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.success.withValues(alpha: 0.2))),
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
                const Divider(height: 32),

                // ── PARKING ───────────────────────────────
                const _SectionLabel('PARKING'),
                _Row('Parking Site', record.parkingName),
                if (record.parkingAddress.isNotEmpty) _Row('Address', record.parkingAddress),
                if (record.spotNumber.isNotEmpty && record.spotNumber != '—') _Row('Slot', record.spotNumber),

                // ── VEHICLE & SESSION ─────────────────────
                const _SectionLabel('SESSION'),
                _Row('Vehicle Plate', record.plateNumber, isMono: true),
                _Row('Entry Time', DateFormat('HH:mm · dd MMM yyyy').format(record.entryTime)),
                _Row('Exit / Paid', DateFormat('HH:mm · dd MMM yyyy').format(record.exitTime ?? DateTime.now())),
                _Row('Duration', record.durationDisplay),

                // ── PAYMENT ───────────────────────────────
                const _SectionLabel('PAYMENT'),
                _Row('Method', 'Mobile Money'),
                _Row('Status', 'PAID'),
                _Row('Amount Paid', 'RWF ${NumberFormat('#,###').format(record.amountPaid ?? record.totalAmount)}', isHighlight: true),
              ]),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.textPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
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
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label, style: AppTheme.bodySmall)),
      Expanded(child: Text(value, textAlign: TextAlign.right, style: TextStyle(
        color: isHighlight ? AppTheme.success : AppTheme.textPrimary,
        fontSize: isHighlight ? 16 : 13,
        fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w800,
        fontFamily: isMono ? 'monospace' : null,
        letterSpacing: isMono ? 1 : null,
      ))),
    ]),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: AppTheme.label.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 9)),
    ),
  );
}
