import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
    final picked = video
        ? await _picker.pickVideo(source: source, maxDuration: const Duration(minutes: 10))
        : await _picker.pickImage(source: source, imageQuality: 90, maxWidth: 2400);
    if (picked == null || !mounted) return;
    setState(() {
      _media = picked;
      _isVideo = video;
    });
    await _openEditor();
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
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () { Navigator.pop(sheet); _pickMedia(video: true, source: ImageSource.camera); }, icon: const Icon(Icons.videocam_outlined), label: const Text('Record video'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceTile(BuildContext sheet, IconData icon, String label, VoidCallback action) => InkWell(
        onTap: () { Navigator.pop(sheet); action(); },
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
      appBar: AppBar(title: const Text('Tools', style: TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(onPressed: _openCreate, tooltip: 'Create post', icon: const Icon(Icons.add_box_outlined))]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text('Create like a studio', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('MANOX brings photo-design and video-editing controls into one creator workflow.'),
          const SizedBox(height: 20),
          _sectionTitle('PHOTO DESIGN'),
          _toolCard(icon: Icons.image_outlined, title: 'Photo Editor', subtitle: 'Crop • ratios • filters • colour • brightness • contrast • saturation • text', onTap: () => _pickMedia(video: false, source: ImageSource.gallery)),
          _toolCard(icon: Icons.text_fields_rounded, title: 'Text & Captions', subtitle: 'Add text directly over your selected photo or video.', onTap: () => _pickMedia(video: false, source: ImageSource.gallery)),
          const SizedBox(height: 18),
          _sectionTitle('VIDEO STUDIO'),
          _toolCard(icon: Icons.video_settings_outlined, title: 'Video Editor', subtitle: 'Crop • ratios • filters • colour • text • playback speed • full-screen preview', onTap: () => _pickMedia(video: true, source: ImageSource.gallery)),
          _toolCard(icon: Icons.speed_rounded, title: 'Speed & Playback', subtitle: 'Preview video at 0.5×, 1×, 1.5× or 2× while editing.', onTap: () => _pickMedia(video: true, source: ImageSource.gallery)),
          const SizedBox(height: 18),
          _sectionTitle('CREATOR WORKFLOW'),
          _toolCard(icon: Icons.auto_awesome_rounded, title: 'Edit selected media', subtitle: 'Open the complete MANOX editor with all currently supported controls.', onTap: _media == null ? _chooseMedia : _openEditor),
          if (_media != null) ...[
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(16), child: SizedBox(height: 180, child: _isVideo ? Container(color: Colors.black, alignment: Alignment.center, child: const Icon(Icons.play_circle_outline, size: 64, color: Colors.white)) : Image.file(File(_media!.path), fit: BoxFit.cover))),
          ],
          const SizedBox(height: 20),
          Text('The toolbox exposes only implemented MANOX controls. Additional Canva-style design and CapCut-style editing capabilities can be added as their underlying functionality is implemented.', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)));

  Widget _toolCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          leading: Container(width: 46, height: 46, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Theme.of(context).colorScheme.surfaceContainerHighest), child: Icon(icon)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      );
}
