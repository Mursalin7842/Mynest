import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../config/appwrite_config.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../studio/memory_studio_screen.dart';
import '../share/share_screen.dart';
import '../share/photo_context_setup_screen.dart';
import '../book/family_book_screen.dart';
import '../vault/vault_screen.dart';
import '../tree/family_tree_screen.dart';
import '../vault/memory_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ─────────────────────────────────────────────
/// Dashboard V1.2.0 — 3 Link Types + Real Data
/// ─────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabChanged;
  const DashboardScreen({super.key, this.onTabChanged});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Memory> _recentMemories = [];
  List<FamilyMember> _members = [];
  List<FamilyMember> _pendingMembers = [];
  List<Memory> _pendingMemoriesData = [];
  bool _isLoading = true;
  String _userName = 'Friend';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        _userName = user.name.isNotEmpty ? user.name.split(' ').first : 'Friend';
        _members = await DatabaseService().getFamilyMembers(user.$id);
        _recentMemories = await DatabaseService().getMemories(user.$id);
        _pendingMembers = await DatabaseService().getPendingMembers(user.$id);
        _pendingMemoriesData =
            await DatabaseService().getPendingMemories(user.$id);
      } else {
        _loadDemoData();
      }
    } catch (_) {
      _loadDemoData();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _loadDemoData() {
    _userName = 'Mursaline';
    _members = [
      FamilyMember(id: 'd1', userId: 'demo', fullName: 'Mursaline', relation: 'Self', isApproved: true),
      FamilyMember(id: 'd2', userId: 'demo', fullName: 'Sarah Miller', relation: 'Mother', isApproved: true),
      FamilyMember(id: 'd3', userId: 'demo', fullName: 'Julian Miller', relation: 'Father', isApproved: true),
      FamilyMember(id: 'd4', userId: 'demo', fullName: 'Eleanor Vance', relation: 'Grandmother', isDeceased: true, isApproved: true),
      FamilyMember(id: 'd5', userId: 'demo', fullName: 'Arthur Miller', relation: 'Grandfather', isDeceased: true, isApproved: true),
    ];
    _recentMemories = [
      Memory(id: 'm1', userId: 'demo', title: "The Summer of '74", story: 'It was the summer that changed everything...', contributorName: 'Evelyn', eventDate: 'June 1974', isApproved: true, status: 'chaptered'),
      Memory(id: 'm2', userId: 'demo', title: "Grandpa's Study", contributorName: 'You', isApproved: true, status: 'raw'),
    ];
    _pendingMembers = [
      FamilyMember(id: 'p1', userId: 'demo', fullName: 'Aunty Shirin', relation: "Aunt", isApproved: false),
    ];
    _pendingMemoriesData = [
      Memory(id: 'pm1', userId: 'demo', title: 'Memory from Shirin', contributorName: 'Shirin', isApproved: false, status: 'raw'),
    ];
  }

  /// Generate one of 3 link types
  Future<void> _generateLink(String type) async {
    String title;
    String description;
    IconData icon;

    switch (type) {
      case 'empty':
        title = 'Story Collection Link';
        description = 'Anyone with this link can upload a memory — no context given.';
        icon = Icons.edit_note_rounded;
        break;
      case 'photo_context':
        title = 'Photo Story Link';
        description = 'Upload a photo first, then share the link. Family members add the story behind the photo.';
        icon = Icons.photo_camera_rounded;
        break;
      case 'vault_share':
        title = 'Vault Share Link';
        description = 'Share your approved memory collection as a read-only gallery.';
        icon = Icons.share_rounded;
        break;
      default:
        return;
    }

    // Create link in database (or generate locally in demo)
    String linkUrl;
    final user = AuthService().currentUser;
    if (user != null) {
      try {
        final link = await DatabaseService().createShareLink(ShareLink(
          id: '',
          userId: user.$id,
          type: type,
        ));
        linkUrl = link.webUrl;
      } catch (_) {
        linkUrl = '${AppwriteConfig.webDomain}/contribute/demo-${DateTime.now().millisecondsSinceEpoch}';
      }
    } else {
      linkUrl = '${AppwriteConfig.webDomain}/contribute/demo-${DateTime.now().millisecondsSinceEpoch}';
    }

    Clipboard.setData(ClipboardData(text: linkUrl));

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: NestTheme.deepAmber),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: TextStyle(color: NestTheme.charcoal, fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NestTheme.parchment,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                linkUrl,
                style: const TextStyle(fontSize: 11, color: NestTheme.charcoal),
              ),
            ),
            const SizedBox(height: 8),
            const Text('📋 Link copied to clipboard!',
                style: TextStyle(fontSize: 12, color: NestTheme.sage, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final approvedMembers = _members.where((m) => m.isApproved).length;
    final approvedMemories = _recentMemories.where((m) => m.isApproved).length;

    return Scaffold(
      backgroundColor: NestTheme.cream,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: NestTheme.deepAmber))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: NestTheme.deepAmber,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: true,
                    backgroundColor: NestTheme.cream,
                    surfaceTintColor: Colors.transparent,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                      title: Text(
                        'Welcome, $_userName',
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontSize: 18),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Pending Banner ──
                        if (_pendingMembers.isNotEmpty || _pendingMemoriesData.isNotEmpty)
                          _buildPendingBanner().animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),

                        // ── Hero Card ──
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyBookScreen())),
                          child: _buildHeroCard().animate().fadeIn(delay: 100.ms, duration: 600.ms).slideY(begin: 0.1),
                        ),
                        const SizedBox(height: 20),

                        // ── Quick Stats ──
                        _buildQuickStats(approvedMembers, approvedMemories).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                        const SizedBox(height: 24),

                        // ── 3 Link Types ──
                        Text('Share & Gather', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 14),
                        _buildLinkActions().animate().fadeIn(delay: 300.ms, duration: 600.ms),
                        const SizedBox(height: 24),

                        // ── Quick Actions ──
                        Row(
                          children: [
                            Expanded(
                              child: _SmallAction(
                                icon: Icons.people_rounded,
                                label: 'Share Tree',
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const ShareScreen())),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SmallAction(
                                icon: Icons.download_rounded,
                                label: 'Import Vault',
                                onTap: () => _showImportDialog(),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: 28),

                        // ── Recent Activity ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent Activity', style: Theme.of(context).textTheme.headlineMedium),
                            TextButton(
                              onPressed: () {},
                              child: const Text('View All', style: TextStyle(color: NestTheme.deepAmber)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._buildRecentActivity(),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dashboard_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MemoryStudioScreen()),
        ).then((_) => _loadData()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Memory'),
        backgroundColor: NestTheme.deepAmber,
      ),
    );
  }

  Widget _buildPendingBanner() {
    final total = _pendingMembers.length + _pendingMemoriesData.length;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultScreen(initialTabIndex: 2))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          NestTheme.amber.withAlpha(38),
          NestTheme.dustyRose.withAlpha(26),
        ]),
        borderRadius: NestTheme.cardRadius,
        border: Border.all(color: NestTheme.amber.withAlpha(77)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: NestTheme.amber.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pending_actions_rounded, color: NestTheme.deepAmber, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔔 $total Pending Approval${total > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700, color: NestTheme.darkBrown),
                ),
                Text('Review new members and memories', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: NestTheme.deepAmber),
        ],
      ),
    ));
  }
  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: NestTheme.heroGradient,
        borderRadius: NestTheme.cardRadius,
        boxShadow: [
          BoxShadow(color: NestTheme.darkBrown.withAlpha(77), blurRadius: 30, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_rounded, color: NestTheme.softGold, size: 28),
              const SizedBox(width: 12),
              Text('Family Story Book',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Text('${_recentMemories.length} memories preserved',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: NestTheme.softGold)),
          const SizedBox(height: 4),
          Row(
            children: List.generate(
              (_members.length > 4 ? 4 : _members.length),
              (i) => Container(
                margin: const EdgeInsets.only(right: 4),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NestTheme.amber.withAlpha(77),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    _members[i].fullName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(int members, int memories) {
    return Row(
      children: [
        _StatChip(
          label: 'Members', value: '$members', icon: Icons.people_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyTreeScreen())),
        ),
        const SizedBox(width: 12),
        _StatChip(
          label: 'Memories', value: '$memories', icon: Icons.photo_library_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultScreen(initialTabIndex: 1))),
        ),
        const SizedBox(width: 12),
        _StatChip(
          label: 'Pending', value: '${_pendingMembers.length + _pendingMemoriesData.length}', icon: Icons.pending_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultScreen(initialTabIndex: 2))),
        ),
      ],
    );
  }

  /// 3 distinct link generation buttons
  Widget _buildLinkActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _LinkButton(
              icon: Icons.edit_note_rounded,
              label: 'Story\nLink',
              subtitle: 'Empty form',
              color: NestTheme.sage,
              onTap: () => _generateLink('empty'),
            )),
            const SizedBox(width: 10),
            Expanded(child: _LinkButton(
              icon: Icons.photo_camera_rounded,
              label: 'Photo\nContext',
              subtitle: 'Add photo story',
              color: NestTheme.deepAmber,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotoContextSetupScreen())),
            )),
            const SizedBox(width: 10),
            Expanded(child: _LinkButton(
              icon: Icons.share_rounded,
              label: 'Vault\nShare',
              subtitle: 'Read-only',
              color: NestTheme.dustyRose,
              onTap: () => _generateLink('vault_share'),
            )),
          ],
        ),
      ],
    );
  }

  void _showImportDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.download_rounded, color: NestTheme.deepAmber),
            SizedBox(width: 10),
            Text('Import Vault Link'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste a vault share link to import another family\'s public memories.'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'https://mynest.mursalin.engineer/vault/...',
                prefixIcon: Icon(Icons.link_rounded, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final link = ctrl.text.trim();
              if (link.contains('shared-')) {
                final id = link.split('shared-').last;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('imported_vault_id', id);
                
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vault imported successfully! 📚'), backgroundColor: NestTheme.sage),
                  );
                  _loadData(); // Reload to show imported memories
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid Vault Link.'), backgroundColor: NestTheme.dustyRose),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentActivity() {
    if (_recentMemories.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: NestTheme.cardRadius,
            boxShadow: NestTheme.softShadow,
          ),
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 48, color: NestTheme.mist),
              const SizedBox(height: 12),
              Text('Your vault is empty', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('Share a link to start collecting memories.',
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ];
    }

    return _recentMemories.take(5).map((memory) {
      return GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemoryDetailScreen(memory: memory))).then((_) => _loadData()),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: NestTheme.cardRadius,
          boxShadow: NestTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: NestTheme.cardGradient,
              ),
              child: Icon(
                memory.photoUrl != null ? Icons.photo_rounded : Icons.article_rounded,
                color: NestTheme.deepAmber,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(memory.title, style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(memory.contributorName ?? 'You', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            // Privacy badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: memory.visibility == 'private'
                    ? NestTheme.dustyRose.withAlpha(38)
                    : NestTheme.sage.withAlpha(38),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                memory.visibility == 'private' ? '🔒' : '🌐',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            if (!memory.isApproved)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: NestTheme.amber.withAlpha(38),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('PENDING',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: NestTheme.deepAmber)),
              ),
          ],
        ),
        ),
      ).animate().fadeIn(delay: (100 * _recentMemories.indexOf(memory)).ms);
    }).toList();
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  const _StatChip({required this.label, required this.value, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: NestTheme.cardRadius,
            boxShadow: NestTheme.softShadow,
          ),
          child: Column(
            children: [
              Icon(icon, color: NestTheme.deepAmber, size: 22),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontSize: 22, color: NestTheme.darkBrown)),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _LinkButton({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: NestTheme.cardRadius,
          boxShadow: NestTheme.softShadow,
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: NestTheme.charcoal, height: 1.3)),
            Text(subtitle, style: TextStyle(fontSize: 9, color: NestTheme.mist)),
          ],
        ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SmallAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: NestTheme.cardRadius,
          boxShadow: NestTheme.softShadow,
        ),
        child: Row(
          children: [
            Icon(icon, color: NestTheme.deepAmber, size: 20),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
