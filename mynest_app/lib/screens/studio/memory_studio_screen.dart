import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';

/// ─────────────────────────────────────────────
/// Memory Studio V1.2.0 — Privacy + Photo Upload
/// ─────────────────────────────────────────────

class MemoryStudioScreen extends StatefulWidget {
  final FamilyMember? taggedMember;
  const MemoryStudioScreen({super.key, this.taggedMember});
  @override
  State<MemoryStudioScreen> createState() => _MemoryStudioScreenState();
}

class _MemoryStudioScreenState extends State<MemoryStudioScreen> {
  final _titleCtrl = TextEditingController();
  final _storyCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _isLoading = false;
  List<FamilyMember> _members = [];
  String? _selectedMemberId;
  String? _selectedMemberName;
  bool _isTypingStory = false;
  String _visibility = 'public'; // public, private, custom
  Uint8List? _photoBytes;
  String? _photoFileName;
  String? _mockAudioPath;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    if (widget.taggedMember != null) {
      _selectedMemberId = widget.taggedMember!.id;
      _selectedMemberName = widget.taggedMember!.fullName;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _storyCtrl.dispose();
    _dateCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final user = AuthService().currentUser;
    if (user != null) {
      _members = await DatabaseService().getFamilyMembers(user.$id);
      _members = _members.where((m) => m.isApproved).toList();
      
      // Validation to prevent dropdown crash
      if (_selectedMemberId != null && !_members.any((m) => m.id == _selectedMemberId)) {
         _selectedMemberId = null;
         _selectedMemberName = null;
      }
      
      if (mounted) setState(() {});
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _photoBytes = Uint8List.fromList(bytes);
      _photoFileName = picked.name;
    });
  }

  Future<void> _saveMemory() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a title')));
      return;
    }

    final user = AuthService().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memory saved locally! (Demo mode)'), backgroundColor: NestTheme.sage),
      );
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? photoUrl;
      if (_photoBytes != null) {
        final fileId = await StorageService().uploadFile(
          fileName: _photoFileName ?? 'memory_${DateTime.now().millisecondsSinceEpoch}.jpg',
          fileBytes: _photoBytes!,
        );
        photoUrl = StorageService().getFileUrl(fileId);
      }

      await DatabaseService().addMemory(Memory(
        id: '', userId: user.$id,
        title: _titleCtrl.text.trim(),
        story: _storyCtrl.text.trim().isNotEmpty ? _storyCtrl.text.trim() : null,
        photoUrl: photoUrl,
        taggedPersonId: _selectedMemberId,
        taggedPersonName: _selectedMemberName,
        eventDate: _dateCtrl.text.isNotEmpty ? _dateCtrl.text : null,
        location: _locationCtrl.text.isNotEmpty ? _locationCtrl.text : null,
        contributorName: user.name,
        isApproved: true,
        status: 'raw',
        visibility: _visibility,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Memory saved to vault! ✨'),
              backgroundColor: NestTheme.sage, behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NestTheme.cream,
      appBar: AppBar(
        title: const Text('Memory Studio'),
        backgroundColor: NestTheme.cream,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Preserve a moment', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 6),
          Text('Every memory is a seed in your family tree.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),

          // Title
          Text('Memory Title', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(controller: _titleCtrl, textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'e.g., The Summer of \'74',
                  prefixIcon: Icon(Icons.title_rounded, size: 20))),
          const SizedBox(height: 20),

          // Privacy Controls
          Text('Visibility', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(children: [
            _VisibilityChip('🌐 Public', 'public', _visibility == 'public', () => setState(() => _visibility = 'public')),
            const SizedBox(width: 8),
            _VisibilityChip('🔒 Private', 'private', _visibility == 'private', () => setState(() => _visibility = 'private')),
            const SizedBox(width: 8),
            _VisibilityChip('👥 Custom', 'custom', _visibility == 'custom', () => setState(() => _visibility = 'custom')),
          ]),
          const SizedBox(height: 20),

          // Photo upload
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              height: _photoBytes != null ? 200 : 140,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: NestTheme.cardRadius,
                border: Border.all(color: NestTheme.mist.withAlpha(128), width: 1.5),
                image: _photoBytes != null
                    ? DecorationImage(image: MemoryImage(_photoBytes!), fit: BoxFit.cover)
                    : null,
              ),
              child: _photoBytes == null
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.cloud_upload_rounded, size: 40, color: NestTheme.mist),
                      const SizedBox(height: 8),
                      Text('Tap to Upload Photo', style: Theme.of(context).textTheme.bodyMedium),
                      Text('JPEG, PNG, or scanned artifacts', style: Theme.of(context).textTheme.bodySmall),
                    ])
                  : Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, size: 18),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Tag Member
          Text('Tag Family Member', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: NestTheme.inputRadius,
                border: Border.all(color: NestTheme.mist.withAlpha(128))),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: _selectedMemberId, isExpanded: true,
              hint: const Text('Select from your tree...'),
              items: _members.map((m) => DropdownMenuItem(value: m.id,
                  child: Text(m.fullName))).toList(),
              onChanged: (v) {
                final m = _members.firstWhere((m) => m.id == v);
                setState(() { _selectedMemberId = v; _selectedMemberName = m.fullName; });
              },
            )),
          ),
          const SizedBox(height: 24),

          // Record / Type
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () async {
                final audioPath = await showModalBottomSheet<String>(
                  context: context,
                  backgroundColor: NestTheme.cream,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  builder: (ctx) => const _MockAudioRecorder(),
                );
                if (audioPath != null) {
                  setState(() => _mockAudioPath = audioPath);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: _mockAudioPath != null ? NestTheme.sage.withAlpha(26) : Colors.white, 
                  borderRadius: NestTheme.cardRadius,
                  boxShadow: NestTheme.softShadow,
                  border: _mockAudioPath != null ? Border.all(color: NestTheme.sage, width: 2) : null,
                ),
                child: Column(children: [
                  Container(padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: _mockAudioPath != null ? null : NestTheme.amberGradient, 
                      color: _mockAudioPath != null ? NestTheme.sage : null,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_mockAudioPath != null ? Icons.check_rounded : Icons.mic_rounded, color: Colors.white, size: 28)),
                  const SizedBox(height: 10),
                  Text(_mockAudioPath != null ? 'Audio Saved' : 'Record Audio', style: Theme.of(context).textTheme.titleMedium),
                ]),
              ),
            )),
            const SizedBox(width: 14),
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _isTypingStory = !_isTypingStory),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: _isTypingStory ? NestTheme.deepAmber.withAlpha(26) : Colors.white,
                  borderRadius: NestTheme.cardRadius, boxShadow: NestTheme.softShadow,
                  border: _isTypingStory ? Border.all(color: NestTheme.deepAmber, width: 2) : null),
                child: Column(children: [
                  Container(padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(gradient: NestTheme.amberGradient, shape: BoxShape.circle),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 28)),
                  const SizedBox(height: 10),
                  Text('Type Story', style: Theme.of(context).textTheme.titleMedium),
                ]),
              ),
            )),
          ]),
          const SizedBox(height: 20),

          // Story
          if (_isTypingStory) ...[
            TextFormField(controller: _storyCtrl, maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Start your narrative here...',
                    alignLabelWithHint: true)),
            const SizedBox(height: 20),
          ],

          // Date & Location
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Event Date', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              TextFormField(controller: _dateCtrl,
                  decoration: const InputDecoration(hintText: 'e.g., 1974',
                      prefixIcon: Icon(Icons.calendar_today_outlined, size: 18))),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Location', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              TextFormField(controller: _locationCtrl,
                  decoration: const InputDecoration(hintText: 'e.g., London',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 18))),
            ])),
          ]),
          const SizedBox(height: 32),

          // Save
          SizedBox(height: 58, child: ElevatedButton(
            onPressed: _isLoading ? null : _saveMemory,
            child: _isLoading
                ? const SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Save to Vault'),
          )),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;
  const _VisibilityChip(this.label, this.value, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? NestTheme.deepAmber.withAlpha(26) : Colors.white,
          borderRadius: NestTheme.chipRadius,
          border: Border.all(
            color: isSelected ? NestTheme.deepAmber : NestTheme.mist.withAlpha(128),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          color: isSelected ? NestTheme.deepAmber : NestTheme.charcoal,
        )),
      ),
    );
  }
}

class _MockAudioRecorder extends StatefulWidget {
  const _MockAudioRecorder();

  @override
  State<_MockAudioRecorder> createState() => _MockAudioRecorderState();
}

class _MockAudioRecorderState extends State<_MockAudioRecorder> {
  bool _isRecording = false;
  int _seconds = 0;

  void _toggleRecord() async {
    if (_isRecording) {
      // Stop
      Navigator.pop(context, 'mock_audio_file_${DateTime.now().millisecondsSinceEpoch}.mp3');
    } else {
      // Start
      setState(() => _isRecording = true);
      while (_isRecording && mounted) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) setState(() => _seconds++);
      }
    }
  }

  @override
  void dispose() {
    _isRecording = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 350,
      child: Column(
        children: [
          Text('Record Memory', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Share your story using your voice.', style: TextStyle(color: NestTheme.mist)),
          const SizedBox(height: 40),
          
          Text(
            '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: NestTheme.darkBrown),
          ),
          const SizedBox(height: 40),

          GestureDetector(
            onTap: _toggleRecord,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isRecording ? NestTheme.dustyRose : NestTheme.deepAmber,
                shape: BoxShape.circle,
                boxShadow: [
                  if (_isRecording)
                    BoxShadow(color: NestTheme.dustyRose.withAlpha(128), blurRadius: 20, spreadRadius: 10),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(_isRecording ? 'Tap to stop recording' : 'Tap to start recording',
              style: TextStyle(color: _isRecording ? NestTheme.dustyRose : NestTheme.charcoal)),
        ],
      ),
    );
  }
}
