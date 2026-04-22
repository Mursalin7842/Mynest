import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';

class MemoryDetailScreen extends StatefulWidget {
  final Memory memory;
  const MemoryDetailScreen({super.key, required this.memory});
  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  late Memory _memory;
  bool _isEditing = false;
  final _storyCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _memory = widget.memory;
    _storyCtrl.text = _memory.story ?? '';
    _titleCtrl.text = _memory.title;
    
    if (_memory.audioUrl != null) {
      _setupAudio();
    }
  }

  Future<void> _setupAudio() async {
    await _audioPlayer.setSourceUrl(_memory.audioUrl!);
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _storyCtrl.dispose();
    _titleCtrl.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await DatabaseService().updateMemory(_memory.id, {
      'title': _titleCtrl.text.trim(),
      'story': _storyCtrl.text.trim(),
    });
    setState(() {
      _memory = _memory.copyWith(title: _titleCtrl.text.trim(), story: _storyCtrl.text.trim());
      _isEditing = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Memory updated ✨'), backgroundColor: NestTheme.sage,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Memory'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseService().deleteMemory(_memory.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NestTheme.cream,
      appBar: AppBar(
        backgroundColor: NestTheme.cream,
        title: const Text('Memory Details'),
        actions: [
          if (!_isEditing) IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => setState(() => _isEditing = true)),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo ──
            if (_memory.photoUrl != null && _memory.photoUrl!.isNotEmpty)
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 400),
                color: NestTheme.parchment,
                child: Image.network(
                  _memory.photoUrl!,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: NestTheme.deepAmber));
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status & Date ──
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _memory.isApproved ? NestTheme.sage.withOpacity(0.15) : NestTheme.amber.withOpacity(0.15),
                        borderRadius: NestTheme.chipRadius,
                      ),
                      child: Text(
                        _memory.isApproved ? '✓ APPROVED' : '⏳ PENDING',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: _memory.isApproved ? NestTheme.sage : NestTheme.deepAmber),
                      ),
                    ),
                    const Spacer(),
                    if (_memory.eventDate != null) Text(_memory.eventDate!, style: Theme.of(context).textTheme.bodySmall),
                  ]),
                  const SizedBox(height: 20),

                  // ── Title ──
                  _isEditing
                      ? TextField(controller: _titleCtrl, style: Theme.of(context).textTheme.displayMedium,
                          decoration: const InputDecoration(border: InputBorder.none, hintText: 'Title...'))
                      : Text(_memory.title, style: Theme.of(context).textTheme.displayMedium).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),

                  // ── Audio Player ──
                  if (_memory.audioUrl != null && _memory.audioUrl!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: NestTheme.softShadow,
                        border: Border.all(color: NestTheme.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: NestTheme.amberGradient,
                            ),
                            child: IconButton(
                              icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                              onPressed: () {
                                if (_isPlaying) {
                                  _audioPlayer.pause();
                                } else {
                                  _audioPlayer.resume();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Voice Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                    activeTrackColor: NestTheme.amber,
                                    inactiveTrackColor: NestTheme.parchment,
                                    thumbColor: NestTheme.deepAmber,
                                  ),
                                  child: Slider(
                                    min: 0,
                                    max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1,
                                    value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1),
                                    onChanged: (v) => _audioPlayer.seek(Duration(seconds: v.toInt())),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatDuration(_position), style: const TextStyle(fontSize: 10, color: NestTheme.mist)),
                                    Text(_formatDuration(_duration), style: const TextStyle(fontSize: 10, color: NestTheme.mist)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Story ──
                  _isEditing
                      ? TextField(controller: _storyCtrl, maxLines: null, minLines: 8,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: InputDecoration(hintText: 'Write the story...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))))
                      : (_memory.story?.isNotEmpty == true
                          ? Text(_memory.story!, style: Theme.of(context).textTheme.bodyLarge).animate().fadeIn(delay: 300.ms)
                          : Container()),

                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(child: OutlinedButton(onPressed: () => setState(() => _isEditing = false), child: const Text('Cancel'))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton(onPressed: _save, child: const Text('Save'))),
                    ]),
                  ],

                  const SizedBox(height: 32),
                  Divider(color: NestTheme.mist.withOpacity(0.3)),
                  const SizedBox(height: 20),

                  // ── Contributor Info ──
                  const Text('CONTRIBUTOR DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: NestTheme.mist)),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: NestTheme.parchment),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (_memory.contributorPhotoUrl != null && _memory.contributorPhotoUrl!.isNotEmpty)
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(_memory.contributorPhotoUrl!),
                              )
                            else if (_memory.contributorName != null && _memory.contributorName!.isNotEmpty)
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: NestTheme.parchment,
                                child: Text(_memory.contributorName![0].toUpperCase(),
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: NestTheme.deepAmber)),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_memory.contributorName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  if (_memory.contributorRelation != null)
                                    Text(_memory.contributorRelation!, style: TextStyle(color: NestTheme.charcoal.withOpacity(0.6), fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_memory.contributorEmail != null || _memory.contributorPhone != null) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          if (_memory.contributorEmail != null && _memory.contributorEmail!.isNotEmpty)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              leading: const Icon(Icons.email_outlined, color: NestTheme.amber),
                              title: Text(_memory.contributorEmail!),
                              onTap: () => launchUrl(Uri.parse('mailto:${_memory.contributorEmail}')),
                            ),
                          if (_memory.contributorPhone != null && _memory.contributorPhone!.isNotEmpty)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              leading: const Icon(Icons.phone_outlined, color: NestTheme.amber),
                              title: Text(_memory.contributorPhone!),
                              onTap: () => launchUrl(Uri.parse('tel:${_memory.contributorPhone}')),
                            ),
                        ]
                      ],
                    ),
                  ),

                  if (!_memory.isApproved && !_isEditing) ...[
                    const SizedBox(height: 40),
                    SizedBox(width: double.infinity, height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await DatabaseService().approveMemory(_memory.id);
                          
                          // Auto-generate family member if contributor details exist
                          if (_memory.contributorName != null && _memory.contributorName!.isNotEmpty) {
                            try {
                              final members = await DatabaseService().getFamilyMembers(_memory.userId);
                              final exists = members.any((m) => 
                                m.fullName.toLowerCase() == _memory.contributorName!.toLowerCase());
                              
                              if (!exists) {
                                await DatabaseService().addFamilyMember(FamilyMember(
                                  id: '',
                                  userId: _memory.userId,
                                  fullName: _memory.contributorName!,
                                  relation: _memory.contributorRelation ?? 'Family',
                                  photoUrl: _memory.contributorPhotoUrl,
                                  isApproved: true,
                                ));
                              }
                            } catch (e) {
                              // Ignore if it fails, memory is still approved
                            }
                          }
                          
                          setState(() => _memory = _memory.copyWith(isApproved: true));
                        },
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Approve This Memory'),
                        style: ElevatedButton.styleFrom(backgroundColor: NestTheme.sage,
                            shape: RoundedRectangleBorder(borderRadius: NestTheme.buttonRadius)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
