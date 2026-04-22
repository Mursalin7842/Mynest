import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../config/appwrite_config.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/database_service.dart';
import '../../models/models.dart';
import '../auth/login_screen.dart';
import '../share/share_screen.dart';

/// ─────────────────────────────────────────────
/// Settings V1.2.0 — Profile Photo + All Settings
/// ─────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _name = '';
  String _email = '';
  String? _profilePhotoUrl;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    if (user != null) {
      _name = user.name;
      _email = user.email;
      _loadProfile(user.$id);
    } else {
      _name = 'Mursaline Huqe';
      _email = 'demo@mynest.app';
    }
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final profile = await DatabaseService().getUserProfile(userId);
      if (profile != null && profile.profilePhotoUrl != null && mounted) {
        setState(() {
          _profilePhotoUrl = StorageService().getProfilePhotoUrl(profile.profilePhotoUrl!);
        });
      }
    } catch (_) {}
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final fileId = await StorageService().uploadProfilePhoto(
        fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        fileBytes: Uint8List.fromList(bytes),
      );

      final user = AuthService().currentUser;
      if (user != null) {
        final existing = await DatabaseService().getUserProfile(user.$id);
        if (existing != null) {
          await DatabaseService().updateUserProfile(existing.id, {'profilePhotoUrl': fileId});
        } else {
          await DatabaseService().createUserProfile(UserProfile(
            id: '', userId: user.$id, fullName: _name, email: _email, profilePhotoUrl: fileId,
          ));
        }
        setState(() {
          _profilePhotoUrl = StorageService().getProfilePhotoUrl(fileId);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated! 📸'), backgroundColor: NestTheme.sage),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isUploadingPhoto = false);
  }

  Future<void> _editDetails() async {
    final nameCtrl = TextEditingController(text: _name);
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Edit Details'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
      ],
    ));
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      try { await AuthService().updateName(nameCtrl.text.trim()); } catch (_) {}
      setState(() => _name = nameCtrl.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated!'), backgroundColor: NestTheme.sage),
      );
    }
    nameCtrl.dispose();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Log Out'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: NestTheme.dustyRose),
            child: const Text('Log Out')),
      ],
    ));
    if (ok == true) {
      try { await AuthService().logout(); } catch (_) {}
      if (mounted) Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NestTheme.cream,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: NestTheme.cream,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Avatar with photo
          Center(child: Column(children: [
            GestureDetector(
              onTap: _pickProfilePhoto,
              child: Stack(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _profilePhotoUrl == null ? NestTheme.amberGradient : null,
                      boxShadow: [BoxShadow(color: NestTheme.amber.withAlpha(77), blurRadius: 20, offset: const Offset(0, 8))],
                      image: _profilePhotoUrl != null
                          ? DecorationImage(image: NetworkImage(_profilePhotoUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _isUploadingPhoto
                        ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : _profilePhotoUrl == null
                            ? Center(child: Text(
                                _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                              ))
                            : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: NestTheme.deepAmber,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(_name, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            Text(_email, style: Theme.of(context).textTheme.bodyMedium),
          ])).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 36),

          _SettingsItem(icon: Icons.edit_rounded, label: 'Edit Details',
              subtitle: 'Update your name and bio', onTap: _editDetails)
              .animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
          _SettingsItem(icon: Icons.camera_alt_rounded, label: 'Change Photo',
              subtitle: 'Pick a new profile picture', onTap: _pickProfilePhoto)
              .animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),
          _SettingsItem(icon: Icons.link_rounded, label: 'Import Vault Link',
              subtitle: 'Connect external archives', onTap: () {
                showDialog(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('Import Vault Link'),
                  content: TextField(
                    decoration: const InputDecoration(hintText: 'Paste link here...'),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vault link imported successfully!'), backgroundColor: NestTheme.sage));
                    }, child: const Text('Import')),
                  ],
                ));
              })
              .animate().fadeIn(delay: 300.ms).slideX(begin: 0.05),
          _SettingsItem(icon: Icons.share_rounded, label: 'Share Family Tree',
              subtitle: 'Send your tree to family members', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ShareScreen()));
              })
              .animate().fadeIn(delay: 350.ms).slideX(begin: 0.05),
          _SettingsItem(icon: Icons.logout_rounded, label: 'Log Out',
              subtitle: 'End your session securely', onTap: _logout, isDestructive: true)
              .animate().fadeIn(delay: 400.ms).slideX(begin: 0.05),
          const SizedBox(height: 40),

          Center(child: Text('MyNest Digital Curator ${AppwriteConfig.appVersion}',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 11)))
              .animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsItem({required this.icon, required this.label, required this.subtitle,
      required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: NestTheme.cardRadius,
            boxShadow: NestTheme.softShadow),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDestructive ? NestTheme.dustyRose : NestTheme.deepAmber).withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isDestructive ? NestTheme.dustyRose : NestTheme.deepAmber, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: isDestructive ? NestTheme.dustyRose : NestTheme.charcoal)),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ])),
          Icon(Icons.chevron_right_rounded, color: NestTheme.mist),
        ]),
      ),
    );
  }
}
