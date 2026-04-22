import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import 'memory_detail_screen.dart';
import '../studio/memory_studio_screen.dart';

/// ─────────────────────────────────────────────
/// Vault Screen — Memory Timeline
/// ─────────────────────────────────────────────

class VaultScreen extends StatefulWidget {
  final int initialTabIndex;
  const VaultScreen({super.key, this.initialTabIndex = 0});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Memory> _allMemories = [];
  List<Memory> _pendingMemories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(initialIndex: widget.initialTabIndex, length: 3, vsync: this);
    _loadMemories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMemories() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        _allMemories = await DatabaseService().getMemories(user.$id);
      } else {
        _loadDemoMemories();
      }
    } catch (_) {
      _loadDemoMemories();
    }
    _pendingMemories = _allMemories.where((m) => !m.isApproved).toList();
    if (mounted) setState(() => _isLoading = false);
  }

  void _loadDemoMemories() {
    _allMemories = [
      Memory(id: 'm1', userId: 'demo', title: "The Summer of '74", story: 'It was the summer that changed everything. The old house on the hill still stood proud against the amber sky...', contributorName: 'Evelyn', eventDate: 'June 1974', isApproved: true, status: 'chaptered'),
      Memory(id: 'm2', userId: 'demo', title: "Grandpa's Study", story: 'The old oak desk still smelled of pipe tobacco and leather-bound books...', contributorName: 'You', eventDate: 'Oct 1992', isApproved: true, status: 'raw'),
      Memory(id: 'm3', userId: 'demo', title: "The Grand Wedding", story: 'Uncle James added 4 photos from the ceremony that summer day...', contributorName: 'Uncle James', isApproved: true, status: 'ai-ready'),
      Memory(id: 'm4', userId: 'demo', title: "Audio Story: Grandma's Recipe", story: 'Passed down from her own mother, this recipe survived three moves...', contributorName: 'Martha S.', isApproved: true, status: 'raw'),
      Memory(id: 'm5', userId: 'demo', title: "Echoes of the Lake House", story: 'Every summer we would drive up to the lake and the children would run straight to the water...', contributorName: 'Thomas', eventDate: '4 days ago', isApproved: true, status: 'chaptered'),
      Memory(id: 'pm1', userId: 'demo', title: 'Memory from Shirin', story: 'I remember when your mother was just a little girl running through the garden with bare feet...', contributorName: 'Shirin', contributorRelation: "Mother's Sister", isApproved: false, status: 'raw'),
      Memory(id: 'pm2', userId: 'demo', title: "Sarah's 5th Birthday", story: 'The cake was shaped like a butterfly and everyone laughed when she blew out the candles...', contributorName: 'David', isApproved: false, status: 'raw'),
    ];
  }

  List<Memory> get _filteredMemories {
    var list = _allMemories;
    if (_tabController.index == 1) {
      list = list.where((m) => m.isApproved).toList();
    } else if (_tabController.index == 2) {
      list = list.where((m) => !m.isApproved).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((m) =>
              m.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (m.story?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NestTheme.cream,
      appBar: AppBar(
        title: const Text('The Vault'),
        backgroundColor: NestTheme.cream,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search memories, dates, or stories...',
                    prefixIcon:
                        const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Tabs
              TabBar(
                controller: _tabController,
                onTap: (_) => setState(() {}),
                labelColor: NestTheme.deepAmber,
                unselectedLabelColor: NestTheme.charcoal.withOpacity(0.5),
                indicatorColor: NestTheme.deepAmber,
                tabs: [
                  Tab(text: 'All (${_allMemories.length})'),
                  Tab(
                      text:
                          'Approved (${_allMemories.where((m) => m.isApproved).length})'),
                  Tab(text: 'Pending (${_pendingMemories.length})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: NestTheme.deepAmber))
          : RefreshIndicator(
              onRefresh: _loadMemories,
              child: _filteredMemories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_stories_rounded,
                              size: 64, color: NestTheme.mist),
                          const SizedBox(height: 16),
                          Text(
                            'No memories yet',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start preserving your family\'s history',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _filteredMemories.length,
                      itemBuilder: (ctx, i) {
                        final memory = _filteredMemories[i];
                        return _MemoryCard(
                          memory: memory,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MemoryDetailScreen(memory: memory),
                            ),
                          ).then((_) => _loadMemories()),
                          onApprove: memory.isApproved
                              ? null
                              : () async {
                                  final user = AuthService().currentUser;
                                  if (user != null) {
                                    await DatabaseService()
                                        .approveMemory(memory.id);
                                  }
                                  // Update local state
                                  setState(() {
                                    final idx = _allMemories.indexWhere((m) => m.id == memory.id);
                                    if (idx != -1) {
                                      _allMemories[idx] = _allMemories[idx].copyWith(isApproved: true);
                                    }
                                    _pendingMemories = _allMemories.where((m) => !m.isApproved).toList();
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            const Text('Memory approved! ✨'),
                                        backgroundColor: NestTheme.sage,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                },
                        )
                            .animate()
                            .fadeIn(delay: (80 * i).ms, duration: 500.ms)
                            .slideX(begin: 0.05);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MemoryStudioScreen()),
        ).then((_) => _loadMemories()),
        backgroundColor: NestTheme.deepAmber,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;
  final VoidCallback? onApprove;

  const _MemoryCard(
      {required this.memory, required this.onTap, this.onApprove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: NestTheme.cardRadius,
          boxShadow: NestTheme.softShadow,
          border: !memory.isApproved
              ? Border.all(color: NestTheme.amber.withOpacity(0.4), width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: memory.photoUrl != null
                          ? null
                          : NestTheme.cardGradient,
                      borderRadius: BorderRadius.circular(14),
                      color: memory.photoUrl != null
                          ? NestTheme.parchment
                          : null,
                    ),
                    child: Icon(
                      memory.photoUrl != null
                          ? Icons.photo_rounded
                          : memory.audioUrl != null
                              ? Icons.mic_rounded
                              : Icons.article_rounded,
                      color: NestTheme.deepAmber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (!memory.isApproved)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: NestTheme.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PENDING',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: NestTheme.deepAmber,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                memory.title,
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (memory.story != null && memory.story!.isNotEmpty)
                          Text(
                            memory.story!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (memory.contributorName != null) ...[
                              Icon(Icons.person_outline,
                                  size: 14, color: NestTheme.mist),
                              const SizedBox(width: 4),
                              Text(
                                memory.contributorName!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(fontSize: 11),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (memory.eventDate != null) ...[
                              Icon(Icons.calendar_today_outlined,
                                  size: 14, color: NestTheme.mist),
                              const SizedBox(width: 4),
                              Text(
                                memory.eventDate!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Approve Button
            if (onApprove != null)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: NestTheme.mist.withOpacity(0.3))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check_circle_outline,
                            size: 18, color: NestTheme.sage),
                        label: const Text('Approve',
                            style: TextStyle(color: NestTheme.sage)),
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 30,
                        color: NestTheme.mist.withOpacity(0.3)),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          await DatabaseService().deleteMemory(memory.id);
                        },
                        icon: Icon(Icons.close_rounded,
                            size: 18, color: NestTheme.dustyRose),
                        label: Text('Reject',
                            style: TextStyle(color: NestTheme.dustyRose)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
