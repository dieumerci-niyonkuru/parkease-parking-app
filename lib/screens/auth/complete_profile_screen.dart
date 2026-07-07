import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../main_layout.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _save() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      _showError('Please enter a valid phone number.');
      return;
    }

    setState(() => _isLoading = true);
    // Simulate updating profile with phone number
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // In production, you would call an API like: 
    // await AuthService.updateProfile(phone: phone);
    
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainLayout()),
      (route) => false,
    );
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Required Info'),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
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
            child: Column(
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
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ACTIVATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ).animate().scale(curve: Curves.easeOutBack),
        ),
      ),
    );
  }
}
