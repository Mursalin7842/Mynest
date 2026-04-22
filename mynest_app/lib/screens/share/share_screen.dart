import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../config/appwrite_config.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

/// ─────────────────────────────────────────────
/// Share Screen — Messenger-style Family Sharing
/// ─────────────────────────────────────────────

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  List<FamilyMember> _members = [];
  final Set<String> _selected = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final all = await DatabaseService().getFamilyMembers(user.$id);
        _members = all.where((m) => m.isApproved).toList();
      } else {
        _members = [
          FamilyMember(id: 'd2', userId: 'demo', fullName: 'Sarah Miller', relation: 'Mother', isApproved: true, gender: 'Female'),
          FamilyMember(id: 'd3', userId: 'demo', fullName: 'Julian Miller', relation: 'Father', isApproved: true, gender: 'Male'),
          FamilyMember(id: 'd6', userId: 'demo', fullName: 'Lily Miller', relation: 'Sister', isApproved: true, gender: 'Female'),
          FamilyMember(id: 'd7', userId: 'demo', fullName: 'Leo Miller', relation: 'Brother', isApproved: true, gender: 'Male'),
        ];
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _shareWithSelected() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one family member')),
      );
      return;
    }

    final selectedNames = _members
        .where((m) => _selected.contains(m.id))
        .map((m) => m.fullName.split(' ').first)
        .join(', ');

    final link = '${AppwriteConfig.webDomain}/vault/shared-${DateTime.now().millisecondsSinceEpoch}';
    Clipboard.setData(ClipboardData(text: link));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: NestTheme.sage, size: 28),
            SizedBox(width: 10),
            Text('Shared!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your family tree and memories have been shared with:'),
            const SizedBox(height: 8),
            Text(selectedNames,
                style: const TextStyle(fontWeight: FontWeight.w700, color: NestTheme.deepAmber)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: NestTheme.parchment,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(link, style: const TextStyle(fontSize: 10)),
            ),
            const SizedBox(height: 8),
            const Text('📋 Link copied!', style: TextStyle(fontSize: 11, color: NestTheme.sage)),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NestTheme.cream,
      appBar: AppBar(
        title: const Text('Share With Family'),
        backgroundColor: NestTheme.cream,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: NestTheme.deepAmber))
          : Column(
              children: [
                // Privacy selector
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: NestTheme.cardRadius,
                      boxShadow: NestTheme.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Share Settings', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _PrivacyChip(label: '🌐 Public', isSelected: true, onTap: () {}),
                            const SizedBox(width: 8),
                            _PrivacyChip(label: '🔒 Private', isSelected: false, onTap: () {}),
                            const SizedBox(width: 8),
                            _PrivacyChip(label: '👥 Custom', isSelected: false, onTap: () {}),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text('Select Family Members',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            if (_selected.length == _members.length) {
                              _selected.clear();
                            } else {
                              _selected.addAll(_members.map((m) => m.id));
                            }
                          });
                        },
                        child: Text(
                          _selected.length == _members.length ? 'Deselect All' : 'Select All',
                          style: const TextStyle(color: NestTheme.deepAmber),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Contact list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _members.length,
                    itemBuilder: (ctx, i) {
                      final m = _members[i];
                      final isSelected = _selected.contains(m.id);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selected.remove(m.id);
                            } else {
                              _selected.add(m.id);
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? NestTheme.deepAmber.withAlpha(13)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(color: NestTheme.deepAmber.withAlpha(77))
                                : null,
                            boxShadow: NestTheme.softShadow,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isSelected
                                    ? NestTheme.deepAmber
                                    : NestTheme.amber.withAlpha(51),
                                child: Text(
                                  m.fullName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : NestTheme.deepAmber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.fullName,
                                        style: Theme.of(context).textTheme.titleMedium),
                                    Text(m.relation ?? 'Family',
                                        style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? NestTheme.deepAmber
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? NestTheme.deepAmber
                                        : NestTheme.mist,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: (60 * i).ms, duration: 400.ms);
                    },
                  ),
                ),

                // Share button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _shareWithSelected,
                      icon: const Icon(Icons.send_rounded),
                      label: Text('Share with ${_selected.length} member${_selected.length != 1 ? 's' : ''}'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PrivacyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _PrivacyChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? NestTheme.deepAmber.withAlpha(26) : NestTheme.parchment,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: NestTheme.deepAmber.withAlpha(128)) : null,
        ),
        child: Text(label, style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? NestTheme.deepAmber : NestTheme.charcoal)),
      ),
    );
  }
}
