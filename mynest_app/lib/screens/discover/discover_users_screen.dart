import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../config/appwrite_config.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import 'package:appwrite/appwrite.dart';

/// ─────────────────────────────────────────────
/// Discover Users — Find & Add Family Members
///
/// This screen queries all registered user profiles from the
/// Appwrite database and allows the current user to send
/// family join requests (stored as pending FamilyMember entries).
/// ─────────────────────────────────────────────

class DiscoverUsersScreen extends StatefulWidget {
  const DiscoverUsersScreen({super.key});
  @override
  State<DiscoverUsersScreen> createState() => _DiscoverUsersScreenState();
}

class _DiscoverUsersScreenState extends State<DiscoverUsersScreen> {
  List<UserProfile> _allUsers = [];
  List<UserProfile> _filtered = [];
  List<FamilyMember> _existingMembers = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Fetch all user profiles and the current user's existing family members
  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        // Load all users from the users collection via DatabaseService
        final db = Databases(AuthService().client);
        final res = await db.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.usersCollection,
          queries: [Query.limit(100)],
        );
        _allUsers = res.documents
            .map((d) => UserProfile.fromMap(d.data))
            .where((u) => u.userId != user.$id) // Exclude self
            .toList();

        // Load existing family members to check duplicates
        _existingMembers = await DatabaseService().getFamilyMembers(user.$id);
      }
    } catch (e) {
      debugPrint('Discover users error: $e');
    }

    // If no real users found, add demo users so the screen isn't empty
    if (_allUsers.isEmpty) {
      _allUsers = [
        UserProfile(id: 'demo1', userId: 'demo_u1', fullName: 'Sarah Miller', email: 'sarah@example.com'),
        UserProfile(id: 'demo2', userId: 'demo_u2', fullName: 'Julian Miller', email: 'julian@example.com'),
        UserProfile(id: 'demo3', userId: 'demo_u3', fullName: 'Eleanor Vance', email: 'eleanor@example.com'),
        UserProfile(id: 'demo4', userId: 'demo_u4', fullName: 'Lily Miller', email: 'lily@example.com'),
        UserProfile(id: 'demo5', userId: 'demo_u5', fullName: 'James Miller', email: 'james@example.com'),
      ];
    }
    _filtered = List.from(_allUsers);
    if (mounted) setState(() => _isLoading = false);
  }

  void _filterUsers() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.from(_allUsers);
      } else {
        _filtered = _allUsers.where((u) =>
            u.fullName.toLowerCase().contains(q) ||
            (u.email ?? '').toLowerCase().contains(q)).toList();
      }
    });
  }

  /// Check if a user is already in the family tree
  bool _isAlreadyInFamily(UserProfile user) {
    return _existingMembers.any((m) =>
        m.fullName.toLowerCase() == user.fullName.toLowerCase());
  }

  /// Send a family request by creating a pending FamilyMember entry
  Future<void> _sendRequest(UserProfile targetUser) async {
    // Show a dialog to select the relationship
    final relation = await showDialog<String>(
      context: context,
      builder: (ctx) => _RelationDialog(targetName: targetUser.fullName),
    );

    if (relation == null || relation.isEmpty) return;

    final user = AuthService().currentUser;
    if (user == null) return;

    try {
      await DatabaseService().addFamilyMember(FamilyMember(
        id: '',
        userId: user.$id,
        fullName: targetUser.fullName,
        relation: relation,
        photoUrl: targetUser.profilePhotoUrl,
        isApproved: false,
      ));

      // Refresh existing members list
      _existingMembers = await DatabaseService().getFamilyMembers(user.$id);
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${targetUser.fullName} added as pending $relation! 🎉'),
            backgroundColor: NestTheme.sage,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send request.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NestTheme.cream,
      appBar: AppBar(
        title: const Text('Find Family'),
        backgroundColor: NestTheme.cream,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search_rounded, color: NestTheme.deepAmber),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: NestTheme.deepAmber))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_rounded, size: 64, color: NestTheme.mist),
                            const SizedBox(height: 16),
                            Text('No users found',
                                style: Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 8),
                            Text('Try a different search term',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) {
                          final user = _filtered[i];
                          final alreadyAdded = _isAlreadyInFamily(user);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: NestTheme.cardRadius,
                              boxShadow: NestTheme.softShadow,
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: NestTheme.deepAmber.withOpacity(0.15),
                                  backgroundImage: (user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty)
                                      ? NetworkImage(user.profilePhotoUrl!)
                                      : null,
                                  child: (user.profilePhotoUrl == null || user.profilePhotoUrl!.isEmpty)
                                      ? Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: NestTheme.deepAmber))
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                // Name & Email
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user.fullName,
                                          style: Theme.of(context).textTheme.titleMedium!
                                              .copyWith(fontWeight: FontWeight.w600)),
                                      if (user.email != null && user.email!.isNotEmpty)
                                        Text(user.email!,
                                            style: TextStyle(fontSize: 12, color: NestTheme.mist)),
                                    ],
                                  ),
                                ),
                                // Action button
                                if (alreadyAdded)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: NestTheme.sage.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: NestTheme.sage, size: 16),
                                        const SizedBox(width: 4),
                                        Text('Added', style: TextStyle(fontSize: 12, color: NestTheme.sage, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  )
                                else
                                  ElevatedButton.icon(
                                    onPressed: () => _sendRequest(user),
                                    icon: const Icon(Icons.person_add_rounded, size: 16),
                                    label: const Text('Add', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: NestTheme.deepAmber,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                              ],
                            ),
                          ).animate().fadeIn(delay: (i * 80).ms, duration: 400.ms);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Dialog to select the relationship when adding a user
class _RelationDialog extends StatefulWidget {
  final String targetName;
  const _RelationDialog({required this.targetName});
  @override
  State<_RelationDialog> createState() => _RelationDialogState();
}

class _RelationDialogState extends State<_RelationDialog> {
  String? _selected;
  final _customCtrl = TextEditingController();

  final _relations = [
    'Father', 'Mother', 'Brother', 'Sister',
    'Son', 'Daughter', 'Grandfather', 'Grandmother',
    'Uncle', 'Aunt', 'Cousin', 'Spouse', 'Other',
  ];

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('How is ${widget.targetName} related?'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _relations.map((r) => ChoiceChip(
                label: Text(r, style: const TextStyle(fontSize: 12)),
                selected: _selected == r,
                selectedColor: NestTheme.deepAmber.withOpacity(0.2),
                onSelected: (v) => setState(() => _selected = v ? r : null),
              )).toList(),
            ),
            if (_selected == 'Other') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customCtrl,
                decoration: const InputDecoration(hintText: 'Enter relation...'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _selected == null ? null : () {
            final result = _selected == 'Other' ? _customCtrl.text.trim() : _selected;
            Navigator.pop(context, result);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
