import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  final _phoneCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  String _verificationPayload = '';

  // Step 2: OTP
  final _otpCtrl = TextEditingController();
  String _registrationToken = '';

  // Step 3: Profile
  final _namesCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
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

  Future<void> _showSnack(String msg, {bool isError = true}) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: isError ? AppTheme.danger : AppTheme.success,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(isError ? 'ERROR' : 'SUCCESS', 
              style: AppTheme.heading3.copyWith(
                letterSpacing: 2, 
                color: isError ? AppTheme.danger : AppTheme.success
              )),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: AppTheme.body.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isError ? AppTheme.danger : AppTheme.success,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _initiateRegistration() async {
    final phone = _phoneCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    if (phone.isEmpty) {
      _showSnack('Please enter your phone number');
      return;
    }
    if (username.isEmpty) {
      _showSnack('Please enter a username');
      return;
    }

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
      _showSnack('OTP sent to $fullPhone', isError: false);
    } else {
      _showSnack(result['message'] ?? 'Failed to send OTP');
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 4) {
      _showSnack('Please enter a valid OTP');
      return;
    }

    setState(() => _isLoading = true);
    final fullPhone = '$_countryCode${_phoneCtrl.text.trim()}';
    final result = await AuthService.verifyOtp(fullPhone, otp);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() {
        _registrationToken = result['registration_token'] ?? '';
        _step = 3;
      });
    } else {
      _showSnack(result['message'] ?? 'Invalid OTP');
    }
  }

  Future<void> _completeRegistration() async {
    final names = _namesCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (names.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnack('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.completeRegister(
      username: _usernameCtrl.text.trim(),
      password: password,
      otherInfo: {
        'names': names,
        'email': email,
      },
    );
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSnack('Registration successful', isError: false);
      Navigator.of(context).pushReplacementNamed('/main');
    } else {
      _showSnack(result['message'] ?? 'Registration failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Column(
        children: [
          // ── BRANDED HEADER ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 24),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      onPressed: () {
                        if (_step > 1) setState(() => _step--);
                        else Navigator.pop(context);
                      },
                    ),
                    const Expanded(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(right: 48), // Balancing for back button
                          child: Text('ITEC PARKING', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 4)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Smart Parking Solutions'.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.w700)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildCurrentStep(),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // ── BRANDED FOOTER ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: AppTheme.primary,
            child: const Center(
              child: Text('Copyright © 2026 ITEC Parking', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case 1: return 'ACCOUNT INITIALIZATION';
      case 2: return 'SECURITY VERIFICATION';
      case 3: return 'PROFILE COMPLETION';
      default: return 'REGISTRATION';
    }
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1:
        return _buildPhoneStep().animate().fadeIn(duration: 300.ms).slideX(begin: 0.1);
      case 2:
        return _buildOtpStep().animate().fadeIn(duration: 300.ms).slideX(begin: 0.1);
      case 3:
        return _buildProfileStep().animate().fadeIn(duration: 300.ms).slideX(begin: 0.1);
      default:
        return const SizedBox();
    }
  }

  Widget _buildPhoneStep() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Create Account',
          style: AppTheme.heading1,
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your phone number to continue',
          style: AppTheme.body,
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 32),

        Text('Username', style: AppTheme.label),
        const SizedBox(height: 8),
        TextField(
          controller: _usernameCtrl,
          style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'e.g. john_doe',
            prefixIcon: Icon(Icons.account_circle_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 20),

        Text('Phone Number', style: AppTheme.label),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: CountryCodePicker(
                onChanged: (code) {
                  setState(() {
                    _countryCode = code.dialCode ?? '+250';
                  });
                },
                initialSelection: 'RW',
                favorite: const ['+250', 'RW', '+254', 'KE'],
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                alignLeft: false,
                textStyle: AppTheme.body.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'e.g. 780000000',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        _buildPrimaryButton(
          text: 'Continue',
          onPressed: _isLoading ? null : _initiateRegistration,
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verify OTP',
          style: AppTheme.heading1,
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a code to $_countryCode${_phoneCtrl.text}',
          style: AppTheme.body,
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 48),

        Text('Enter OTP', style: AppTheme.label),
        const SizedBox(height: 8),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: AppTheme.heading1.copyWith(letterSpacing: 8.0, color: AppTheme.textPrimary),
          maxLength: 6,
          decoration: const InputDecoration(
            counterText: '',
            hintText: '••••••',
          ),
        ),
        const SizedBox(height: 32),

        _buildPrimaryButton(
          text: 'Verify',
          onPressed: _isLoading ? null : _verifyOtp,
        ),
      ],
    );
  }

  Widget _buildProfileStep() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Complete Profile',
          style: AppTheme.heading1,
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us a bit about yourself',
          style: AppTheme.body,
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 32),

        Text('Full Name', style: AppTheme.label),
        const SizedBox(height: 8),
        TextField(
          controller: _namesCtrl,
          style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'John Doe',
            prefixIcon: Icon(Icons.person_outline, size: 20),
          ),
        ),
        const SizedBox(height: 20),

        Text('Email Address', style: AppTheme.label),
        const SizedBox(height: 8),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'john.doe@example.com',
            prefixIcon: Icon(Icons.email_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 20),

        Text('Password', style: AppTheme.label),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Create a strong password',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.textMuted,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 32),

        _buildPrimaryButton(
          text: 'Complete Registration',
          onPressed: _isLoading ? null : _completeRegistration,
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({required String text, required VoidCallback? onPressed}) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(text, style: AppTheme.heading4.copyWith(color: Colors.white)),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  const _ContactRow(this.icon, this.label, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.label.copyWith(fontSize: 9, color: AppTheme.textMuted)),
              const SizedBox(height: 2),
              Text(text, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
