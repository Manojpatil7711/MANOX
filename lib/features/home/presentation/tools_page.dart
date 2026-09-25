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
  int _category = 0;

  static const _categories = ['All', 'Video', 'Photo', 'Text', 'Audio'];

  Future<void> _pickMedia({required bool video, required ImageSource source}) async {
    final picked = video
        ? await _picker.pickVideo(source: source, maxDuration: const Duration(minutes: 10))
        : await _picker.pickImage(source: source, imageQuality: 95, maxWidth: 3000);
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
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Start creating', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 5),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Pick a photo or video. MANOX opens the editor immediately.'),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _sourceTile(sheet, Icons.photo_library_rounded, 'Gallery', () => _pickMedia(video: false, source: ImageSource.gallery))),
                  const SizedBox(width: 10),
                  Expanded(child: _sourceTile(sheet, Icons.video_library_rounded, 'Video', () => _pickMedia(video: true, source: ImageSource.gallery))),
                  const SizedBox(width: 10),
                  Expanded(child: _sourceTile(sheet, Icons.camera_alt_rounded, 'Camera', () => _pickMedia(video: false, source: ImageSource.camera))),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheet);
                    _pickMedia(video: true, source: ImageSource.camera);
                  },
                  icon: const Icon(Icons.videocam_rounded),
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
    onTap: () { Navigator.pop(sheet); action(); },
    borderRadius: BorderRadius.circular(20),
    child: Container(
      height: 94,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .35),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 30),
        const SizedBox(height: 7),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ]),
    ),
  );

  Future<void> _openEditor() async {
    final media = _media;
    if (media == null) {
      await _chooseMedia();
      return;
    }
    await context.push<bool>('/editor', extra: <String, dynamic>{
      'isVideo': _isVideo,
      'mediaPath': media.path,
    });
  }

  void _openCreate() => context.push('/create');

  List<({String title, String subtitle, IconData icon, int category})> get _features => [
    (title: 'Trim & timeline', subtitle: 'Cut clips precisely and control the start/end', icon: Icons.content_cut_rounded, category: 1),
    (title: 'Filters & looks', subtitle: 'Natural, Cinema, Warm, Cool, Vintage, B&W and Vivid', icon: Icons.auto_awesome_rounded, category: 0),
    (title: 'Crop & ratios', subtitle: '9:16, 4:5, 1:1, 16:9 and 4:3', icon: Icons.crop_rounded, category: 2),
    (title: 'Text overlays', subtitle: 'Add readable captions directly onto media', icon: Icons.text_fields_rounded, category: 3),
    (title: 'Speed & volume', subtitle: '0.5× to 2× playback and audio control', icon: Icons.tune_rounded, category: 4),
    (title: 'MANOX Beats', subtitle: 'Add a published beat to your video', icon: Icons.music_note_rounded, category: 4),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final features = _features.where((f) => _category == 0 || f.category == 0 || f.category == _category).toList();
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create Studio', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(tooltip: 'Create post', onPressed: _openCreate, icon: const Icon(Icons.add_box_outlined)),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            sliver: SliverToBoxAdapter(
              child: InkWell(
                onTap: _openEditor,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: Colors.black,
                    image: _media != null && !_isVideo
                        ? DecorationImage(image: FileImage(File(_media!.path)), fit: BoxFit.cover, opacity: .72)
                        : null,
                  ),
                  child: Stack(children: [
                    if (_media != null && _isVideo) const Center(child: Icon(Icons.play_circle_fill_rounded, size: 74, color: Colors.white)),
                    if (_media == null) const Center(child: Icon(Icons.add_rounded, size: 72, color: Colors.white70)),
                    Positioned(left: 18, top: 18, child: _pill(_media == null ? 'CREATE' : (_isVideo ? 'VIDEO' : 'PHOTO'))),
                    Positioned(left: 18, right: 18, bottom: 18, child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_media == null ? 'Make something worth watching.' : 'Continue editing',
                          style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(_media == null ? 'Pick media and jump straight into the editor.' : 'Filters, crop, text, audio and export.',
                          style: const TextStyle(color: Colors.white70)),
                      ])),
                      const SizedBox(width: 12),
                      FilledButton(onPressed: _openEditor, child: Text(_media == null ? 'START' : 'EDIT')),
                    ])),
                  ]),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) => ChoiceChip(
                    label: Text(_categories[index]),
                    selected: _category == index,
                    onSelected: (_) => setState(() => _category = index),
                    showCheckmark: false,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, index) {
                  final item = features[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      elevation: 0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        leading: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          child: Icon(item.icon),
                        ),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                        subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(item.subtitle)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: _openEditor,
                      ),
                    ),
                  );
                },
                childCount: features.length,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: _openEditor,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: Text(_media == null ? 'Choose media & open editor' : 'Open editor'),
        ),
      ),
    );
  }

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
  );
}
