import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/phone_service.dart';
import 'phone_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<PhoneNumber> _phones = [];
  bool _loading = true;

  @override void initState() { 
    super.initState(); 
    _refresh(); 
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await AuthService.fetchProfile(); // Get fresh data from /users/me
    final phones = await PhoneService.getPhones();
    if (!mounted) return;
    setState(() { _phones = phones; _loading = false; });
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
          const SizedBox(height: 24),
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
        content: Text('Are you sure you want to exit the ITEC Portal?', style: AppTheme.body),
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
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  
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
                                  ? FileImage(File(ProfileService.profile.profilePic))
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
                    ]),
                  ),
                  
                  const SizedBox(height: 40),

                  // ── SECURITY SECTION ──────────────────────────────────
                  _SectionHeader('SECURITY & ACCOUNT'),
                  _ProfileTile(
                    icon: Icons.person_outline_rounded, label: 'Edit Profile Information', 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen())).then((_) => _refresh()),
                  ),
                  _ProfileTile(
                    icon: Icons.phone_android_rounded, label: 'Manage Phone Numbers', 
                    trailing: '${_phones.length} active', 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneScreen())).then((_) => _refresh()),
                  ),
                  _ProfileTile(icon: Icons.security_rounded, label: 'Identity Verification', trailing: 'Verified', onTap: () {}),
                  _ProfileTile(icon: Icons.lock_outline_rounded, label: 'Update Password', onTap: () {}),
                  
                  const SizedBox(height: 32),
                  
                  // ── PREFERENCES SECTION ───────────────────────────────
                  _SectionHeader('PREFERENCES'),
                  _ProfileTile(
                    icon: Icons.notifications_none_rounded, label: 'Notification Settings', 
                    trailing: 'Enabled', 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
                  ),
                  _ProfileTile(icon: Icons.language_rounded, label: 'Language', trailing: 'English (RW)', onTap: () {}),
                  _ProfileTile(icon: Icons.dark_mode_outlined, label: 'Appearance', trailing: 'System', onTap: () {}),
                  
                  const SizedBox(height: 32),
                  
                  // ── SUPPORT SECTION ───────────────────────────────────
                  _SectionHeader('SUPPORT'),
                  _ProfileTile(icon: Icons.help_outline_rounded, label: 'Help & FAQ Center', onTap: () {}),
                  _ProfileTile(icon: Icons.info_outline_rounded, label: 'About ITEC Rwanda', onTap: () {}),
                  _ProfileTile(icon: Icons.policy_outlined, label: 'Terms of Service', onTap: () {}),
                  
                  const SizedBox(height: 48),
                  
                  // ── LOGOUT BUTTON ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity, height: 60,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
                      label: Text('SIGN OUT OF PORTAL', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.danger, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Center(child: Text('BUILD VERSION 1.0.5 - STABLE PRODUCTION', style: AppTheme.label.copyWith(fontSize: 8, color: AppTheme.textHint, letterSpacing: 1))),
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
      border: Border.all(color: AppTheme.border.withOpacity(0.5), width: 1),
      boxShadow: AppTheme.subtleShadow,
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
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SectionHeader('CHANNELS'),
          _SwitchCard(title: 'Push Notifications', sub: 'Instant updates on your device', val: _push, onChange: (v) => setState(() => _push = v)),
          _SwitchCard(title: 'SMS Alerts', sub: 'Direct text messages for critical alerts', val: _sms, onChange: (v) => setState(() => _sms = v)),
          _SwitchCard(title: 'Email Reports', sub: 'Weekly summaries and digital receipts', val: _email, onChange: (v) => setState(() => _email = v)),
          
          const SizedBox(height: 32),
          _SectionHeader('AUTOMATED ALERTS'),
          _SwitchCard(title: 'Parking Reminders', sub: 'Notify me 15 mins before duration ends', val: _reminder, onChange: (v) => setState(() => _reminder = v)),
          
          const SizedBox(height: 48),
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

class _SwitchCard extends StatelessWidget {
  final String title, sub;
  final bool val;
  final ValueChanged<bool> onChange;
  const _SwitchCard({required this.title, required this.sub, required this.val, required this.onChange});

  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: AppTheme.bgCard, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      boxShadow: AppTheme.subtleShadow,
    ),
    child: SwitchListTile(
      value: val, onChanged: onChange,
      activeColor: AppTheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(title, style: AppTheme.body.copyWith(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      subtitle: Text(sub, style: AppTheme.bodySmall),
    ),
  );
}
