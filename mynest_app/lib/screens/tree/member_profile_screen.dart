import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import 'add_member_screen.dart';
import '../studio/memory_studio_screen.dart';

class MemberProfileScreen extends StatefulWidget {
  final FamilyMember member;
  const MemberProfileScreen({super.key, required this.member});
  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late FamilyMember _member;
  List<Memory> _memories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _member = widget.member;
    _loadMemories();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMemories() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final all = await DatabaseService().getMemories(user.$id);
        _memories = all.where((m) => m.taggedPersonId == _member.id).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleDeceased() async {
    final newVal = !_member.isDeceased;
    await DatabaseService().updateFamilyMember(_member.id, {'isDeceased': newVal});
    setState(() => _member = _member.copyWith(isDeceased: newVal));
  }

  Future<void> _deletePerson() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Delete Person'),
      content: Text('Remove ${_member.fullName} from your family tree? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
            child: const Text('Delete')),
      ],
    ));
    if (ok == true) {
      await DatabaseService().deleteFamilyMember(_member.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NestTheme.cream,
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: _member.isDeceased ? const Color(0xFF5D5D5D) : NestTheme.darkBrown,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: _member.isDeceased
                      ? const LinearGradient(colors: [Color(0xFF4A4A4A), Color(0xFF6B6B6B)])
                      : NestTheme.heroGradient,
                ),
                child: SafeArea(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(height: 40),
                    CircleAvatar(radius: 40,
                      backgroundColor: _member.isDeceased ? NestTheme.mist.withOpacity(0.3) : NestTheme.amber.withOpacity(0.3),
                      child: Text(_member.fullName[0].toUpperCase(),
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold,
                              color: _member.isDeceased ? NestTheme.mist : Colors.white)),
                    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),
                    const SizedBox(height: 14),
                    Text(_member.fullName,
                        style: Theme.of(context).textTheme.headlineLarge!.copyWith(color: Colors.white))
                        .animate().fadeIn(delay: 200.ms),
                    if (_member.relation != null)
                      Text(_member.relation!,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: NestTheme.softGold))
                          .animate().fadeIn(delay: 300.ms),
                    if (_member.dateOfBirth != null)
                      Text('Born: ${_member.dateOfBirth}',
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white60))
                          .animate().fadeIn(delay: 400.ms),
                  ]),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(delegate: SliverChildListDelegate([
              // Action Row
              Row(children: [
                _ActionBtn(icon: Icons.add_photo_alternate_rounded, label: 'Add Memory',
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => MemoryStudioScreen(taggedMember: _member)))
                        .then((_) => _loadMemories())),
                const SizedBox(width: 10),
                _ActionBtn(icon: Icons.edit_rounded, label: 'Edit Info',
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AddMemberScreen(existingMember: _member)))
                        .then((_) => _loadMemories())),
                const SizedBox(width: 10),
                _ActionBtn(icon: Icons.delete_outline_rounded, label: 'Delete', color: NestTheme.dustyRose,
                    onTap: _deletePerson),
              ]).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),

              // Toggles
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: NestTheme.cardRadius,
                    boxShadow: NestTheme.softShadow),
                child: Row(children: [
                  Icon(Icons.brightness_low_rounded, color: NestTheme.mist, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Mark as Deceased', style: Theme.of(context).textTheme.titleMedium)),
                  Switch(value: _member.isDeceased, activeThumbColor: NestTheme.deepAmber, onChanged: (_) => _toggleDeceased()),
                ]),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 20),

              // Tabs
              TabBar(controller: _tabCtrl,
                labelColor: NestTheme.deepAmber, unselectedLabelColor: NestTheme.mist,
                indicatorColor: NestTheme.deepAmber,
                tabs: const [Tab(text: 'Stories'), Tab(text: 'Gallery')],
              ),
              const SizedBox(height: 16),

              // Tab Content
              SizedBox(
                height: 400,
                child: TabBarView(controller: _tabCtrl, children: [
                  // Stories
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: NestTheme.deepAmber))
                      : _memories.isEmpty
                          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.article_rounded, size: 48, color: NestTheme.mist),
                              const SizedBox(height: 12),
                              Text('No stories yet', style: Theme.of(context).textTheme.bodyMedium),
                            ]))
                          : ListView.builder(
                              itemCount: _memories.length,
                              itemBuilder: (_, i) {
                                final m = _memories[i];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: Colors.white,
                                      borderRadius: NestTheme.cardRadius, boxShadow: NestTheme.softShadow),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(m.title, style: Theme.of(context).textTheme.titleMedium),
                                    if (m.story != null) ...[
                                      const SizedBox(height: 6),
                                      Text(m.story!, style: Theme.of(context).textTheme.bodyMedium,
                                          maxLines: 3, overflow: TextOverflow.ellipsis),
                                    ],
                                  ]),
                                );
                              },
                            ),
                  // Gallery placeholder
                  Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.photo_library_rounded, size: 48, color: NestTheme.mist),
                    const SizedBox(height: 12),
                    Text('Photo gallery', style: Theme.of(context).textTheme.bodyMedium),
                  ])),
                ]),
              ),
            ])),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _ActionBtn({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? NestTheme.deepAmber;
    return Expanded(child: GestureDetector(onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: NestTheme.cardRadius),
        child: Column(children: [
          Icon(icon, color: c, size: 22),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
        ]),
      ),
    ));
  }
}
