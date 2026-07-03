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

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      ),
    );
  }

  Future<void> _initiateRegistration() async {
    final phone = _phoneCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    if (phone.isEmpty || username.isEmpty) {
      _showSnack('Please enter your phone number and username');
      return;
    }

    setState(() => _isLoading = true);
    final fullPhone = '$_countryCode$phone';
    final result = await AuthService.initiateRegister(fullPhone, username: username);
    
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
    final phone = '$_countryCode${_phoneCtrl.text.trim()}';
    if (otp.length < 4) {
      _showSnack('Please enter a valid OTP');
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.verifyOtp(phone, otp);
    
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
    final password = _passwordCtrl.text;

    if (names.isEmpty || password.isEmpty) {
      _showSnack('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.completeRegister(
      username: _usernameCtrl.text.trim(),
      password: password,
      otherInfo: names,
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
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 4,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (_step > 1) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          children: [
            const Text('ITEC PARKING', style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.w900)),
            Text(_stepTitle, style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 0.5)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),
              const SizedBox(height: 60),
              
              // ── Contact & Help Footer ──────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                ),
                child: Column(children: [
                  Text('NEED ASSISTANCE?', style: AppTheme.label.copyWith(letterSpacing: 2, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                  const SizedBox(height: 16),
                  const _ContactRow(Icons.phone_in_talk_rounded, 'Call Support: +250 788 123 456'),
                  const SizedBox(height: 12),
                  const _ContactRow(Icons.alternate_email_rounded, 'Email: support@iteccone.com'),
                ]),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 32),
              Center(
                child: Text('© 2026 ITEC Parking · Rwanda',
                  style: AppTheme.label.copyWith(color: AppTheme.textHint, fontWeight: FontWeight.bold, fontSize: 10)),
              ).animate().fadeIn(delay: 800.ms),
              const SizedBox(height: 20),
            ],
          ),
        ),
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
        const SizedBox(height: 48),

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
        const SizedBox(height: 20),

        Text('Username', style: AppTheme.label),
        const SizedBox(height: 8),
        TextField(
          controller: _usernameCtrl,
          style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Choose a username',
            prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
          ),
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
  final String text;
  const _ContactRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 10),
        Text(text, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
