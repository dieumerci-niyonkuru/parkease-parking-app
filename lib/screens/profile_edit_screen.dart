import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../theme/app_theme.dart';
import '../services/profile_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _imagePath;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = ProfileService.profile;
    _nameCtrl.text = p.name;
    _emailCtrl.text = p.email;
    _imagePath = p.profilePic;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
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
          if (_imagePath != null && _imagePath!.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
              title: const Text('Remove Current Photo', style: TextStyle(color: AppTheme.danger)),
              onTap: () {
                setState(() => _imagePath = '');
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
      if (kIsWeb) {
        setState(() {
          _imagePath = image.path;
        });
        return;
      }
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
      final savedImage = await File(image.path).copy('${directory.path}/$fileName');
      
      setState(() {
        _imagePath = savedImage.path;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() => _loading = true);
    await ProfileService.update(name: name, email: email, profilePic: _imagePath);
    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppTheme.success),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        elevation: 0,
        title: Text('EDIT PROFILE', style: AppTheme.heading4.copyWith(letterSpacing: 1.5, color: AppTheme.primary)),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: AppTheme.primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    backgroundImage: _imagePath != null && _imagePath!.isNotEmpty
                        ? (kIsWeb ? NetworkImage(_imagePath!) : FileImage(File(_imagePath!)) as ImageProvider)
                        : null,
                    child: _imagePath == null || _imagePath!.isEmpty
                        ? const Icon(Icons.person_outline_rounded, size: 60, color: AppTheme.primary)
                        : null,
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Full Name', style: AppTheme.label),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
              decoration: const InputDecoration(hintText: 'John Doe'),
            ),
            const SizedBox(height: 16),
            Text('Email Address', style: AppTheme.label),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
              decoration: const InputDecoration(hintText: 'john@example.com'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
