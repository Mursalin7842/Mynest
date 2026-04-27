import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────
/// Family Tree Screen V1.2.0
/// 
/// This screen is responsible for visualizing the family hierarchy.
/// It fetches family members from the Appwrite database and organizes 
/// them into generational layers. It includes a background synchronization 
/// mechanism that maps new contributors from memories directly into the tree.
/// ─────────────────────────────────────────────
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/appwrite_config.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import 'add_member_screen.dart';
import 'member_profile_screen.dart';

/// ─────────────────────────────────────────────
/// Family Tree — Visual Graph with Nodes & Lines
/// ─────────────────────────────────────────────

class FamilyTreeScreen extends StatefulWidget {
  const FamilyTreeScreen({super.key});
  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  List<FamilyMember> _members = [];
  List<FamilyMember> _pendingMembers = [];
  bool _isLoading = true;

  // Organized tree layers
  List<FamilyMember> _grandparents = [];
  List<FamilyMember> _parents = [];
  List<FamilyMember> _self = [];
  List<FamilyMember> _siblings = [];
  List<FamilyMember> _children = [];
  List<FamilyMember> _others = [];

  /// Initializes the screen and triggers the initial background data load.
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Asynchronously fetches family members from the database, parses their relations,
  /// and automatically synchronizes the user's master profile to the "Self" node.
  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final all = await DatabaseService().getFamilyMembers(user.$id);
        final memories = await DatabaseService().getMemories(user.$id);
        bool needsRefresh = false;

        // --- 1. Sync User Profile (Self) ---
        final profile = await DatabaseService().getUserProfile(user.$id);
        String? selfPhotoUrl;
        if (profile != null && profile.profilePhotoUrl != null) {
           selfPhotoUrl = StorageService().getProfilePhotoUrl(profile.profilePhotoUrl!);
        }
        
        final selfExists = all.any((m) => m.relation?.toLowerCase() == 'self' || m.relation?.toLowerCase() == 'me');
        if (!selfExists) {
           await DatabaseService().addFamilyMember(FamilyMember(
             id: '',
             userId: user.$id,
             fullName: profile?.fullName ?? user.name,
             relation: 'Self',
             photoUrl: selfPhotoUrl,
             isApproved: true,
           ));
           needsRefresh = true;
        } else if (selfPhotoUrl != null) {
           final selfNode = all.firstWhere((m) => m.relation?.toLowerCase() == 'self' || m.relation?.toLowerCase() == 'me');
           if (selfNode.photoUrl != selfPhotoUrl) {
             await DatabaseService().updateFamilyMember(selfNode.id, {'photoUrl': selfPhotoUrl});
             needsRefresh = true;
           }
        }

        // --- 2. Sync Contributors ---
        for (var mem in memories) {
          if (mem.contributorName != null && mem.contributorName!.isNotEmpty) {
            final exists = all.any((m) => m.fullName.toLowerCase() == mem.contributorName!.toLowerCase());
            if (!exists) {
              await DatabaseService().addFamilyMember(FamilyMember(
                id: '',
                userId: user.$id,
                fullName: mem.contributorName!,
                relation: mem.contributorRelation ?? 'Unknown',
                photoUrl: mem.contributorPhotoUrl,
                isApproved: true,
              ));
              needsRefresh = true;
            } else if (mem.contributorPhotoUrl != null && mem.contributorPhotoUrl!.isNotEmpty) {
               final existing = all.firstWhere((m) => m.fullName.toLowerCase() == mem.contributorName!.toLowerCase());
               if (existing.photoUrl == null || existing.photoUrl!.isEmpty) {
                 await DatabaseService().updateFamilyMember(existing.id, {'photoUrl': mem.contributorPhotoUrl});
                 needsRefresh = true;
               }
            }
          }
        }
        
        if (needsRefresh) {
          final refreshed = await DatabaseService().getFamilyMembers(user.$id);
          _members = refreshed.where((m) => m.isApproved).toList();
          _pendingMembers = refreshed.where((m) => !m.isApproved).toList();
        } else {
          _members = all.where((m) => m.isApproved).toList();
          _pendingMembers = all.where((m) => !m.isApproved).toList();
        }
      } else {
        _loadDemoTree();
      }
    } catch (_) {
      _loadDemoTree();
    }
    _organizeTree();
    if (mounted) setState(() => _isLoading = false);
  }

  void _loadDemoTree() {
    _members = [
      FamilyMember(id: 'd4', userId: 'demo', fullName: 'Eleanor Vance', relation: 'Grandmother', isDeceased: true, isApproved: true, dateOfBirth: '03/15/1928', gender: 'Female'),
      FamilyMember(id: 'd5', userId: 'demo', fullName: 'Arthur Miller', relation: 'Grandfather', isDeceased: true, isApproved: true, dateOfBirth: '07/22/1922', gender: 'Male'),
      FamilyMember(id: 'd2', userId: 'demo', fullName: 'Sarah Miller', relation: 'Mother', isApproved: true, gender: 'Female'),
      FamilyMember(id: 'd3', userId: 'demo', fullName: 'Julian Miller', relation: 'Father', isApproved: true, gender: 'Male'),
      FamilyMember(id: 'd1', userId: 'demo', fullName: 'Mursaline', relation: 'Self', isApproved: true, gender: 'Male'),
      FamilyMember(id: 'd6', userId: 'demo', fullName: 'Lily Miller', relation: 'Sister', isApproved: true, gender: 'Female'),
      FamilyMember(id: 'd7', userId: 'demo', fullName: 'Leo Miller', relation: 'Brother', isApproved: true, gender: 'Male'),
    ];
    _pendingMembers = [
      FamilyMember(id: 'p1', userId: 'demo', fullName: 'Aunty Shirin', relation: "Aunt", isApproved: false, gender: 'Female'),
    ];
  }

  /// Organize members into hierarchical layers by analyzing the relation field
  void _organizeTree() {
    _grandparents = [];
    _parents = [];
    _self = [];
    _siblings = [];
    _children = [];
    _others = [];

    for (final m in _members) {
      final r = (m.relation ?? '').toLowerCase();
      if (r.contains('grandm') || r.contains('grandf') || r.contains('grandp') || r.contains('nana') || r.contains('nani') || r.contains('dada') || r.contains('dadi')) {
        _grandparents.add(m);
      } else if (r.contains('mother') || r.contains('father') || r.contains('mom') || r.contains('dad') || r.contains('amma') || r.contains('abba') || r.contains('parent')) {
        _parents.add(m);
      } else if (r.contains('self') || r.contains('me') || r.contains('you')) {
        _self.add(m);
      } else if (r.contains('sister') || r.contains('brother') || r.contains('sibling') || r.contains('bhai') || r.contains('behen') || r.contains('apu') || r.contains('bhaiya')) {
        _siblings.add(m);
      } else if (r.contains('son') || r.contains('daughter') || r.contains('child') || r.contains('kid') || r.contains('beta') || r.contains('beti')) {
        _children.add(m);
      } else if (r.contains('uncle') || r.contains('aunt') || r.contains('chacha') || r.contains('mama') || r.contains('khala') || r.contains('fupu') || r.contains('mami')) {
        _others.add(m);
      } else {
        _others.add(m);
      }
    }
  }

  /// ── Explicit Gemini Integration for Demonstration ──
  Future<void> _organizeTreeWithGemini() async {
    setState(() => _isLoading = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gemini is analyzing family relations... ✨'), duration: Duration(seconds: 2)),
    );

    try {
      final apiKey = AppwriteConfig.geminiApiKey;
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite-preview:generateContent?key=$apiKey');

      final memberListJson = _members.map((m) => {'name': m.fullName, 'relation': m.relation ?? 'Unknown'}).toList();
      final membersStr = jsonEncode(memberListJson);
      
      final prompt = 'You are an intelligent family tree organizer. I will provide a list of family members with their self-reported relationship to me.\n'
          'Members: $membersStr\n\n'
          'Determine the generation of each member and return ONLY a raw JSON object (no markdown, no backticks) structured exactly like this:\n'
          '{"grandparents": ["name1"], "parents": ["name2"], "self": ["name3"], "siblings": ["name4"], "children": ["name5"], "extended": ["name6"]}\n'
          'Place each members exact full name into the correct array.';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.1}
        })
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Strip markdown if Gemini includes it
        text = text.trim();
        if (text.startsWith('```json')) {
          text = text.substring(7);
        } else if (text.startsWith('```')) text = text.substring(3);
        if (text.endsWith('```')) text = text.substring(0, text.length - 3);
        
        final rawGeminiOutput = text.trim();
        final parsed = jsonDecode(rawGeminiOutput);
        
        setState(() {
          _grandparents = _members.where((m) => (parsed['grandparents'] as List?)?.contains(m.fullName) ?? false).toList();
          _parents = _members.where((m) => (parsed['parents'] as List?)?.contains(m.fullName) ?? false).toList();
          _self = _members.where((m) => (parsed['self'] as List?)?.contains(m.fullName) ?? false).toList();
          _siblings = _members.where((m) => (parsed['siblings'] as List?)?.contains(m.fullName) ?? false).toList();
          _children = _members.where((m) => (parsed['children'] as List?)?.contains(m.fullName) ?? false).toList();
          _others = _members.where((m) => (parsed['extended'] as List?)?.contains(m.fullName) ?? false).toList();
          _isLoading = false;
        });

        // Show Gemini's reasoning in a dedicated dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                Icon(Icons.auto_awesome, color: NestTheme.deepAmber),
                const SizedBox(width: 10),
                const Text('Gemini AI Analysis'),
              ]),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Model: gemini-3.1-flash-lite-preview',
                        style: TextStyle(fontSize: 11, color: NestTheme.mist)),
                    const SizedBox(height: 8),
                    Text('Input: ${_members.length} family members analyzed',
                        style: TextStyle(fontSize: 12, color: NestTheme.charcoal)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        const JsonEncoder.withIndent('  ').convert(parsed),
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('✅ Tree organized successfully!',
                        style: TextStyle(fontSize: 12, color: NestTheme.sage, fontWeight: FontWeight.w600)),
                  ],
                ),
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
        return;
      } else {
        throw Exception('Gemini API Error');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gemini API failed. Falling back to local logic.'), backgroundColor: Colors.red),
        );
      }
      _organizeTree();
    }
    setState(() => _isLoading = false);
  }

  void _demoApprove(FamilyMember m) {
    setState(() {
      _pendingMembers.removeWhere((p) => p.id == m.id);
      _members.add(m.copyWith(isApproved: true));
      _organizeTree();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${m.fullName} approved! 🎉'),
          backgroundColor: NestTheme.sage, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  void _demoReject(FamilyMember m) {
    setState(() {
      _pendingMembers.removeWhere((p) => p.id == m.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NestTheme.cream,
      appBar: AppBar(
        title: const Text('Family Tree'),
        backgroundColor: NestTheme.cream,
        actions: [
          IconButton(
            tooltip: 'Organize with Gemini ✨',
            icon: const Icon(Icons.auto_awesome_rounded, color: NestTheme.deepAmber),
            onPressed: _organizeTreeWithGemini,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddMemberScreen()))
                .then((_) => _load()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: NestTheme.deepAmber))
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // ── Pending Approvals ──
                    if (_pendingMembers.isNotEmpty) ...[
                      _buildPendingSection(),
                      const SizedBox(height: 16),
                    ],

                    // ── Legend ──
                    _buildLegend().animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 20),

                    // ── Title ──
                    Text('Heritage Explorer',
                        style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 4),
                    Text('${_members.length} members connected',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 24),

                    // ── Visual Tree ──
                    if (_members.isEmpty)
                      _emptyState()
                    else
                      _buildVisualTree(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'tree_fab',
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddMemberScreen()))
            .then((_) => _load()),
        backgroundColor: NestTheme.deepAmber,
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }

  /// The core visual tree layout
  Widget _buildVisualTree() {
    return Column(
      children: [
        // ── Generation 1: Grandparents ──
        if (_grandparents.isNotEmpty) ...[
          _generationLabel('Grandparents', Icons.elderly_rounded),
          const SizedBox(height: 12),
          _buildNodeRow(_grandparents, NestTheme.mist),
          _buildVerticalConnector(),
        ],

        // ── Generation 2: Parents ──
        if (_parents.isNotEmpty) ...[
          _generationLabel('Parents', Icons.escalator_warning_rounded),
          const SizedBox(height: 12),
          _buildNodeRow(_parents, const Color(0xFF7B9E6F)),
          _buildVerticalConnector(),
        ],

        // ── Generation 3: Self + Siblings ──
        if (_self.isNotEmpty || _siblings.isNotEmpty) ...[
          _generationLabel('You & Siblings', Icons.people_rounded),
          const SizedBox(height: 12),
          _buildNodeRow([..._self, ..._siblings], NestTheme.deepAmber, selfId: _self.isNotEmpty ? _self.first.id : null),
          if (_children.isNotEmpty) _buildVerticalConnector(),
        ],

        // ── Generation 4: Children ──
        if (_children.isNotEmpty) ...[
          _generationLabel('Children', Icons.child_care_rounded),
          const SizedBox(height: 12),
          _buildNodeRow(_children, const Color(0xFF6BA3D6)),
        ],

        // ── Extended Family ──
        if (_others.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 1,
            color: NestTheme.mist.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          _generationLabel('Extended Family', Icons.diversity_3_rounded),
          const SizedBox(height: 12),
          _buildNodeRow(_others, NestTheme.dustyRose),
        ],
      ],
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _generationLabel(String label, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: NestTheme.charcoal.withOpacity(0.4)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: NestTheme.charcoal.withOpacity(0.4),
          letterSpacing: 1.5,
        )),
      ],
    );
  }

  /// Row of circular tree nodes for a generation
  Widget _buildNodeRow(List<FamilyMember> members, Color accentColor, {String? selfId}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: members.asMap().entries.map((entry) {
        final i = entry.key;
        final m = entry.value;
        final isSelf = m.id == selfId;
        final isUnknown = m.relation == null || m.relation!.isEmpty || m.relation!.toLowerCase() == 'unknown';
        final nodeColor = isUnknown ? Colors.red.shade400 : accentColor;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => MemberProfileScreen(member: m)))
                .then((_) => _load()),
            child: Column(
              children: [
                // ── Node circle ──
                Container(
                  width: isSelf ? 72 : 60,
                  height: isSelf ? 72 : 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelf
                        ? NestTheme.amberGradient
                        : LinearGradient(
                            colors: [nodeColor.withOpacity(0.8), nodeColor],
                          ),
                    border: Border.all(
                      color: m.isDeceased
                          ? NestTheme.mist
                          : isUnknown
                              ? Colors.red
                              : isSelf
                                  ? NestTheme.softGold
                                  : Colors.white,
                      width: isSelf || isUnknown ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isSelf ? NestTheme.amber : nodeColor).withOpacity(0.3),
                        blurRadius: isSelf ? 16 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: m.photoUrl != null && m.photoUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(m.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Center(
                    child: m.isDeceased && (m.photoUrl == null || m.photoUrl!.isEmpty)
                        ? const Icon(Icons.spa_rounded, color: Colors.white70, size: 22)
                        : (m.photoUrl == null || m.photoUrl!.isEmpty)
                            ? Text(
                                m.fullName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: isSelf ? 24 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null, // Don't show text/icon if image exists
                  ),
                ),
                const SizedBox(height: 6),
                // ── Name ──
                SizedBox(
                  width: 72,
                  child: Text(
                    m.fullName.split(' ').first,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isSelf ? 12 : 11,
                      fontWeight: isSelf ? FontWeight.w700 : FontWeight.w500,
                      color: NestTheme.charcoal,
                    ),
                  ),
                ),
                // ── Relation tag ──
                Text(
                  m.relation ?? '',
                  style: TextStyle(
                    fontSize: 9,
                    color: NestTheme.charcoal.withOpacity(0.45),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (m.isDeceased)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: NestTheme.mist.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('✝', style: TextStyle(fontSize: 9, color: NestTheme.mist)),
                  ),
              ],
            ),
          ).animate().fadeIn(delay: (i * 100).ms, duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),
        );
      }).toList(),
    );
  }

  /// Vertical connector between generations
  Widget _buildVerticalConnector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Container(width: 2, height: 12, color: NestTheme.amber.withOpacity(0.3)),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NestTheme.amber.withOpacity(0.3),
            ),
          ),
          Container(width: 2, height: 12, color: NestTheme.amber.withOpacity(0.3)),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: NestTheme.cardRadius,
        boxShadow: NestTheme.softShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legend(NestTheme.deepAmber, 'You'),
          _legend(const Color(0xFF7B9E6F), 'Living'),
          _legend(NestTheme.mist, 'Deceased'),
          _legend(NestTheme.amber, 'Pending'),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }

  Widget _buildPendingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NestTheme.amber.withOpacity(0.1),
        borderRadius: NestTheme.cardRadius,
        border: Border.all(color: NestTheme.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.notification_important_rounded, color: NestTheme.deepAmber, size: 20),
            const SizedBox(width: 8),
            Text('🔔 ${_pendingMembers.length} Pending Approval${_pendingMembers.length > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          ..._pendingMembers.map((m) => Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${m.fullName} wants to join as ${m.relation ?? "family member"}.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () async {
                      final user = AuthService().currentUser;
                      if (user != null) {
                        await DatabaseService().deleteFamilyMember(m.id);
                        _load();
                      } else {
                        _demoReject(m);
                      }
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: NestTheme.dustyRose,
                        side: BorderSide(color: NestTheme.dustyRose.withOpacity(0.5))),
                    child: const Text('Reject'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(
                    onPressed: () async {
                      final user = AuthService().currentUser;
                      if (user != null) {
                        await DatabaseService().approveFamilyMember(m.id);
                        _load();
                      } else {
                        _demoApprove(m);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: NestTheme.sage),
                    child: const Text('Approve'),
                  )),
                ]),
              ],
            ),
          )),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _emptyState() {
    return Center(
      child: Column(children: [
        const SizedBox(height: 40),
        Icon(Icons.account_tree_rounded, size: 64, color: NestTheme.mist),
        const SizedBox(height: 16),
        Text('Your family tree is empty', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Add family members to start building', style: Theme.of(context).textTheme.bodyMedium),
      ]),
    );
  }
}
