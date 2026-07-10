import 'package:flutter/material.dart';

import 'package:country_code_picker/country_code_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _step = 1; // 1: Phone, 2: OTP, 3: Profile
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Step 1: Phone
  String _countryCode = '+250';
  final _phoneCtrl    = TextEditingController();
  final _usernameCtrl = TextEditingController();
  String _verificationPayload = '';

  // Step 2: OTP
  final _otpCtrl          = TextEditingController();
  String _registrationToken = '';

  // Step 3: Profile
  final _namesCtrl    = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    _otpCtrl.dispose();
    _namesCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _showDialog(String msg, {bool isError = true}) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: (isError ? AppTheme.danger : AppTheme.success).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                  color: isError ? AppTheme.danger : AppTheme.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isError ? 'Oops!' : 'Success!',
                style: AppTheme.heading2.copyWith(color: isError ? AppTheme.danger : AppTheme.success),
              ),
              const SizedBox(height: 8),
              Text(msg, textAlign: TextAlign.center, style: AppTheme.body.copyWith(color: AppTheme.textMuted)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isError ? AppTheme.danger : AppTheme.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initiateRegistration() async {
    final phone    = _phoneCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    if (phone.isEmpty) { _showDialog('Please enter your phone number'); return; }
    if (username.isEmpty) { _showDialog('Please enter a username'); return; }

    setState(() => _isLoading = true);
    final fullPhone = '$_countryCode$phone';
    final result = await AuthService.initiateRegister(fullPhone, username);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() {
        _verificationPayload = result['verification_payload'] ?? '';
        _step = 2;
      });
      _showDialog('OTP sent to $fullPhone', isError: false);
    } else {
      _showDialog(result['message'] ?? 'Failed to send OTP');
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 4) { _showDialog('Please enter a valid OTP'); return; }

    setState(() => _isLoading = true);
    final fullPhone = '$_countryCode${_phoneCtrl.text.trim()}';
    final result = await AuthService.verifyOtp(
      fullPhone, otp,
      verificationPayload: _verificationPayload,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() {
        _registrationToken = result['registration_token'] ?? '';
        _step = 3;
      });
    } else {
      _showDialog(result['message'] ?? 'Invalid OTP. Please try again.');
    }
  }

  Future<void> _completeRegistration() async {
    final names    = _namesCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (names.isEmpty || email.isEmpty || password.isEmpty) {
      _showDialog('Please fill in all fields to finish setting up your account.');
      return;
    }
    // The backend requires at least 6 characters — check it here so users
    // get an instant, clear message instead of a server rejection.
    if (password.length < 6) {
      _showDialog('Your password needs at least 6 characters. Please choose a longer one.');
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.completeRegister(
      username: _usernameCtrl.text.trim(),
      password: password,
      registrationToken: _registrationToken,
      otherInfo: {'names': names, 'email': email},
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (!mounted) return;
      await _showDialog('Account created successfully! Please sign in.', isError: false);
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      _showDialog(result['message'] ?? 'Registration failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarH = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Column(
        children: [
          // ── HERO HEADER ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: statusBarH + 12, bottom: 20),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: Column(
              children: [
                // Back + Title row
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_step > 1) {
                          setState(() => _step--);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'ITEC PARKING',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'SMART PARKING SOLUTIONS',
                  style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 2),
                ),
                const SizedBox(height: 16),

                // ── STEP INDICATORS ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final stepNum = i + 1;
                    final isActive = _step == stepNum;
                    final isDone   = _step > stepNum;
                    return Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isActive ? 36 : 28,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDone ? AppTheme.success : (isActive ? Colors.white : Colors.white30),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: isDone
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                              : Text(
                                  '$stepNum',
                                  style: TextStyle(
                                    color: isActive ? AppTheme.primary : Colors.white70,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                          ),
                        ),
                        if (i < 2)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 40, height: 2,
                            color: _step > stepNum ? AppTheme.success : Colors.white30,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  _step == 1 ? 'Phone Verification'
                  : _step == 2 ? 'OTP Confirmation'
                  : 'Profile Setup',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
                ),
              ],
            ),
          ),

          // ── SCROLLABLE CONTENT ───────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: _buildStep(),
              ),
            ),
          ),

          // ── SIGN IN LINK (always visible, no scroll needed) ────────
          if (_step == 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: RichText(
                  text: TextSpan(
                    style: AppTheme.body.copyWith(color: AppTheme.textMuted),
                    children: [
                      const TextSpan(text: 'Already have an account?  '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text('Sign In', style: AppTheme.body.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── FOOTER ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: AppTheme.primaryDeep,
            child: const Center(
              child: Text(
                'Copyright © 2026 ITEC Parking',
                style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 1:  return _buildPhoneStep();
      case 2:  return _buildOtpStep();
      default: return _buildProfileStep();
    }
  }

  // ─── STEP 1: Phone ──────────────────────────────────────────────────
  Widget _buildPhoneStep() => Column(
    key: const ValueKey(1),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Create Account', style: AppTheme.heading2.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      Text('Enter your phone number to get started', style: AppTheme.body.copyWith(color: AppTheme.textMuted)),
      const SizedBox(height: 32),

      const _FieldLabel(text: 'Username'),
      const SizedBox(height: 8),
      TextField(
        controller: _usernameCtrl,
        textInputAction: TextInputAction.next,
        style: _inputStyle,
        decoration: _inputDeco(hint: 'e.g. john_doe', icon: Icons.account_circle_outlined),
      ),
      const SizedBox(height: 20),

      const _FieldLabel(text: 'Phone Number'),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
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
                onSubmitted: (_) => _initiateRegistration(),
                style: _inputStyle,
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
          ],
        ),
      ),
      const SizedBox(height: 36),
      _PrimaryButton(text: 'Send OTP', isLoading: _isLoading, onPressed: _initiateRegistration),
    ],
  );

  // ─── STEP 2: OTP ────────────────────────────────────────────────────
  Widget _buildOtpStep() => Column(
    key: const ValueKey(2),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Verify OTP', style: AppTheme.heading2.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      RichText(
        text: TextSpan(
          style: AppTheme.body.copyWith(color: AppTheme.textMuted),
          children: [
            const TextSpan(text: 'We sent a code to  '),
            TextSpan(
              text: '$_countryCode${_phoneCtrl.text}',
              style: AppTheme.body.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      const SizedBox(height: 40),

      // Large OTP input
      Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 1.5),
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Center(
          child: TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            onSubmitted: (_) => _verifyOtp(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
              letterSpacing: 12,
            ),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '- - - - - -',
              hintStyle: TextStyle(
                fontSize: 24,
                color: AppTheme.textHint,
                letterSpacing: 8,
                fontWeight: FontWeight.w300,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: Text(
          'Enter the 6-digit code sent to your phone',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
        ),
      ),
      const SizedBox(height: 36),
      _PrimaryButton(text: 'Verify OTP', isLoading: _isLoading, onPressed: _verifyOtp),
      const SizedBox(height: 20),
      Center(
        child: TextButton.icon(
          onPressed: _isLoading ? null : _initiateRegistration,
          icon: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.primary),
          label: Text('Resend Code', style: AppTheme.body.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700)),
        ),
      ),
    ],
  );

  // ─── STEP 3: Profile ────────────────────────────────────────────────
  Widget _buildProfileStep() => Column(
    key: const ValueKey(3),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Complete Profile', style: AppTheme.heading2.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      Text('Almost there! Tell us a bit about yourself.', style: AppTheme.body.copyWith(color: AppTheme.textMuted)),
      const SizedBox(height: 32),

      const _FieldLabel(text: 'Full Name'),
      const SizedBox(height: 8),
      TextField(
        controller: _namesCtrl,
        textInputAction: TextInputAction.next,
        style: _inputStyle,
        decoration: _inputDeco(hint: 'John Doe', icon: Icons.person_outline_rounded),
      ),
      const SizedBox(height: 20),

      const _FieldLabel(text: 'Email Address'),
      const SizedBox(height: 8),
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        style: _inputStyle,
        decoration: _inputDeco(hint: 'john@example.com', icon: Icons.email_outlined),
      ),
      const SizedBox(height: 20),

      const _FieldLabel(text: 'Password'),
      const SizedBox(height: 8),
      TextField(
        controller: _passwordCtrl,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _completeRegistration(),
        style: _inputStyle,
        decoration: _inputDeco(
          hint: 'Create a strong password',
          icon: Icons.lock_outline_rounded,
          suffix: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppTheme.textMuted, size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        const Icon(Icons.info_outline_rounded, size: 13, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Text('Use at least 6 characters.', style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted)),
      ]),
      const SizedBox(height: 28),
      _PrimaryButton(text: 'Create Account', isLoading: _isLoading, onPressed: _completeRegistration),
    ],
  );

  TextStyle get _inputStyle => AppTheme.body.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w600,
    fontSize: 15,
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: AppTheme.label.copyWith(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.textSecond),
  );
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
          : Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
    ),
  );
}
