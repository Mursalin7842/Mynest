import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../config/theme.dart';
import '../../config/appwrite_config.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

/// ─────────────────────────────────────────────
/// Family Book — Real Storybook Page-Turner
/// ─────────────────────────────────────────────

class FamilyBookScreen extends StatefulWidget {
  const FamilyBookScreen({super.key});

  @override
  State<FamilyBookScreen> createState() => _FamilyBookScreenState();
}

class _FamilyBookScreenState extends State<FamilyBookScreen> {
  List<Memory> _memories = [];
  bool _isLoading = true;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final all = await DatabaseService().getMemories(user.$id);
        _memories = all.where((m) => m.isApproved).toList();
      } else {
        _loadDemoStories();
      }
    } catch (_) {
      _loadDemoStories();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _loadDemoStories() {
    _memories = [
      Memory(id: 'm1', userId: 'demo', title: "The Summer of '74", story: 'It was the summer that changed everything. The old house on the hill still stood proud against the amber sky. Grandmother would sit on the porch, her hands busy with the embroidery she loved so much, while the scent of jasmine drifted through the warm evening air.\n\nWe would gather around her, the children, and she would begin to speak — softly at first, as if the words themselves were fragile things. "Let me tell you about the summer your grandfather came home from the sea," she would say.\n\nAnd in those moments, the world would stop. The crickets would hush. Even the wind seemed to lean in closer to listen.', contributorName: 'Grandmother Eleanor', eventDate: 'Summer 1974', isApproved: true, status: 'chaptered'),
      Memory(id: 'm2', userId: 'demo', title: "The Old Oak Desk", story: 'The desk had been in the family for three generations. Its surface was a map of our history — a ring stain from Grandfather Arthur\'s morning tea, a small gouge from when Father tried to carve his initials at age seven, a faded ink spot from the letter Mother wrote the night before her wedding.\n\nI would sit there every evening doing my homework, running my fingers over these imperfections, each one a story waiting to be told. The drawer on the right always stuck. Inside it, wrapped in tissue paper, was a photograph I would not understand until many years later.', contributorName: 'Father Julian', eventDate: 'October 1992', isApproved: true, status: 'chaptered'),
      Memory(id: 'm3', userId: 'demo', title: "The Grand Wedding", story: 'The ceremony was held in the garden behind the old church on Maple Street. Mother had spent weeks arranging the flowers — white roses intertwined with baby\'s breath, exactly as Grandmother had done for her own wedding forty years before.\n\nThe sun broke through the clouds at precisely the right moment, casting long golden shadows across the lawn. Uncle James, never one for sentimentality, was spotted dabbing his eyes with his handkerchief. "It\'s the pollen," he insisted later, though there wasn\'t a flower within ten feet of where he stood.', contributorName: 'Uncle James', isApproved: true, status: 'chaptered'),
      Memory(id: 'm4', userId: 'demo', title: "Grandma's Secret Recipe", story: 'The recipe was never written down. It existed only in Grandma\'s hands — the precise pinch of cardamom, the exact moment to add the rosewater, the way she would tilt the pan just so to let the syrup coat the edges.\n\n"Watch carefully," she would say, never measuring anything. "Your hands will remember even when your mind forgets."\n\nI tried for years to recreate it. The taste was always close, but never quite right. Then one morning, half-asleep, I reached for the spices without thinking. My hands moved on their own. And there it was — perfect. Grandma was right. The hands remember.', contributorName: 'Mother Sarah', isApproved: true, status: 'chaptered'),
      Memory(id: 'm5', userId: 'demo', title: "Echoes of the Lake House", story: 'Every August, without fail, the entire family would pile into whatever cars were available and drive the three hours north to the lake house. The building itself was nothing special — a wooden cabin with a leaky roof and a porch that creaked under every step.\n\nBut it was everything to us.\n\nThe lake would catch the last light of the day and hold it, turning the water to liquid gold. We would swim until our fingers pruned, build fires that burned too high, and fall asleep to the sound of loons calling across the water.\n\nThe last summer we went there, nobody knew it would be the last. Perhaps that\'s for the best. Some endings are gentler when they arrive unannounced.', contributorName: 'Lily', eventDate: 'August 2019', isApproved: true, status: 'chaptered'),
    ];
  }

  Future<void> _playStory(Memory memory) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: NestTheme.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _GeminiAudioPlayer(memory: memory),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E2723),
      appBar: AppBar(
        title: const Text('Family Story Book'),
        backgroundColor: const Color(0xFF3E2723),
        foregroundColor: NestTheme.softGold,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_memories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_currentPage + 1} / ${_memories.length + 1}',
                  style: TextStyle(color: NestTheme.softGold.withAlpha(153), fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: NestTheme.softGold))
          : _memories.isEmpty
              ? _emptyState()
              : Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemCount: _memories.length + 1, // +1 for cover page
                        itemBuilder: (ctx, i) {
                          if (i == 0) return _buildCoverPage();
                          return _buildStoryPage(_memories[i - 1], i);
                        },
                      ),
                    ),
                    // Page indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _memories.length + 1,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _currentPage ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _currentPage
                                  ? NestTheme.softGold
                                  : NestTheme.softGold.withAlpha(77),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCoverPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5EDE3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: NestTheme.amber.withAlpha(77), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(77),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: NestTheme.amberGradient,
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 32),
            Text(
              'The Family\nStory Book',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium!.copyWith(
                    color: NestTheme.darkBrown,
                    height: 1.2,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 60,
              height: 2,
              color: NestTheme.amber,
            ),
            const SizedBox(height: 16),
            Text(
              '${_memories.length} Stories Preserved',
              style: TextStyle(
                color: NestTheme.charcoal.withAlpha(153),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"Before your memory fades away"',
              style: TextStyle(
                color: NestTheme.amber,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Swipe to read', style: TextStyle(color: NestTheme.mist, fontSize: 12)),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, color: NestTheme.mist, size: 16),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildStoryPage(Memory memory, int pageNum) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6F0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: NestTheme.amber.withAlpha(51), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Chapter header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: NestTheme.amber.withAlpha(51)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHAPTER $pageNum',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: NestTheme.amber,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    memory.title,
                    style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (memory.contributorName != null) ...[
                            Icon(Icons.edit_note_rounded, size: 14, color: NestTheme.mist),
                            const SizedBox(width: 4),
                            Text(
                              'Written by ${memory.contributorName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: NestTheme.charcoal.withAlpha(128),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          if (memory.eventDate != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.calendar_today_rounded, size: 12, color: NestTheme.mist),
                            const SizedBox(width: 4),
                            Text(
                              memory.eventDate!,
                              style: TextStyle(
                                fontSize: 12,
                                color: NestTheme.charcoal.withAlpha(128),
                              ),
                            ),
                          ],
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_circle_fill_rounded, color: NestTheme.deepAmber, size: 36),
                        onPressed: () => _playStory(memory),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Story body ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First letter drop cap effect
                    if (memory.story != null && memory.story!.isNotEmpty)
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: memory.story![0],
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: NestTheme.deepAmber,
                                height: 1,
                                fontFamily: 'Playfair Display',
                              ),
                            ),
                            TextSpan(
                              text: memory.story!.substring(1),
                              style: TextStyle(
                                fontSize: 15,
                                color: NestTheme.charcoal,
                                height: 1.8,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        'This story is waiting to be told...',
                        style: TextStyle(
                          fontSize: 15,
                          color: NestTheme.mist,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Page footer ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: NestTheme.amber.withAlpha(38)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MyNest Family Book',
                    style: TextStyle(fontSize: 10, color: NestTheme.mist),
                  ),
                  Text(
                    'Page $pageNum',
                    style: TextStyle(fontSize: 10, color: NestTheme.mist),
                  ),
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
          Text(
            'No stories yet',
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: NestTheme.softGold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Approved memories will appear here\nas pages in your family story book.',
            textAlign: TextAlign.center,
            style: TextStyle(color: NestTheme.softGold.withAlpha(153), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _GeminiAudioPlayer extends StatefulWidget {
  final Memory memory;
  const _GeminiAudioPlayer({required this.memory});

  @override
  State<_GeminiAudioPlayer> createState() => _GeminiAudioPlayerState();
}

class _GeminiAudioPlayerState extends State<_GeminiAudioPlayer> {
  String _status = 'Generating audio with Gemini AI...';
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _hasError = false;
  final AudioPlayer _player = AudioPlayer();
  String? _wavPath;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
        if (state == PlayerState.completed) {
          setState(() => _status = 'Narration complete');
        }
      }
    });
    _generateAndPlay();
  }

  @override
  void dispose() {
    _player.dispose();
    // Clean up temp file
    if (_wavPath != null) {
      try { File(_wavPath!).deleteSync(); } catch (_) {}
    }
    super.dispose();
  }

  /// Build a WAV file header for raw PCM data (16-bit mono 24kHz)
  Uint8List _buildWav(Uint8List pcmData) {
    const sampleRate = 24000;
    const numChannels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final blockAlign = numChannels * (bitsPerSample ~/ 8);
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;

    final header = ByteData(44);
    // RIFF header
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57);  // W
    header.setUint8(9, 0x41);  // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    // fmt sub-chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // (space)
    header.setUint32(16, 16, Endian.little); // sub-chunk size
    header.setUint16(20, 1, Endian.little);  // PCM format
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // data sub-chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);

    // Combine header + PCM data
    final wav = Uint8List(44 + dataSize);
    wav.setRange(0, 44, header.buffer.asUint8List());
    wav.setRange(44, 44 + dataSize, pcmData);
    return wav;
  }

  /// Call Gemini TTS API, convert PCM response to WAV, and play it
  Future<void> _generateAndPlay() async {
    try {
      final apiKey = AppwriteConfig.geminiApiKey;
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-tts-preview:generateContent?key=$apiKey');

      // Build the narration prompt from the story content
      final storyText = widget.memory.story ?? widget.memory.title;
      final prompt = 'Read this family story with warm emotion and nostalgia: $storyText';

      setState(() => _status = 'Sending story to Gemini AI...');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {'voiceName': 'Kore'}
              }
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        setState(() => _status = 'Processing Gemini audio...');
        final data = jsonDecode(response.body);
        final b64Audio = data['candidates'][0]['content']['parts'][0]['inlineData']['data'] as String;

        // Decode base64 PCM data and wrap in WAV container
        final pcmBytes = base64Decode(b64Audio);
        final wavBytes = _buildWav(pcmBytes);

        // Write WAV to temp file for playback
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/gemini_narration_${DateTime.now().millisecondsSinceEpoch}.wav');
        await file.writeAsBytes(wavBytes);
        _wavPath = file.path;

        setState(() {
          _isLoading = false;
          _status = 'Playing Gemini narration...';
        });

        // Start playback automatically
        await _player.play(DeviceFileSource(file.path));
      } else {
        final errBody = jsonDecode(response.body);
        final msg = errBody['error']?['message'] ?? 'Unknown error';
        setState(() {
          _isLoading = false;
          _hasError = true;
          _status = 'Gemini error: $msg';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _status = 'Connection error: ${e.toString().substring(0, 80)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 320,
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _hasError
                      ? Colors.red.withAlpha(26)
                      : NestTheme.deepAmber.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _hasError ? Icons.error_rounded : Icons.graphic_eq_rounded,
                  color: _hasError ? Colors.red : NestTheme.deepAmber,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gemini AI Voice', style: Theme.of(context).textTheme.titleMedium),
                    Text(_status,
                        style: const TextStyle(color: NestTheme.mist, fontSize: 12),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _player.stop();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Waveform animation or loading indicator
          if (_isLoading)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: NestTheme.deepAmber),
                  const SizedBox(height: 16),
                  Text(_status, style: TextStyle(color: NestTheme.mist, fontSize: 13)),
                ],
              ),
            )
          else ...[
            // Animated waveform bars when playing
            SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(20, (i) => AnimatedContainer(
                  duration: Duration(milliseconds: 300 + (i * 50)),
                  width: 4,
                  height: _isPlaying ? (15.0 + (i % 5) * 8.0) : 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: NestTheme.deepAmber.withAlpha(_isPlaying ? 200 : 80),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),
            const SizedBox(height: 16),

            // Story title being narrated
            Text(
              '♪ "${widget.memory.title}"',
              style: const TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: NestTheme.charcoal,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.memory.contributorName != null)
              Text(
                'by ${widget.memory.contributorName}',
                style: TextStyle(fontSize: 12, color: NestTheme.mist),
              ),
            const Spacer(),

            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_rounded),
                  color: NestTheme.deepAmber,
                  iconSize: 32,
                  onPressed: _wavPath != null ? () async {
                    await _player.stop();
                    await _player.play(DeviceFileSource(_wavPath!));
                  } : null,
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: NestTheme.amberGradient,
                  ),
                  child: IconButton(
                    icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    color: Colors.white,
                    iconSize: 40,
                    onPressed: () async {
                      if (_isPlaying) {
                        await _player.pause();
                      } else if (_wavPath != null) {
                        await _player.resume();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.stop_rounded),
                  color: NestTheme.deepAmber,
                  iconSize: 32,
                  onPressed: () async => await _player.stop(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
