import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Creator entry point: only expose actions that lead to real workflows.
class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _media;
  bool _isVideo = false;

  Future<void> _pickMedia({required bool video, required ImageSource source}) async {
    try {
      final picked = video
          ? await _picker.pickVideo(source: source, maxDuration: const Duration(minutes: 10))
          : await _picker.pickImage(source: source, imageQuality: 90, maxWidth: 2400);
      if (picked == null || !mounted) return;
      setState(() {
        _media = picked;
        _isVideo = video;
      });
      await _openEditor();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open media: $error')));
    }
  }

  Future<void> _chooseMedia() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(alignment: Alignment.centerLeft, child: Text('Choose media', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _sourceTile(sheet, Icons.photo_library_outlined, 'Photo', () => _pickMedia(video: false, source: ImageSource.gallery))),
                  const SizedBox(width: 10),
                  Expanded(child: _sourceTile(sheet, Icons.video_library_outlined, 'Video', () => _pickMedia(video: true, source: ImageSource.gallery))),
                  const SizedBox(width: 10),
                  Expanded(child: _sourceTile(sheet, Icons.camera_alt_outlined, 'Camera', () => _pickMedia(video: false, source: ImageSource.camera))),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheet);
                    _pickMedia(video: true, source: ImageSource.camera);
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

  Widget _sourceTile(BuildContext sheet, IconData icon, String label, VoidCallback action) => InkWell(
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

  Future<void> _openEditor() async {
    final media = _media;
    if (media == null) return;
    await context.push<bool>('/editor', extra: <String, dynamic>{'isVideo': _isVideo, 'mediaPath': media.path});
  }

  void _openCreate() => context.push('/create');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Studio', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: _openCreate, tooltip: 'Create post', icon: const Icon(Icons.add_box_outlined))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text('Make something worth watching.', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Choose a real creation workflow. Editing controls appear after you select media.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 22),
          _sectionTitle('START CREATING'),
          _heroAction(icon: Icons.photo_edit_outlined, title: 'Edit a photo', subtitle: 'Select a photo and open the MANOX editor.', onTap: () => _pickMedia(video: false, source: ImageSource.gallery)),
          _heroAction(icon: Icons.video_settings_outlined, title: 'Edit a video', subtitle: 'Select a video and open the MANOX editor.', onTap: () => _pickMedia(video: true, source: ImageSource.gallery)),
          _heroAction(icon: Icons.videocam_outlined, title: 'Record a video', subtitle: 'Capture new video and continue directly to editing.', onTap: () => _pickMedia(video: true, source: ImageSource.camera)),
          const SizedBox(height: 18),
          _sectionTitle('PUBLISH'),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: theme.colorScheme.surfaceContainerHighest),
                child: const Icon(Icons.add_box_outlined),
              ),
              title: const Text('Create a post', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Padding(padding: EdgeInsets.only(top: 4), child: Text('Choose media, set audience and publish.')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _openCreate,
            ),
          ),
          if (_media != null) ...[
            const SizedBox(height: 18),
            _sectionTitle('CURRENT MEDIA'),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 190,
                child: _isVideo
                    ? Container(color: Colors.black, alignment: Alignment.center, child: const Icon(Icons.play_circle_outline, size: 64, color: Colors.white))
                    : Image.file(File(_media!.path), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: _openEditor, icon: const Icon(Icons.tune_rounded), label: const Text('Continue editing')),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      );

  Widget _heroAction({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: theme.colorScheme.surfaceContainerHighest),
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
