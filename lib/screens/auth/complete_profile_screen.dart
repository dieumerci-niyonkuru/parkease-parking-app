import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../main_layout.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  int _step = 1; // 1: enter phone, 2: enter OTP
  final _otpCtrl = TextEditingController();
  String _verificationPayload = '';
  String _phoneNumber = '';

  String _countryCode = '+250';

  Future<void> _initiateLink() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      _showError('Please enter a valid phone number.');
      return;
    }

    final fullPhone = phone.startsWith('+') ? phone : '$_countryCode$phone';

    setState(() => _isLoading = true);
    final result = await AuthService.phoneLinkInitiate(fullPhone);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() {
        _verificationPayload = result['verification_payload'] ?? '';
        _phoneNumber = fullPhone;
        _step = 2;
      });
    } else {
      _showError(result['message'] ?? 'Failed to send OTP.');
    }
  }

  Future<void> _verifyAndComplete() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 4) {
      _showError('Please enter a valid OTP.');
      return;
    }

    setState(() => _isLoading = true);
    final password = _passwordCtrl.text.trim();
    final result = await AuthService.phoneLinkVerify(
      _phoneNumber, otp,
      password: password.isNotEmpty ? password : null,
      verificationPayload: _verificationPayload,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainLayout()),
        (route) => false,
      );
    } else {
      _showError(result['message'] ?? 'Invalid OTP.');
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Required Info', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  @override void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: _step == 1 ? _buildPhoneStep() : _buildOtpStep(),
            ),
          ).animate().scale(curve: Curves.easeOutBack),
        ),
      ),
    );
  }

  Widget _buildPhoneStep() => Column(
    key: const ValueKey(1),
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.contact_phone_rounded, color: Color(0xFF7A5B40), size: 64),
      const SizedBox(height: 24),
      const Text('One Last Step!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      Text(
        'To use ITEC Parking services and view receipts, please link your phone number to your account.',
        textAlign: TextAlign.center,
        style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
      ),
      const SizedBox(height: 32),
      TextField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2),
        decoration: const InputDecoration(
          hintText: '07XXXXXXXX',
          prefixIcon: Icon(Icons.phone_android_rounded),
        ),
      ),
      const SizedBox(height: 8),
      CountryCodePicker(
        onChanged: (c) => setState(() => _countryCode = c.dialCode ?? '+250'),
        initialSelection: 'RW',
        favorite: const ['+250', 'RW'],
        textStyle: AppTheme.body.copyWith(fontWeight: FontWeight.w800),
        showFlag: true,
        showDropDownButton: true,
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _passwordCtrl,
        obscureText: !_showPassword,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Set password (optional)',
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
        ),
      ),
      const SizedBox(height: 32),
      SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _initiateLink,
          child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('SEND OTP', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ),
    ],
  );

  Widget _buildOtpStep() => Column(
    key: const ValueKey(2),
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.sms_rounded, color: Color(0xFF7A5B40), size: 64),
      const SizedBox(height: 24),
      const Text('Verify OTP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      Text(
        'Enter the code sent to $_phoneNumber',
        textAlign: TextAlign.center,
        style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
      ),
      const SizedBox(height: 32),
      TextField(
        controller: _otpCtrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 6,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 12),
        decoration: const InputDecoration(
          counterText: '',
          hintText: '- - - - - -',
          hintStyle: TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w300),
        ),
      ),
      const SizedBox(height: 32),
      SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _verifyAndComplete,
          child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('VERIFY & ACTIVATE', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ),
    ],
  );
}
