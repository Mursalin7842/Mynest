import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  String _narration = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNarration();
  }

  Future<void> _fetchNarration() async {
    try {
      final apiKey = AppwriteConfig.geminiApiKey;
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite-preview:generateContent?key=$apiKey');

      final prompt = '''
      You are the MyNest Family Storyteller. Act as a warm, nostalgic voice. 
      Read the following memory out loud (generate the spoken script). 
      Make it sound beautiful, cinematic, and emotional. Keep it short (3-4 sentences max).
      Memory Title: ${widget.memory.title}
      Memory Story: ${widget.memory.story}
      ''';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _narration = text;
          _isLoading = false;
        });
      } else {
        setState(() {
          _narration = 'Audio playback failed. Please check Gemini API key.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _narration = 'Connection error. Could not connect to Gemini.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 300,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NestTheme.deepAmber.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.graphic_eq_rounded, color: NestTheme.deepAmber),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gemini Storyteller', style: Theme.of(context).textTheme.titleMedium),
                    const Text('Playing audio narration...', style: TextStyle(color: NestTheme.mist, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: NestTheme.deepAmber))
                : SingleChildScrollView(
                    child: Text(
                      '"$_narration"',
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: NestTheme.charcoal,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 800.ms),
                  ),
          ),
        ],
      ),
    );
  }
}
