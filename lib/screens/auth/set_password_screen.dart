import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});
  @override State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _setPassword() async {
    final current  = _currentCtrl.text;
    final password = _passwordCtrl.text;
    final confirm  = _confirmCtrl.text;

    if (current.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showMsg('Please fill in all fields');
      return;
    }
    if (password.length < 6) {
      _showMsg('Your new password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      _showMsg('Your new passwords do not match');
      return;
    }
    if (current == password) {
      _showMsg('Your new password must be different from your current one');
      return;
    }

    final identifier = (AuthService.user?.phone.isNotEmpty ?? false)
        ? AuthService.user!.phone
        : (AuthService.user?.email ?? '');
    if (identifier.isEmpty) {
      _showMsg('We couldn\'t verify your account. Please sign in again.');
      return;
    }

    setState(() => _isLoading = true);

    // 1) Verify the current password by re-authenticating.
    final verify = await AuthService.login(identifier, current);
    if (!mounted) return;
    if (verify['success'] != true) {
      setState(() => _isLoading = false);
      _showMsg('Your current password is incorrect.');
      return;
    }

    // 2) Set the new password.
    final result = await AuthService.setPassword(password);
    if (!mounted) return;
    if (result['success'] != true) {
      setState(() => _isLoading = false);
      _showMsg(result['message'] ?? 'Couldn\'t change your password. Please try again.');
      return;
    }

    // 3) Refresh the session + stored credentials with the new password.
    await AuthService.login(identifier, password);
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showMsg('Password changed successfully!', isError: false);
  }

  void _showMsg(String msg, {bool isError = true}) {
    showDialog(
      context: context,
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
              const SizedBox(height: 14),
              Text(
                isError ? 'Oops!' : 'Success',
                style: AppTheme.heading2.copyWith(color: isError ? AppTheme.danger : AppTheme.success),
              ),
              const SizedBox(height: 8),
              Text(msg, textAlign: TextAlign.center, style: AppTheme.body.copyWith(color: AppTheme.textMuted)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (!isError) Navigator.pop(context);
                  },
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

  @override
  void dispose() {
    _currentCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 32),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: Column(
              children: [
                Row(children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                  const Expanded(child: Center(child: Text('ITEC PARKING', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 4)))),
                  const SizedBox(width: 28),
                ]),
                const SizedBox(height: 16),
                const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text('Change Password', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 14),
                  Text('Enter your current password, then choose a new one to keep your account secure.', style: AppTheme.body.copyWith(color: AppTheme.textMuted)),
                  const SizedBox(height: 18),
                  Text('CURRENT PASSWORD', style: AppTheme.label.copyWith(fontWeight: FontWeight.w800, fontSize: 10)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _currentCtrl,
                    obscureText: _obscureCurrent,
                    textInputAction: TextInputAction.next,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Your existing password',
                      filled: true, fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.lock_clock_rounded, color: AppTheme.textMuted, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textMuted, size: 20),
                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('NEW PASSWORD', style: AppTheme.label.copyWith(fontWeight: FontWeight.w800, fontSize: 10)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'At least 6 characters',
                      filled: true, fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textMuted, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('CONFIRM PASSWORD', style: AppTheme.label.copyWith(fontWeight: FontWeight.w800, fontSize: 10)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmCtrl,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _setPassword(),
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Re-enter your password',
                      filled: true, fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textMuted, size: 20),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _setPassword,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 2),
                      child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('SET PASSWORD', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
