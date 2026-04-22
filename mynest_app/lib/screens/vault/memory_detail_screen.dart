import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  @override
  void initState() {
    super.initState();
    _memory = widget.memory;
    _storyCtrl.text = _memory.story ?? '';
    _titleCtrl.text = _memory.title;
  }

  @override
  void dispose() {
    _storyCtrl.dispose();
    _titleCtrl.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Memory deleted'), backgroundColor: NestTheme.charcoal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              action: SnackBarAction(label: 'Undo', textColor: NestTheme.softGold,
                  onPressed: () => DatabaseService().addMemory(_memory))),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NestTheme.cream,
      appBar: AppBar(
        backgroundColor: NestTheme.cream,
        title: const Text('Memory'),
        actions: [
          if (!_isEditing) IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => setState(() => _isEditing = true)),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
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
            // Title
            _isEditing
                ? TextField(controller: _titleCtrl, style: Theme.of(context).textTheme.displayMedium,
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Title...'))
                : Text(_memory.title, style: Theme.of(context).textTheme.displayMedium).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            if (_memory.contributorName != null)
              Row(children: [
                CircleAvatar(radius: 14, backgroundColor: NestTheme.parchment,
                    child: Text(_memory.contributorName![0].toUpperCase(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: NestTheme.deepAmber))),
                const SizedBox(width: 8),
                Text('By ${_memory.contributorName}', style: Theme.of(context).textTheme.bodyMedium),
              ]),
            const SizedBox(height: 24),
            Divider(color: NestTheme.mist.withOpacity(0.3)),
            const SizedBox(height: 24),
            // Story
            _isEditing
                ? TextField(controller: _storyCtrl, maxLines: null, minLines: 8,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(hintText: 'Write the story...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))))
                : (_memory.story?.isNotEmpty == true
                    ? Text(_memory.story!, style: Theme.of(context).textTheme.bodyLarge).animate().fadeIn(delay: 300.ms)
                    : Center(child: Padding(padding: const EdgeInsets.all(32),
                        child: Text('No story yet. Tap edit to add one.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center)))),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => setState(() => _isEditing = false), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: _save, child: const Text('Save'))),
              ]),
            ],
            if (!_memory.isApproved && !_isEditing) ...[
              const SizedBox(height: 32),
              SizedBox(width: double.infinity, height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await DatabaseService().approveMemory(_memory.id);
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
    );
  }
}
