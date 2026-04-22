import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../config/appwrite_config.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';

class PhotoContextSetupScreen extends StatefulWidget {
  const PhotoContextSetupScreen({super.key});

  @override
  State<PhotoContextSetupScreen> createState() => _PhotoContextSetupScreenState();
}

class _PhotoContextSetupScreenState extends State<PhotoContextSetupScreen> {
  final _questionCtrl = TextEditingController();
  Uint8List? _imageBytes;
  bool _isLoading = false;
  String? _generatedLink;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _generateLink() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo first!'), backgroundColor: NestTheme.dustyRose),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = AuthService().currentUser;
      if (user == null) throw Exception('Not logged in');

      // Upload image
      final fileName = 'context_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileId = await StorageService().uploadFile(
        fileName: fileName,
        fileBytes: _imageBytes!,
      );

      final photoUrl = StorageService().getFileUrl(fileId);

      // Create link
      final link = await DatabaseService().createShareLink(ShareLink(
        id: '',
        userId: user.$id,
        type: 'photo_context',
        photoUrl: photoUrl,
        description: _questionCtrl.text.trim(),
      ));

      setState(() => _generatedLink = link.webUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: NestTheme.dustyRose),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyLink() {
    if (_generatedLink != null) {
      Clipboard.setData(ClipboardData(text: _generatedLink!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard!'), backgroundColor: NestTheme.sage),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NestTheme.cream,
      appBar: AppBar(
        title: const Text('Photo Story Link'),
        backgroundColor: NestTheme.cream,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Share a photo to uncover its story',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: NestTheme.darkBrown),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload an old photo and ask your family about it. Anyone with the link can add their memories.',
              style: TextStyle(fontSize: 14, color: NestTheme.charcoal.withAlpha(153)),
            ),
            const SizedBox(height: 32),

            // Image Picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: NestTheme.cardRadius,
                  border: Border.all(color: NestTheme.amber.withAlpha(51), width: 2),
                  image: _imageBytes != null
                      ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                      : null,
                ),
                child: _imageBytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, size: 48, color: NestTheme.amber.withAlpha(128)),
                          const SizedBox(height: 12),
                          const Text('Tap to select a photo', style: TextStyle(color: NestTheme.mist)),
                        ],
                      )
                    : Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 16,
                            child: IconButton(
                              icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                              onPressed: _pickImage,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Question Input
            TextField(
              controller: _questionCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Add a question or context (Optional)',
                hintText: 'e.g., Who are the people in the background? What year was this?',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: NestTheme.buttonRadius),
              ),
            ),
            const SizedBox(height: 40),

            // Generate Button
            if (_generatedLink == null)
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateLink,
                  icon: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.link_rounded),
                  label: Text(_isLoading ? 'Generating...' : 'Generate Shareable Link'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NestTheme.deepAmber,
                    shape: RoundedRectangleBorder(borderRadius: NestTheme.buttonRadius),
                  ),
                ),
              ),

            // Result
            if (_generatedLink != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NestTheme.sage.withAlpha(26),
                  borderRadius: NestTheme.cardRadius,
                  border: Border.all(color: NestTheme.sage),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: NestTheme.sage, size: 32),
                    const SizedBox(height: 12),
                    const Text('Link generated successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Text(_generatedLink!, style: const TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _copyLink,
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copy & Finish'),
                        style: ElevatedButton.styleFrom(backgroundColor: NestTheme.sage),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
