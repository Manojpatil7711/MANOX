import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../data/supabase_post_repository.dart';
import 'widgets/media_preview.dart';

/// Full-screen creator flow: choose media, edit it, add a caption, then publish.
class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _picker = ImagePicker();
  final _repository = SupabasePostRepository();
  final _captionController = TextEditingController();

  XFile? _media;
  bool _isVideo = false;
  bool _posting = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool video, required ImageSource source}) async {
    final picked = video
        ? await _picker.pickVideo(source: source, maxDuration: const Duration(minutes: 10))
        : await _picker.pickImage(source: source, imageQuality: 90, maxWidth: 2400);
    if (picked == null || !mounted) return;
    setState(() {
      _media = picked;
      _isVideo = video;
    });
  }

  Future<void> _openMediaPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(alignment: Alignment.centerLeft, child: Text('Add to your post', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _sourceTile(sheet, Icons.photo_library_outlined, 'Photo', () => _pick(video: false, source: ImageSource.gallery))),
                  const SizedBox(width: 10),
                  Expanded(child: _sourceTile(sheet, Icons.video_library_outlined, 'Video', () => _pick(video: true, source: ImageSource.gallery))),
                  const SizedBox(width: 10),
                  Expanded(child: _sourceTile(sheet, Icons.camera_alt_outlined, 'Camera', () => _pick(video: false, source: ImageSource.camera))),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheet);
                    _pick(video: true, source: ImageSource.camera);
                  },
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Record video'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceTile(BuildContext sheet, IconData icon, String label, VoidCallback action) {
    return InkWell(
      onTap: () {
        Navigator.pop(sheet);
        action();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
        child: Column(children: [Icon(icon, size: 28), const SizedBox(height: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))]),
      ),
    );
  }

  Future<void> _editMedia() async {
    final media = _media;
    if (media == null) return;
    final result = await context.push<bool>('/editor', extra: <String, dynamic>{'isVideo': _isVideo, 'mediaPath': media.path});
    if (result == true && mounted) setState(() {});
  }

  void _openTools() => context.push('/tools');

  Future<void> _publish() async {
    final media = _media;
    final caption = _captionController.text.trim();
    if (media == null && caption.isEmpty) {
      _show('Add a photo, video or caption first.');
      return;
    }
    setState(() => _posting = true);
    try {
      String? mediaPath;
      var mediaType = 'post';
      if (media != null) {
        final bytes = await media.readAsBytes();
        final extension = media.path.split('.').last.toLowerCase();
        if (_isVideo) {
          mediaPath = await _repository.uploadVideo(bytes, extension, media.mimeType);
          mediaType = 'video';
        } else {
          mediaPath = await _repository.uploadImage(bytes, extension, media.mimeType);
          mediaType = 'image';
        }
      }
      await _repository.createPost(text: caption, imagePath: mediaPath, mediaType: mediaType);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _posting = false);
      _show(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _show(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(tooltip: 'Close', onPressed: _posting ? null : () => Navigator.of(context).pop(false), icon: const Icon(Icons.close_rounded)),
        title: const Text('Create post', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: _posting ? null : _openTools, tooltip: 'Tools', icon: const Icon(Icons.build_circle_outlined)),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilledButton(
              onPressed: _posting ? null : _publish,
              child: _posting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Post'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (_media == null) _emptyMedia() else _mediaPreview(),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              maxLength: 2200,
              maxLines: 6,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Write a caption…', alignLabelWithHint: true, border: OutlineInputBorder()),
            ),
            const SizedBox(height: 6),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('Add media'),
                    subtitle: const Text('Photo, video or camera'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _openMediaPicker,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.build_circle_outlined),
                    title: const Text('Tools'),
                    subtitle: const Text('Photo design + video editing studio'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _openTools,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyMedia() {
    return InkWell(
      onTap: _openMediaPicker,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 320,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor)),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 58),
            SizedBox(height: 14),
            Text('Add photo or video', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('Gallery • Camera • Video', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _mediaPreview() {
    final media = _media!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _isVideo
              ? ManoxLocalVideoPreview(path: media.path, height: 430)
              : Image.file(media: media.path, height: 430, fit: BoxFit.contain),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: OutlinedButton.icon(onPressed: _openTools, icon: const Icon(Icons.build_circle_outlined), label: const Text('Tools'))),
            const SizedBox(width: 10),
            IconButton.filledTonal(tooltip: 'Replace media', onPressed: _openMediaPicker, icon: const Icon(Icons.swap_horiz_rounded)),
          ],
        ),
      ],
    );
  }
}
