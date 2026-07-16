import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

// The API has no dedicated "forgot password" endpoint — the only way to
// regain access is to prove ownership of the phone number already on the
// account via OTP (the same public reclaim mechanism used during
// registration), then set a new password for that account.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 1; // 1: Phone, 2: OTP, 3: New password
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _fieldError;

  String _countryCode = '+250';
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  String get _fullPhone => '$_countryCode${_phoneCtrl.text.trim()}';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      setState(() => _fieldError = 'Please enter the phone number on your account.');
      return;
    }
    setState(() { _fieldError = null; _isLoading = true; });

    final result = await AuthService.initiateReclaimForRegistration(_fullPhone);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (result['verification_type'] == 'reclaim') {
        setState(() => _step = 2);
      } else {
        // The server doesn't recognise this phone as belonging to an
        // existing account — there's nothing to reset.
        setState(() => _fieldError = 'We couldn\'t find an account with that phone number.');
      }
    } else if (result['can_reclaim'] == true) {
      // The phone is on file but not as the account's verified primary
      // number — the server will actually send a reclaim code for this.
      setState(() => _step = 2);
    } else {
      // The server has told us explicitly (can_reclaim: false) that it will
      // not send an OTP for this phone — it's already a verified primary
      // number, and self-service reset via OTP is blocked for security.
      // Routing to the OTP screen here would just strand the user waiting
      // for a code that never arrives.
      setState(() => _fieldError = result['is_primary'] == true
          ? 'For your security, this account can\'t be reset from the app. Please contact support to regain access.'
          : (result['message'] ?? 'Could not send a code. Please try again.'));
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 4) {
      setState(() => _fieldError = 'Please enter the code we sent you.');
      return;
    }
    setState(() { _fieldError = null; _isLoading = true; });

    final result = await AuthService.verifyReclaimOtp(_fullPhone, otp);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() => _step = 3);
    } else {
      setState(() => _fieldError = result['message'] ?? 'That code didn\'t work. Please try again.');
    }
  }

  Future<void> _setNewPassword() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;

    if (username.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _fieldError = 'Please fill in all fields.');
      return;
    }
    if (password.length < 6) {
      setState(() => _fieldError = 'Your password needs at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _fieldError = 'Your passwords don\'t match.');
      return;
    }
    setState(() { _fieldError = null; _isLoading = true; });

    final result = await AuthService.completeRegister(username: username, password: password);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSuccessAndReturn();
    } else {
      setState(() => _fieldError = result['message'] ?? 'Could not update your password. Please try again.');
    }
  }

  Future<void> _showSuccessAndReturn() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.success, size: 40),
              ),
              const SizedBox(height: 14),
              Text('Password Updated!', style: AppTheme.heading2.copyWith(color: AppTheme.success)),
              const SizedBox(height: 8),
              Text('You can now sign in with your new password.', textAlign: TextAlign.center,
                style: AppTheme.body.copyWith(color: AppTheme.textMuted)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('BACK TO SIGN IN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, bottom: 20),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: Column(
              children: [
                Row(children: [
                  IconButton(
                    onPressed: () => _step == 1 ? Navigator.pop(context) : setState(() { _step -= 1; _fieldError = null; }),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    tooltip: 'Back',
                  ),
                  const Expanded(child: Center(child: Text('ITEC PARKING',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 3)))),
                  const SizedBox(width: 28),
                ]),
                const SizedBox(height: 8),
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 28),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 10),
                const Text('Reset Password', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final stepNum = i + 1;
                    final isActive = _step == stepNum;
                    final isDone = _step > stepNum;
                    return Row(children: [
                      Container(
                        width: isActive ? 28 : 24, height: 28,
                        decoration: BoxDecoration(
                          color: isDone ? AppTheme.success : (isActive ? Colors.white : Colors.white.withValues(alpha: 0.28)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: isDone
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                            : Text('$stepNum', style: TextStyle(color: isActive ? AppTheme.primary : Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                      ),
                      if (i < 2)
                        Container(width: 28, height: 2, color: _step > stepNum ? AppTheme.success : Colors.white.withValues(alpha: 0.4), margin: const EdgeInsets.symmetric(horizontal: 4)),
                    ]);
                  }),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                child: _buildStep(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 1: return _buildPhoneStep();
      case 2: return _buildOtpStep();
      default: return _buildPasswordStep();
    }
  }

  Widget _buildPhoneStep() => Column(
    key: const ValueKey(1),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('No worries — it happens!', style: AppTheme.heading3.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      Text('Enter the phone number linked to your account and we\'ll send you a verification code.',
        style: AppTheme.body.copyWith(color: AppTheme.textMuted)),
      const SizedBox(height: 18),

      Text('PHONE NUMBER', style: AppTheme.label.copyWith(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.textSecond)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _fieldError != null ? AppTheme.danger : AppTheme.border)),
        child: Row(children: [
          CountryCodePicker(
            onChanged: (code) => setState(() => _countryCode = code.dialCode ?? '+250'),
            initialSelection: 'RW',
            favorite: const ['+250', 'RW', '+254', 'KE'],
            showCountryOnly: false,
            showOnlyCountryWhenClosed: false,
            alignLeft: false,
            textStyle: AppTheme.body.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
          ),
          Container(width: 1, height: 36, color: AppTheme.border),
          Expanded(
            child: TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _sendOtp(),
              onChanged: (_) { if (_fieldError != null) setState(() => _fieldError = null); },
              style: AppTheme.body.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
              decoration: InputDecoration(
                hintText: '780 000 000',
                hintStyle: AppTheme.body.copyWith(color: AppTheme.textHint),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
            ),
          ),
        ]),
      ),
      if (_fieldError != null) ...[
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(_fieldError!, style: AppTheme.bodySmall.copyWith(color: AppTheme.danger, fontWeight: FontWeight.w600))),
        ]),
      ],
      const SizedBox(height: 18),
      _PrimaryButton(text: 'SEND CODE', isLoading: _isLoading, onPressed: _sendOtp),
      const SizedBox(height: 16),
      Center(
        child: RichText(
          text: TextSpan(
            style: AppTheme.body.copyWith(color: AppTheme.textMuted),
            children: [
              const TextSpan(text: 'Remembered it?  '),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('Back to Sign In', style: AppTheme.body.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildOtpStep() => Column(
    key: const ValueKey(2),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Verify Your Phone', style: AppTheme.heading3.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      RichText(
        text: TextSpan(
          style: AppTheme.body.copyWith(color: AppTheme.textMuted),
          children: [
            const TextSpan(text: 'We sent a code to  '),
            TextSpan(text: _fullPhone, style: AppTheme.body.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _fieldError != null ? AppTheme.danger : AppTheme.border, width: 1.5),
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Center(
          child: TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            onSubmitted: (_) => _verifyOtp(),
            onChanged: (_) { if (_fieldError != null) setState(() => _fieldError = null); },
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: 12),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '- - - - - -',
              hintStyle: TextStyle(fontSize: 24, color: AppTheme.textHint, letterSpacing: 8, fontWeight: FontWeight.w300),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
      ),
      if (_fieldError != null) ...[
        const SizedBox(height: 8),
        Center(child: Text(_fieldError!, style: AppTheme.bodySmall.copyWith(color: AppTheme.danger, fontWeight: FontWeight.w600))),
      ] else ...[
        const SizedBox(height: 12),
        Center(child: Text('Enter the 6-digit code sent to your phone', style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted))),
      ],
      const SizedBox(height: 20),
      _PrimaryButton(text: 'VERIFY CODE', isLoading: _isLoading, onPressed: _verifyOtp),
      const SizedBox(height: 16),
      Center(
        child: TextButton.icon(
          onPressed: _isLoading ? null : _sendOtp,
          icon: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.primary),
          label: Text('Resend Code', style: AppTheme.body.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700)),
        ),
      ),
    ],
  );

  Widget _buildPasswordStep() => Column(
    key: const ValueKey(3),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Set a New Password', style: AppTheme.heading3.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      Text('Confirm your username and choose a new password.', style: AppTheme.body.copyWith(color: AppTheme.textMuted)),
      const SizedBox(height: 18),

      Text('USERNAME', style: AppTheme.label.copyWith(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.textSecond)),
      const SizedBox(height: 8),
      TextField(
        controller: _usernameCtrl,
        textInputAction: TextInputAction.next,
        onChanged: (_) { if (_fieldError != null) setState(() => _fieldError = null); },
        style: AppTheme.body.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
        decoration: _inputDeco(hint: 'Your existing username', icon: Icons.account_circle_outlined),
      ),
      const SizedBox(height: 14),

      Text('NEW PASSWORD', style: AppTheme.label.copyWith(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.textSecond)),
      const SizedBox(height: 8),
      TextField(
        controller: _passwordCtrl,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.next,
        onChanged: (_) { if (_fieldError != null) setState(() => _fieldError = null); },
        style: AppTheme.body.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
        decoration: _inputDeco(
          hint: 'Create a new password',
          icon: Icons.lock_outline_rounded,
          suffix: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textMuted, size: 20),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
      const SizedBox(height: 14),

      Text('CONFIRM PASSWORD', style: AppTheme.label.copyWith(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.textSecond)),
      const SizedBox(height: 8),
      TextField(
        controller: _confirmPasswordCtrl,
        obscureText: _obscureConfirm,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _setNewPassword(),
        onChanged: (_) { if (_fieldError != null) setState(() => _fieldError = null); },
        style: AppTheme.body.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
        decoration: _inputDeco(
          hint: 'Re-type your new password',
          icon: Icons.lock_outline_rounded,
          suffix: IconButton(
            icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textMuted, size: 20),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
      ),
      if (_fieldError != null) ...[
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(_fieldError!, style: AppTheme.bodySmall.copyWith(color: AppTheme.danger, fontWeight: FontWeight.w600))),
        ]),
      ] else ...[
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.info_outline_rounded, size: 13, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Text('Use at least 6 characters.', style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted)),
        ]),
      ],
      const SizedBox(height: 18),
      _PrimaryButton(text: 'UPDATE PASSWORD', isLoading: _isLoading, onPressed: _setNewPassword),
    ],
  );

  InputDecoration _inputDeco({required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
      hintStyle: AppTheme.body.copyWith(color: AppTheme.textHint),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;
  const _PrimaryButton({required this.text, required this.isLoading, this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
      child: isLoading
        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
        : Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
    ),
  );
}
