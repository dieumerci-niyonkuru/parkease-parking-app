import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/phone_service.dart';
import '../providers/theme_provider.dart';
import 'auth/complete_profile_screen.dart';
import 'auth/set_password_screen.dart';
import 'phone_screen.dart';
import 'profile_edit_screen.dart';
import 'parking_costs_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<PhoneNumber> _phones = [];

  @override void initState() { 
    super.initState(); 
    _refresh(); 
  }

  Future<void> _refresh() async {
    await AuthService.fetchProfile(); // Get fresh data from /users/me
    final phones = await PhoneService.getPhones();
    if (!mounted) return;
    setState(() { _phones = phones; });
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text('Select Profile Photo', style: AppTheme.heading4),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
            title: const Text('Take a Photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          if (ProfileService.profile.profilePic.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
              title: const Text('Remove Current Photo', style: TextStyle(color: AppTheme.danger)),
              onTap: () {
                ProfileService.update(profilePic: '');
                setState(() {});
                Navigator.pop(ctx);
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
      final savedImage = await File(image.path).copy('${directory.path}/$fileName');
      
      await ProfileService.update(profilePic: savedImage.path);
      if (mounted) setState(() {});
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Sign Out', style: AppTheme.heading3),
        content: Text('Are you sure you want to sign out of your account?', style: AppTheme.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('CANCEL', style: AppTheme.label.copyWith(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white, elevation: 0),
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.logout();
      if (mounted) {
        // Use rootNavigator: true to ensure we escape the nested navigator and reach the root /login route
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override Widget build(BuildContext context) {
    final user = AuthService.user;
    final name = user?.names ?? 'Valued Driver';
    final initials = name.isNotEmpty ? name.split(' ').map((e) => e[0]).take(2).join().toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                color: Colors.white,
                child: Column(
                  children: [
                    const Text('MY ACCOUNT', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF212529), letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text('Driver Profile Settings'.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 2)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center, 
                  children: [
                    if (user?.phone == null || user!.phone.isEmpty || user.phone == '+250 7XX XXX XXX' || user.phone == '—')
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
                                SizedBox(width: 12),
                                Text('Incomplete Profile', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.warning)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Link your phone number to enable payments and receipts.', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecond)),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CompleteProfileScreen()));
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning, foregroundColor: Colors.white),
                                child: const Text('SET PHONE NUMBER', style: TextStyle(fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ],
                        ),
                      ),
                  
                  // ── PROFILE HEADER (Simplified) ───────────────────────
                  Center(
                    child: Column(children: [
                      Stack(alignment: Alignment.bottomRight, children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Hero(
                            tag: 'profile-pic',
                            child: CircleAvatar(
                              radius: 58, backgroundColor: AppTheme.primary,
                              backgroundImage: ProfileService.profile.profilePic.isNotEmpty
                                  ? (kIsWeb
                                      ? NetworkImage(ProfileService.profile.profilePic)
                                      : FileImage(File(ProfileService.profile.profilePic)) as ImageProvider)
                                  : null,
                              child: ProfileService.profile.profilePic.isEmpty
                                  ? Text(initials, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white))
                                  : null,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 18),
                      Text(name, style: AppTheme.heading2.copyWith(fontSize: 26)),
                      Text(user?.email ?? 'driver@itec.rw', style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted)),
                      if (user?.phone != null && user!.phone.isNotEmpty && user.phone != '+250 7XX XXX XXX' && user.phone != '—') ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.phone_android_rounded, size: 13, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text(user.phone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                          ]),
                        ),
                      ],
                    ]),
                  ),
                  
                  const SizedBox(height: 24),

                  // ── SECURITY SECTION ──────────────────────────────────
                  const _SectionHeader('SECURITY & ACCOUNT'),
                  const _BiometricToggle(),
                  _ProfileTile(
                    icon: Icons.person_outline_rounded, label: 'Edit Profile Information', 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen())).then((_) => _refresh()),
                  ),
                  _ProfileTile(
                    icon: Icons.phone_android_rounded, label: 'Manage Phone Numbers', 
                    trailing: '${_phones.length} active', 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneScreen())).then((_) => _refresh()),
                  ),
                  _ProfileTile(icon: Icons.lock_outline_rounded, label: 'Set Password',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetPasswordScreen()))),
                  const SizedBox(height: 20),
                  
                  // ── PREFERENCES SECTION ───────────────────────────────
                  const _SectionHeader('PREFERENCES'),
                  _ProfileTile(
                    icon: Icons.notifications_none_rounded, label: 'Notification Settings', 
                    trailing: 'Enabled', 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
                  ),
                  const _AppearanceTile(),
                  _ProfileTile(icon: Icons.monetization_on_outlined, label: 'View Price List', onTap: () => showPriceListSheet(context)),
                  
                  const SizedBox(height: 20),
                  
                  // ── SUPPORT SECTION ───────────────────────────────────
                  const _SectionHeader('SUPPORT'),
                  _ProfileTile(icon: Icons.contact_support_rounded, label: 'Contact Us', onTap: () => _showContactSheet(context)),

                  const SizedBox(height: 28),
                  
                  // ── LOGOUT BUTTON ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity, height: 60,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
                      label: const Text('SIGN OUT OF PORTAL', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.danger, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Center(child: Text('ITEC PARKING · VERSION 1.0.0', style: AppTheme.label.copyWith(fontSize: 8, color: AppTheme.textHint, letterSpacing: 1))),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 12),
    child: Text(title, style: AppTheme.label.copyWith(letterSpacing: 2, color: AppTheme.primary, fontWeight: FontWeight.w900)),
  );
}

class _BiometricToggle extends StatefulWidget {
  const _BiometricToggle();
  @override State<_BiometricToggle> createState() => _BiometricToggleState();
}

class _BiometricToggleState extends State<_BiometricToggle> {
  bool _available = false;

  @override void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final can = await AuthService.canUseBiometrics();
    if (mounted) setState(() => _available = can);
  }

  @override Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard, borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.bgDeep, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.fingerprint_rounded, color: AppTheme.textSecond, size: 22),
        ),
        title: const Text('Fingerprint Login', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        subtitle: const Text('Unlock app with your fingerprint', style: TextStyle(fontSize: 11)),
        value: AuthService.isBiometricEnabled,
        activeThumbColor: AppTheme.primary,
        onChanged: (val) async {
          if (val) {
            final success = await AuthService.authenticateBiometrically();
            if (success) {
              await AuthService.setBiometricEnabled(true);
            }
          } else {
            await AuthService.setBiometricEnabled(false);
          }
          setState(() {});
        },
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  const _ProfileTile({required this.icon, required this.label, this.trailing, required this.onTap});

  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: AppTheme.bgCard, borderRadius: BorderRadius.circular(20),
      boxShadow: AppTheme.cardShadow,
    ),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.bgDeep, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppTheme.textSecond, size: 22),
      ),
      title: Text(label, style: AppTheme.body.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (trailing != null) Text(trailing!, style: AppTheme.bodySmall.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
      ]),
    ),
  );
}

// ── APPEARANCE ────────────────────────────────────────────────────
class _AppearanceTile extends StatelessWidget {
  const _AppearanceTile();

  @override Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return _ProfileTile(
      icon: Icons.dark_mode_outlined,
      label: 'Appearance',
      trailing: themeProvider.label,
      onTap: () => _showPicker(context, themeProvider),
    );
  }

  void _showPicker(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Appearance', style: AppTheme.heading4),
              const SizedBox(height: 12),
              _ModeOption(
                icon: Icons.light_mode_outlined, label: 'Light',
                selected: themeProvider.mode == ThemeMode.light,
                onTap: () { themeProvider.setMode(ThemeMode.light); Navigator.pop(ctx); },
              ),
              _ModeOption(
                icon: Icons.dark_mode_outlined, label: 'Dark',
                selected: themeProvider.mode == ThemeMode.dark,
                onTap: () { themeProvider.setMode(ThemeMode.dark); Navigator.pop(ctx); },
              ),
              _ModeOption(
                icon: Icons.brightness_auto_outlined, label: 'System',
                selected: themeProvider.mode == ThemeMode.system,
                onTap: () { themeProvider.setMode(ThemeMode.system); Navigator.pop(ctx); },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeOption({required this.icon, required this.label, required this.selected, required this.onTap});

  @override Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    leading: Icon(icon, color: selected ? AppTheme.primary : AppTheme.textSecond),
    title: Text(label, style: AppTheme.body.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
    trailing: selected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary) : null,
  );
}

// ── NOTIFICATION SETTINGS ───────────────────────────────────────────

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _push = true;
  bool _sms = true;
  bool _email = false;
  bool _reminder = true;

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep, elevation: 0,
        title: Text('NOTIFICATIONS', style: AppTheme.heading4.copyWith(letterSpacing: 1.5, fontSize: 13, color: AppTheme.primary)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _SectionHeader('CHANNELS'),
          _SwitchCard(title: 'Push Notifications', sub: 'Instant updates on your device', val: _push, onChange: (v) => setState(() => _push = v)),
          _SwitchCard(title: 'SMS Alerts', sub: 'Direct text messages for critical alerts', val: _sms, onChange: (v) => setState(() => _sms = v)),
          _SwitchCard(title: 'Email Reports', sub: 'Weekly summaries and digital receipts', val: _email, onChange: (v) => setState(() => _email = v)),
          
          const SizedBox(height: 20),
          const _SectionHeader('AUTOMATED ALERTS'),
          _SwitchCard(title: 'Parking Reminders', sub: 'Notify me 15 mins before duration ends', val: _reminder, onChange: (v) => setState(() => _reminder = v)),
          
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity, height: 64,
            child: ElevatedButton(
              onPressed: () {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences saved.'), behavior: SnackBarBehavior.floating));
                 Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
              ),
              child: const Text('SAVE PREFERENCES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── CONTACT US SHEET ────────────────────────────────────────────────

void _showContactSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          Text('GETTING ASSISTANCE', style: AppTheme.label.copyWith(color: AppTheme.primary, letterSpacing: 2, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          _ContactRow(
            icon: Icons.phone_in_talk_rounded,
            label: 'Quick Call Us',
            value: '+250 788 620 612',
            onTap: () => launchUrl(Uri.parse('tel:+250788620612')),
          ),
          const SizedBox(height: 16),
          _ContactRow(
            icon: Icons.alternate_email_rounded,
            label: 'Mail Us On',
            value: 'info@itec.rw',
            onTap: () => launchUrl(Uri.parse('mailto:info@itec.rw')),
          ),
          const SizedBox(height: 16),
          const _ContactRow(
            icon: Icons.location_on_rounded,
            label: 'Visit Location',
            value: 'KN 1 Rd 4, MUHIMA-Near Post Office\nP.O. Box 4179 KIGALI RWANDA',
          ),
        ],
      ),
    ),
  );
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback? onTap;
  const _ContactRow({required this.icon, required this.label, required this.value, this.onTap});

  @override Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
        ],
      ),
    ),
  );
}

class _SwitchCard extends StatelessWidget {
  final String title, sub;
  final bool val;
  final ValueChanged<bool> onChange;
  const _SwitchCard({required this.title, required this.sub, required this.val, required this.onChange});

  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: AppTheme.bgCard, borderRadius: BorderRadius.circular(20),
      boxShadow: AppTheme.cardShadow,
    ),
    child: SwitchListTile(
      value: val, onChanged: onChange,
      activeThumbColor: AppTheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(title, style: AppTheme.body.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      subtitle: Text(sub, style: AppTheme.bodySmall),
    ),
  );
}
