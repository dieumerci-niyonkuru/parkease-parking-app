import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../theme/app_theme.dart';
import '../services/phone_service.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});
  @override State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  List<PhoneNumber> _phones = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final phones = await PhoneService.getPhones();
    if (!mounted) return;
    setState(() { _phones = phones; _loading = false; });
  }

  void _showReclaim()  => _showAddDialog(title: 'Reclaim Number', mode: 'reclaim');
  void _showVerifyAdd() => _showAddDialog(title: 'Add & Verify', mode: 'verify');

  Future<void> _deletePhone(PhoneNumber ph) async {
    if (ph.isPrimary) {
      _snack('Cannot delete your primary number.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text('Delete Number?', style: AppTheme.heading3),
        content: Text('Remove ${ph.phone} from your account?',
            style: AppTheme.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: AppTheme.body.copyWith(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: AppTheme.body.copyWith(
                    color: AppTheme.danger, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await PhoneService.deletePhone(ph.id);
    if (!mounted) return;
    if (result['success'] == true) {
      _snack('Number removed.', isError: false);
      _load();
    } else {
      _snack(result['message'] ?? 'Failed to delete.');
    }
  }

  void _snack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
    ));
  }

  void _showAddDialog({required String title, required String mode}) {
    String countryCode = '+250';
    final phoneCtrl    = TextEditingController();
    final otpCtrl      = TextEditingController();
    bool loading  = false;
    bool otpSent  = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(title, style: AppTheme.heading3),
                const SizedBox(height: 6),
                Text(
                  mode == 'verify'
                        ? 'Add a number and verify it via OTP.'
                        : 'Reclaim a number that was registered by someone else.',
                  style: AppTheme.body,
                ),
                const SizedBox(height: 16),

                if (!otpSent) ...[
                  Text('Phone Number', style: AppTheme.label),
                  const SizedBox(height: 8),
                  Row(children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        color: AppTheme.bgSurface,
                      ),
                      child: CountryCodePicker(
                        onChanged: (c) =>
                            countryCode = c.dialCode ?? '+250',
                        initialSelection: 'RW',
                        favorite: const ['+250', 'RW'],
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        alignLeft: false,
                        textStyle: AppTheme.body.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: AppTheme.body
                            .copyWith(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                            hintText: 'e.g. 780000000'),
                      ),
                    ),
                  ]),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.07),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          color: AppTheme.primary, size: 18),
                      const SizedBox(width: 10),
                      Text('OTP sent to $countryCode${phoneCtrl.text}',
                          style:
                              AppTheme.body.copyWith(color: AppTheme.primary)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Text('Enter OTP', style: AppTheme.label),
                  const SizedBox(height: 8),
                  TextField(
                    controller: otpCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: AppTheme.heading2
                        .copyWith(letterSpacing: 8, color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '••••••',
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (phoneCtrl.text.trim().isEmpty) return;
                            setModal(() => loading = true);

                            if (!otpSent) {
                              // Reclaim or Verify — initiate OTP
                              final full =
                                  '$countryCode${phoneCtrl.text.trim()}';
                              final r = mode == 'reclaim'
                                ? await PhoneService.reclaim(full)
                                : await PhoneService.initiateVerify(full);
                              setModal(() => loading = false);
                              if (r['success'] == true) {
                                setModal(() => otpSent = true);
                              } else {
                                _snack(r['message'] ?? 'Couldn\'t send the OTP. Please try again.');
                              }
                            } else {
                              // Confirm OTP
                              final fullPhone = '$countryCode${phoneCtrl.text.trim()}';
                              final r = mode == 'reclaim'
                                ? await PhoneService.reclaimVerify(fullPhone, otpCtrl.text.trim())
                                : await PhoneService.confirmVerify(fullPhone, otpCtrl.text.trim());
                              
                              if (!ctx.mounted) return;
                              setModal(() => loading = false);
                              if (r['success'] == true) {
                                Navigator.pop(ctx);
                                _snack(mode == 'reclaim' ? 'Number reclaimed!' : 'Number verified!', isError: false);
                                _load();
                              } else {
                                _snack(r['message'] ?? 'Invalid OTP.');
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd)),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            otpSent ? 'Confirm OTP' : 'Send OTP',
                            style: AppTheme.heading4
                                .copyWith(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        title: Row(children: [
          const Icon(Icons.phone_rounded, size: 18, color: AppTheme.textSecond),
          const SizedBox(width: 8),
          Text('Phone Numbers', style: AppTheme.heading4),
        ]),
        automaticallyImplyLeading: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // ── Action Buttons ────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ActionBtn(
                        label: 'Add & Verify',
                        color: AppTheme.primary,
                        onTap: _showVerifyAdd,
                      ),
                      _ActionBtn(
                        label: 'Reclaim',
                        color: AppTheme.danger,
                        outlined: true,
                        onTap: _showReclaim,
                      ),
                    ],
                  ).animate().fadeIn(delay: 50.ms),
                  const SizedBox(height: 14),

                  // ── Phone List ────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.border, width: 0.5),
                      boxShadow: AppTheme.subtleShadow,
                    ),
                    child: _phones.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Column(children: [
                                const Icon(Icons.phone_disabled_rounded,
                                    color: AppTheme.textHint, size: 48),
                                const SizedBox(height: 12),
                                Text('No phone numbers added',
                                    style: AppTheme.body.copyWith(
                                        color: AppTheme.textMuted)),
                              ]),
                            ),
                          )
                        : Column(
                            children: List.generate(_phones.length, (i) {
                              final ph = _phones[i];
                              return Column(children: [
                                if (i > 0)
                                  const Divider(
                                      height: 1,
                                      thickness: 0.5,
                                      color: AppTheme.border),
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  leading: Container(
                                    width: 38, height: 38,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.phone_rounded,
                                        color: AppTheme.primary, size: 18),
                                  ),
                                  title: Text(ph.phone,
                                    style: AppTheme.body.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    )),
                                  subtitle: ph.isPrimary
                                      ? Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text('Primary',
                                            style: AppTheme.label.copyWith(
                                              color: Colors.white,
                                              fontSize: 10,
                                            )),
                                        ).animate().fadeIn()
                                      : null,
                                  trailing: IconButton(
                                    icon: Container(
                                      width: 32, height: 32,
                                      decoration: BoxDecoration(
                                        color: AppTheme.danger.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.delete_outline_rounded,
                                          color: AppTheme.danger, size: 16),
                                    ),
                                    onPressed: () => _deletePhone(ph),
                                  ),
                                ).animate()
                                    .fadeIn(delay: Duration(milliseconds: i * 50)),
                              ]);
                            }),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // ── Info Card ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          width: 0.5),
                      boxShadow: AppTheme.subtleShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.info_outline_rounded,
                              color: AppTheme.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('About Adding Numbers',
                              style: AppTheme.heading4.copyWith(fontSize: 14)),
                        ]),
                        const SizedBox(height: 14),
                        const _InfoBullet(
                          bold: 'Add & Verify',
                          text:
                              ' texts a one-time code to confirm you own the number before it\'s saved.',
                          highlight: true,
                        ),
                        const SizedBox(height: 10),
                        const _InfoBullet(
                          bold: 'Reclaim',
                          text:
                              ' reclaim your phone number if it\'s already taken by someone else.',
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ]),
              ),
            ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label,
      required this.color,
      required this.onTap,
      this.outlined = false});

  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Text(label,
          style: AppTheme.heading4.copyWith(
            color: outlined ? color : Colors.white,
            fontSize: 13,
          )),
      ),
    ),
  );
}

class _InfoBullet extends StatelessWidget {
  final String bold;
  final String text;
  final bool highlight;
  const _InfoBullet(
      {required this.bold, required this.text, this.highlight = false});

  @override Widget build(BuildContext context) => RichText(
    text: TextSpan(
      style: AppTheme.body.copyWith(fontSize: 13),
      children: [
        TextSpan(
          text: bold,
          style: AppTheme.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: highlight ? AppTheme.primary : AppTheme.textPrimary,
          ),
        ),
        TextSpan(text: text, style: AppTheme.body.copyWith(fontSize: 13)),
      ],
    ),
  );
}
