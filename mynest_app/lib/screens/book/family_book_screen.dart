import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../config/appwrite_config.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

/// Family Story Book — Merges all memories into one Gemini-generated narrative.
/// Uses gemini-3.1-flash-lite-preview for story generation and
/// gemini-3.1-flash-tts-preview for audio narration with Gemini's AI voice.
class FamilyBookScreen extends StatefulWidget {
  const FamilyBookScreen({super.key});
  @override
  State<FamilyBookScreen> createState() => _FamilyBookScreenState();
}

class _FamilyBookScreenState extends State<FamilyBookScreen> {
  List<Memory> _memories = [];
  String _generatedStory = '';
  bool _isLoadingMemories = true;
  bool _isGeneratingStory = false;
  bool _storyReady = false;
  late PageController _pageCtrl;
  int _currentPage = 0;

  // Audio state
  final AudioPlayer _player = AudioPlayer();
  bool _isGeneratingAudio = false;
  bool _isPlaying = false;
  String? _wavPath;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) {
        setState(() => _isPlaying = s == PlayerState.playing);
      }
    });
    _loadAndGenerate();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _player.dispose();
    if (_wavPath != null) {
      try { File(_wavPath!).deleteSync(); } catch (_) {}
    }
    super.dispose();
  }

  /// Build a hash of all memory IDs+titles to detect changes
  String _buildMemoryHash() {
    final ids = _memories.map((m) => '${m.id}:${m.title}').join('|');
    return ids.hashCode.toString();
  }

  /// Load all memories, check cache, only regenerate if memories changed
  Future<void> _loadAndGenerate() async {
    setState(() => _isLoadingMemories = true);
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final all = await DatabaseService().getMemories(user.$id);
        _memories = all.where((m) => m.isApproved).toList();
      }
      if (_memories.isEmpty) _loadDemoMemories();
    } catch (_) {
      _loadDemoMemories();
    }
    setState(() => _isLoadingMemories = false);

    // Check if memories changed since last generation
    final prefs = await SharedPreferences.getInstance();
    final cachedHash = prefs.getString('book_memory_hash') ?? '';
    final currentHash = _buildMemoryHash();
    final cachedStory = prefs.getString('book_cached_story') ?? '';
    final cachedWav = prefs.getString('book_cached_wav') ?? '';

    if (cachedHash == currentHash && cachedStory.isNotEmpty) {
      // No new memories — use cached story
      _generatedStory = cachedStory;
      if (cachedWav.isNotEmpty && File(cachedWav).existsSync()) {
        _wavPath = cachedWav;
      }
      setState(() => _storyReady = true);
    } else {
      // Memories changed — regenerate
      await _generateMergedStory();
      // Save to cache
      prefs.setString('book_memory_hash', currentHash);
      prefs.setString('book_cached_story', _generatedStory);
    }
  }

  void _loadDemoMemories() {
    _memories = [
      Memory(id: 'm1', userId: 'demo', title: "The Summer of '74",
          story: 'Grandmother would sit on the porch, her hands busy with the embroidery she loved. The scent of jasmine drifted through the warm evening air as she began to speak softly about the summer grandfather came home from the sea.',
          contributorName: 'Grandmother Eleanor', eventDate: 'Summer 1974', isApproved: true, status: 'chaptered'),
      Memory(id: 'm2', userId: 'demo', title: "The Old Oak Desk",
          story: 'The desk had been in the family for three generations. Its surface was a map of our history — a ring stain from Grandfather Arthur\'s morning tea, a small gouge from when Father tried to carve his initials at age seven.',
          contributorName: 'Father Julian', eventDate: 'October 1992', isApproved: true, status: 'chaptered'),
      Memory(id: 'm3', userId: 'demo', title: "Grandma's Secret Recipe",
          story: 'The recipe was never written down. It existed only in Grandma\'s hands — the precise pinch of cardamom, the exact moment to add the rosewater. "Watch carefully," she would say, never measuring anything.',
          contributorName: 'Mother Sarah', isApproved: true, status: 'chaptered'),
    ];
  }

  /// Send ALL memories to Gemini to create one unified family narrative
  Future<void> _generateMergedStory() async {
    if (_memories.isEmpty) return;
    setState(() { _isGeneratingStory = true; _storyReady = false; });
    try {
      final apiKey = AppwriteConfig.geminiApiKey;
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite-preview:generateContent?key=$apiKey');

      // Build a summary of all memories for the prompt
      final memorySummaries = _memories.map((m) {
        final by = m.contributorName ?? 'Unknown';
        final date = m.eventDate ?? '';
        return '- "${m.title}" (told by $by${date.isNotEmpty ? ', $date' : ''}): ${m.story ?? 'No story yet'}';
      }).join('\n');

      final prompt = 'You are a family storyteller writing a beautiful family story book. '
          'I will give you all the memories collected from different family members. '
          'Merge ALL of them into ONE beautiful, flowing, cinematic narrative. '
          'Organize it chronologically. For each memory, mention who contributed it (e.g. "As Grandmother Eleanor recalls..."). '
          'Use warm, nostalgic, emotional language. Add smooth transitions between memories. '
          'Format with clear paragraphs. Do NOT use markdown headings or bullet points.\n\n'
          'Here are all the family memories:\n$memorySummaries';

      final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.8}
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _generatedStory = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() { _storyReady = true; _isGeneratingStory = false; });
      } else {
        setState(() => _isGeneratingStory = false);
      }
    } catch (e) {
      debugPrint('Story generation error: $e');
      setState(() => _isGeneratingStory = false);
    }
  }

  /// Build WAV header for raw PCM (16-bit mono 24kHz)
  Uint8List _buildWav(Uint8List pcm) {
    final ds = pcm.length;
    final h = ByteData(44);
    h.setUint32(0, 0x52494646, Endian.big); // RIFF
    h.setUint32(4, 36 + ds, Endian.little);
    h.setUint32(8, 0x57415645, Endian.big); // WAVE
    h.setUint32(12, 0x666D7420, Endian.big); // fmt
    h.setUint32(16, 16, Endian.little);
    h.setUint16(20, 1, Endian.little);
    h.setUint16(22, 1, Endian.little);
    h.setUint32(24, 24000, Endian.little);
    h.setUint32(28, 48000, Endian.little);
    h.setUint16(32, 2, Endian.little);
    h.setUint16(34, 16, Endian.little);
    h.setUint32(36, 0x64617461, Endian.big); // data
    h.setUint32(40, ds, Endian.little);
    final wav = Uint8List(44 + ds);
    wav.setRange(0, 44, h.buffer.asUint8List());
    wav.setRange(44, 44 + ds, pcm);
    return wav;
  }

  /// Send the FULL merged story to Gemini TTS and play the audio
  Future<void> _playFullStory() async {
    if (_generatedStory.isEmpty) return;

    // If we already have a cached WAV file, just replay it — no API call needed
    if (_wavPath != null && File(_wavPath!).existsSync()) {
      await _player.play(DeviceFileSource(_wavPath!));
      return;
    }

    setState(() => _isGeneratingAudio = true);

    try {
      final apiKey = AppwriteConfig.geminiApiKey;
      // Truncate to ~2000 chars to keep TTS response time reasonable
      final storyForTts = _generatedStory.length > 2000
          ? '${_generatedStory.substring(0, 2000)}...'
          : _generatedStory;
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-tts-preview:generateContent?key=$apiKey');

      final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': 'Read this family story with warm emotion: $storyForTts'}]}],
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'speechConfig': {'voiceConfig': {'prebuiltVoiceConfig': {'voiceName': 'Kore'}}}
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final b64 = data['candidates'][0]['content']['parts'][0]['inlineData']['data'] as String;
        final pcm = base64Decode(b64);
        final wav = _buildWav(pcm);

        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/gemini_book_${DateTime.now().millisecondsSinceEpoch}.wav');
        await file.writeAsBytes(wav);
        // Clean old file
        if (_wavPath != null) {
          try { File(_wavPath!).deleteSync(); } catch (_) {}
        }
        _wavPath = file.path;
        // Cache the WAV path for future replays
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('book_cached_wav', file.path);
        setState(() => _isGeneratingAudio = false);
        await _player.play(DeviceFileSource(file.path));
      } else {
        setState(() => _isGeneratingAudio = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio generation failed'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() => _isGeneratingAudio = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().substring(0, 60)}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Split the generated story into pages of ~600 chars each
  List<String> get _storyPages {
    if (_generatedStory.isEmpty) return [];
    final paragraphs = _generatedStory.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    final pages = <String>[];
    var current = '';
    for (final p in paragraphs) {
      if (current.length + p.length > 600 && current.isNotEmpty) {
        pages.add(current.trim());
        current = p;
      } else {
        current += '\n\n$p';
      }
    }
    if (current.trim().isNotEmpty) pages.add(current.trim());
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _storyPages;
    final totalPages = pages.length + 1; // +1 for cover

    return Scaffold(
      backgroundColor: const Color(0xFF3E2723),
      appBar: AppBar(
        title: const Text('Family Story Book'),
        backgroundColor: const Color(0xFF3E2723),
        foregroundColor: NestTheme.softGold,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          // Play/Pause button in app bar
          if (_storyReady)
            _isGeneratingAudio
                ? const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(color: NestTheme.softGold, strokeWidth: 2)),
                  )
                : IconButton(
                    icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: NestTheme.softGold, size: 32),
                    onPressed: () async {
                      if (_isPlaying) {
                        await _player.pause();
                      } else if (_wavPath != null) {
                        await _player.resume();
                      } else {
                        await _playFullStory();
                      }
                    },
                  ),
          if (pages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('${_currentPage + 1} / $totalPages',
                    style: TextStyle(color: NestTheme.softGold.withAlpha(153), fontSize: 13)),
              ),
            ),
        ],
      ),
      body: _isLoadingMemories
          ? const Center(child: CircularProgressIndicator(color: NestTheme.softGold))
          : _isGeneratingStory
              ? _buildGeneratingState()
              : !_storyReady
                  ? _emptyState()
                  : Column(
                      children: [
                        // Audio bar when playing
                        if (_isPlaying || _isGeneratingAudio)
                          _buildAudioBar().animate().fadeIn(duration: 300.ms),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageCtrl,
                            onPageChanged: (i) => setState(() => _currentPage = i),
                            itemCount: totalPages,
                            itemBuilder: (ctx, i) {
                              if (i == 0) return _buildCoverPage(pages.length);
                              return _buildStoryPage(pages[i - 1], i);
                            },
                          ),
                        ),
                        // Page dots
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(totalPages, (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _currentPage ? 24 : 8, height: 8,
                              decoration: BoxDecoration(
                                color: i == _currentPage ? NestTheme.softGold : NestTheme.softGold.withAlpha(77),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildGeneratingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: NestTheme.softGold),
          const SizedBox(height: 24),
          Text('Gemini is writing your family story...', style: TextStyle(color: NestTheme.softGold, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Merging ${_memories.length} memories into one narrative',
              style: TextStyle(color: NestTheme.softGold.withAlpha(153), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAudioBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: NestTheme.darkBrown.withAlpha(200),
      child: Row(
        children: [
          if (_isGeneratingAudio)
            const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: NestTheme.softGold, strokeWidth: 2))
          else
            ...List.generate(12, (i) => AnimatedContainer(
              duration: Duration(milliseconds: 300 + i * 40),
              width: 3, height: _isPlaying ? (8.0 + (i % 4) * 6.0) : 4,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(color: NestTheme.softGold, borderRadius: BorderRadius.circular(2)),
            )),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isGeneratingAudio ? 'Gemini is generating audio...' : 'Playing Gemini AI narration',
              style: TextStyle(color: NestTheme.softGold, fontSize: 12),
            ),
          ),
          if (!_isGeneratingAudio) ...[
            IconButton(icon: const Icon(Icons.replay_rounded, color: NestTheme.softGold, size: 20),
                onPressed: () async { await _player.stop(); _playFullStory(); }),
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: NestTheme.softGold),
              onPressed: () async {
                if (_isPlaying) await _player.pause(); else if (_wavPath != null) await _player.resume();
              },
            ),
            IconButton(icon: const Icon(Icons.stop_rounded, color: NestTheme.softGold, size: 20),
                onPressed: () async => await _player.stop()),
          ],
        ],
      ),
    );
  }

  Widget _buildCoverPage(int pageCount) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5EDE3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: NestTheme.amber.withAlpha(77), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(77), blurRadius: 30, offset: const Offset(0, 10))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 80, height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: NestTheme.amberGradient),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 32),
            Text('The Family\nStory Book', textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium!.copyWith(color: NestTheme.darkBrown, height: 1.2)),
            const SizedBox(height: 16),
            Container(width: 60, height: 2, color: NestTheme.amber),
            const SizedBox(height: 16),
            Text('${_memories.length} Memories Merged • $pageCount Pages',
                style: TextStyle(color: NestTheme.charcoal.withAlpha(153), fontSize: 13, fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            Text('"Before your memory fades away"',
                style: TextStyle(color: NestTheme.amber, fontSize: 13, fontStyle: FontStyle.italic)),
            const SizedBox(height: 24),
            // Contributors list
            Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6,
              children: _memories.where((m) => m.contributorName != null).map((m) => m.contributorName!).toSet().map((name) =>
                Chip(label: Text(name, style: const TextStyle(fontSize: 11)),
                    avatar: CircleAvatar(backgroundColor: NestTheme.deepAmber, radius: 10,
                        child: Text(name[0], style: const TextStyle(fontSize: 10, color: Colors.white))),
                    backgroundColor: NestTheme.amber.withAlpha(26)),
              ).toList(),
            ),
            const SizedBox(height: 24),
            // Play full story button
            ElevatedButton.icon(
              onPressed: _isGeneratingAudio ? null : _playFullStory,
              icon: _isGeneratingAudio
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_circle_filled),
              label: Text(_isGeneratingAudio ? 'Generating...' : 'Listen to Full Story'),
              style: ElevatedButton.styleFrom(backgroundColor: NestTheme.deepAmber, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Swipe to read', style: TextStyle(color: NestTheme.mist, fontSize: 12)),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, color: NestTheme.mist, size: 16),
            ]),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildStoryPage(String pageText, int pageNum) {
    // Find a memory that has a photo to display on this page
    final memWithPhoto = _memories.where((m) =>
        m.photoUrl != null && m.photoUrl!.isNotEmpty &&
        pageText.contains(m.contributorName ?? '###')).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6F0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: NestTheme.amber.withAlpha(51)),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            // Page header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: NestTheme.amber.withAlpha(51)))),
              child: Row(
                children: [
                  Text('PAGE $pageNum', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 3, color: NestTheme.amber)),
                  const Spacer(),
                  Text('Powered by Gemini AI', style: TextStyle(fontSize: 9, color: NestTheme.mist)),
                ],
              ),
            ),
            // Photo if available
            if (memWithPhoto.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(28, 12, 28, 0),
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(memWithPhoto.first.photoUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            // Story text
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: pageText[0],
                          style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: NestTheme.deepAmber, height: 1, fontFamily: 'Playfair Display')),
                      TextSpan(text: pageText.substring(1),
                          style: TextStyle(fontSize: 15, color: NestTheme.charcoal, height: 1.8, fontFamily: 'Inter')),
                    ],
                  ),
                ),
              ),
            ),
            // Page footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: NestTheme.amber.withAlpha(38)))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('MyNest Family Book', style: TextStyle(fontSize: 10, color: NestTheme.mist)),
                  Text('Page $pageNum', style: TextStyle(fontSize: 10, color: NestTheme.mist)),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: 64, color: NestTheme.softGold.withAlpha(128)),
          const SizedBox(height: 16),
          Text('No stories yet', style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: NestTheme.softGold)),
          const SizedBox(height: 8),
          Text('Add memories and they will appear here\nas your family story book.',
              textAlign: TextAlign.center, style: TextStyle(color: NestTheme.softGold.withAlpha(153), fontSize: 14)),
        ],
      ),
    );
  }
}
