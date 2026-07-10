import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../utils/app_utils.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;        // switches to the "check your inbox" success view
  String? _fieldError;       // inline validation message under the field

  Future<void> _resetPassword() async {
    final username = _usernameCtrl.text.trim();
    // Inline validation — friendlier than a popup for a simple empty field.
    if (username.isEmpty) {
      setState(() => _fieldError = 'Please enter your username, phone or email.');
      return;
    }
    setState(() { _fieldError = null; _isLoading = true; });

    try {
      final resp = await ApiService.post('/auth/password/reset', body: {'username': username});

      if (!mounted) return;
      setState(() => _isLoading = false);

      Map<String, dynamic> data = {};
      try { data = jsonDecode(resp.body) as Map<String, dynamic>; } catch (_) {}

      // We intentionally show the same friendly confirmation whether or not the
      // account exists — this avoids leaking which accounts are registered and
      // is the standard, user-friendly behaviour for password resets.
      if (resp.statusCode == 200 || resp.statusCode == 202 || resp.statusCode == 404) {
        setState(() => _sent = true);
      } else {
        setState(() => _fieldError = data['message']?.toString() ?? 'We couldn\'t start the reset. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _fieldError = AppUtils.friendlyNetworkError(); });
    }
  }

  @override void dispose() { _usernameCtrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Column(
        children: [
          // ── HERO HEADER ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, bottom: 16),
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
                    tooltip: 'Back to Sign In',
                  ),
                  const Expanded(child: Center(child: Text('ITEC PARKING',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 3)))),
                  const SizedBox(width: 48),
                ]),
                const SizedBox(height: 8),
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(_sent ? Icons.mark_email_read_rounded : Icons.lock_reset_rounded, color: Colors.white, size: 28),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 10),
                Text(_sent ? 'Check Your Inbox' : 'Reset Password',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
          ),

          // ── BODY ────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: _sent ? _buildSentView() : _buildFormView(),
            ),
          ),
        ],
      ),
    );
  }

  // ── FORM VIEW ─────────────────────────────────────────────────────
  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('No worries — it happens!', style: AppTheme.heading3.copyWith(fontWeight: FontWeight.w900))
          .animate().fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 6),
        Text('Enter the username, phone number, or email linked to your account and we\'ll help you get back in.',
          style: AppTheme.body.copyWith(color: AppTheme.textMuted)).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 28),

        Text('USERNAME / PHONE / EMAIL', style: AppTheme.label.copyWith(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.textSecond)),
        const SizedBox(height: 8),
        TextField(
          controller: _usernameCtrl,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _resetPassword(),
          onChanged: (_) { if (_fieldError != null) setState(() => _fieldError = null); },
          style: AppTheme.body.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
          decoration: _inputDeco(
            hint: 'e.g. john_doe or 078...',
            icon: Icons.person_outline_rounded,
            hasError: _fieldError != null,
          ),
        ).animate().fadeIn(delay: 150.ms),

        // Inline error / helper line
        if (_fieldError != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 16),
            const SizedBox(width: 6),
            Expanded(child: Text(_fieldError!, style: AppTheme.bodySmall.copyWith(color: AppTheme.danger, fontWeight: FontWeight.w600))),
          ]),
        ],

        const SizedBox(height: 28),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Text('SEND RESET INSTRUCTIONS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
          ),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 24),
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
  }

  // ── SUCCESS VIEW ──────────────────────────────────────────────────
  Widget _buildSentView() {
    final target = _usernameCtrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'If an account matches "$target", reset instructions are on the way. Please check your messages and email.',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecond, fontWeight: FontWeight.w600, height: 1.4),
              ),
            ),
          ]),
        ).animate().fadeIn().slideY(begin: 0.1),

        const SizedBox(height: 20),
        Text('Didn\'t get anything?', style: AppTheme.body.copyWith(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        Text('Give it a minute, then check your spam folder. You can also try again with a different username or number.',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted)),

        const SizedBox(height: 28),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.login_rounded, size: 20),
            label: const Text('BACK TO SIGN IN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: () => setState(() => _sent = false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textMuted,
              side: const BorderSide(color: AppTheme.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('TRY A DIFFERENT ACCOUNT', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3)),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDeco({required String hint, required IconData icon, Widget? suffix, bool hasError = false}) {
    final borderColor = hasError ? AppTheme.danger : AppTheme.border;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      prefixIcon: Icon(icon, color: hasError ? AppTheme.danger : AppTheme.textMuted, size: 20),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: hasError ? AppTheme.danger : AppTheme.primary, width: 2)),
      hintStyle: AppTheme.body.copyWith(color: AppTheme.textHint),
    );
  }
}
