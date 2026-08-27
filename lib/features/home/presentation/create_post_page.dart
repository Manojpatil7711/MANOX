import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../data/supabase_post_repository.dart';
import 'widgets/media_preview.dart';

class CreatePostPage extends StatefulWidget {
  final bool initialBeat;
  const CreatePostPage({super.key, this.initialBeat = false});
  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _picker = ImagePicker();
  final _repository = SupabasePostRepository();
  final _captionController = TextEditingController();
  XFile? _media;
  late bool _isVideo;
  late bool _isBeat;
  bool _posting = false;
  bool _kidsContent = false;
  String _kidsCategory = 'Science Experiments';

  static const _kidsCategories = [
    'Science Experiments', 'Maths', 'English', 'History', 'Geography',
    'GK', 'Art & Drawing', 'Music & Dance', 'Sports', 'Coding',
  ];

  @override
  void initState() {
    super.initState();
    _isVideo = widget.initialBeat;
    _isBeat = widget.initialBeat;
  }

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
      if (!video) _isBeat = false;
    });
  }

  Future<void> _openMediaPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.initialBeat ? 'Upload a BEAT' : 'Add to your post', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 16),
            Row(children: [
              if (!widget.initialBeat) ...[
                Expanded(child: _sourceTile(sheet, Icons.photo_library_outlined, 'Photo', () => _pick(video: false, source: ImageSource.gallery))),
                const SizedBox(width: 10),
              ],
              Expanded(child: _sourceTile(sheet, Icons.video_library_outlined, 'Video', () => _pick(video: true, source: ImageSource.gallery))),
              if (!widget.initialBeat) const SizedBox(width: 10),
              if (!widget.initialBeat) Expanded(child: _sourceTile(sheet, Icons.camera_alt_outlined, 'Camera', () => _pick(video: false, source: ImageSource.camera))),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () { Navigator.pop(sheet); _pick(video: true, source: ImageSource.camera); },
                icon: const Icon(Icons.videocam_outlined),
                label: Text(widget.initialBeat ? 'Record BEAT' : 'Record video'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _sourceTile(BuildContext sheet, IconData icon, String label, VoidCallback action) {
    return InkWell(
      onTap: () { Navigator.pop(sheet); action(); },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
        child: Column(children: [Icon(icon, size: 28), const SizedBox(height: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))]),
      ),
    );
  }

  void _openTools() => context.push('/tools');

  Future<void> _publish() async {
    final media = _media;
    final caption = _captionController.text.trim();
    if (media == null && caption.isEmpty) {
      _show(widget.initialBeat ? 'Select a video to upload your BEAT.' : 'Add a photo, video or caption first.');
      return;
    }
    if (_isBeat && !_isVideo) {
      _show('BEATS can only contain video.');
      return;
    }
    if (_kidsContent && !_isVideo) {
      _show('Kids content must be a video.');
      return;
    }
    if (widget.initialBeat && !_isVideo) {
      _show('Select a video for your BEAT.');
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
          mediaType = _isBeat ? 'beat' : 'video';
        } else {
          mediaPath = await _repository.uploadImage(bytes, extension, media.mimeType);
          mediaType = 'image';
        }
      }
      await _repository.createPost(
        text: caption,
        imagePath: mediaPath,
        mediaType: mediaType,
        audienceCategory: _kidsContent ? 'kids_15_plus' : 'general',
        kidsCategory: _kidsContent ? _kidsCategory : null,
      );
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
        title: Text(widget.initialBeat ? 'Upload BEAT' : 'Create post', style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: _posting ? null : _openTools, tooltip: 'Tools', icon: const Icon(Icons.build_circle_outlined)),
          Padding(padding: const EdgeInsets.only(right: 10), child: FilledButton(onPressed: _posting ? null : _publish, child: _posting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Post'))),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (_media == null) _emptyMedia() else _mediaPreview(),
            const SizedBox(height: 16),
            TextField(controller: _captionController, maxLength: 2200, maxLines: 6, minLines: 3, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(hintText: widget.initialBeat ? 'Write a BEAT caption…' : 'Write a caption…', alignLabelWithHint: true, border: const OutlineInputBorder())),
            const SizedBox(height: 6),
            if (_isVideo && !widget.initialBeat)
              Card(child: SwitchListTile.adaptive(secondary: const Icon(Icons.music_note_rounded), title: const Text('Add to BEATS', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Public BEATS are separate from Kids content'), value: _isBeat, onChanged: _posting ? null : (v) => setState(() => _isBeat = v))),
            if (widget.initialBeat)
              const Card(child: ListTile(leading: Icon(Icons.music_note_rounded), title: Text('BEAT video', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('Your video will appear in the full-screen BEATS feed.'))),
            Card(child: SwitchListTile.adaptive(secondary: const Icon(Icons.child_care_rounded), title: const Text('Kids content', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Routes this content only to MANOX Kids'), value: _kidsContent, onChanged: widget.initialBeat || _posting ? null : (v) => setState(() { _kidsContent = v; if (v) _isBeat = false; }))),
            if (_kidsContent) Card(child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: DropdownButtonFormField<String>(initialValue: _kidsCategory, decoration: const InputDecoration(labelText: 'Kids category'), items: _kidsCategories.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: _posting ? null : (v) => setState(() => _kidsCategory = v ?? _kidsCategory)))),
            Card(child: Column(children: [
              ListTile(leading: const Icon(Icons.photo_library_outlined), title: Text(widget.initialBeat ? 'Choose BEAT video' : 'Add media'), subtitle: Text(widget.initialBeat ? 'Gallery video or camera recording' : 'Photo, video or camera'), trailing: const Icon(Icons.chevron_right_rounded), onTap: _posting ? null : _openMediaPicker),
              const Divider(height: 1),
              ListTile(leading: const Icon(Icons.build_circle_outlined), title: const Text('Tools'), subtitle: const Text('Photo design + video editing studio'), trailing: const Icon(Icons.chevron_right_rounded), onTap: _posting ? null : _openTools),
            ])),
          ],
        ),
      ),
    );
  }

  Widget _emptyMedia() => InkWell(
    onTap: _posting ? null : _openMediaPicker,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      height: 320,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(widget.initialBeat ? Icons.video_library_rounded : Icons.add_photo_alternate_outlined, size: 58),
        const SizedBox(height: 14),
        Text(widget.initialBeat ? 'Upload your BEAT video' : 'Add photo or video', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(widget.initialBeat ? 'Gallery • Camera • Vertical video' : 'Gallery • Camera • Video', style: const TextStyle(fontSize: 13)),
      ]),
    ),
  );

  Widget _mediaPreview() {
    final media = _media!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ClipRRect(borderRadius: BorderRadius.circular(20), child: _isVideo ? ManoxLocalVideoPreview(path: media.path, height: 430) : Image.file(File(media.path), height: 430, fit: BoxFit.contain)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: _posting ? null : _openTools, icon: const Icon(Icons.build_circle_outlined), label: const Text('Tools'))),
        const SizedBox(width: 10),
        IconButton.filledTonal(tooltip: 'Replace media', onPressed: _posting ? null : _openMediaPicker, icon: const Icon(Icons.swap_horiz_rounded)),
      ]),
    ]);
  }
}
