import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/supabase_post_repository.dart';
import '../presentation/widgets/media_preview.dart';
import '../../editor/presentation/professional_media_editor_v2_page.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key, this.initialBeat = false});
  final bool initialBeat;

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _captionController = TextEditingController();
  final _repository = SupabasePostRepository();

  XFile? _media;
  bool _isVideo = false;
  bool _posting = false;
  bool _legalAccepted = false;
  bool _addToBeats = false;
  bool _allowComments = true;
  bool _allowDownloads = true;
  bool _kidsContent = false;
  String _audience = 'Everyone';
  String _kidsCategory = 'General';

  static const _kidsCategories = [
    'General',
    'Education',
    'Entertainment',
    'Sports',
    'Music',
  ];

  @override
  void initState() {
    super.initState();
    _addToBeats = widget.initialBeat;
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openMediaPicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Add media', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(sheet, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(sheet, ImageSource.camera),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = source == ImageSource.camera
        ? await picker.pickImage(source: source)
        : await picker.pickMedia();

    if (picked == null || !mounted) return;

    setState(() {
      _media = picked;
      _isVideo = isManoxVideo(picked.path);
    });
  }

  Future<void> _openTools() async {
    final media = _media;
    if (media == null) {
      _show('Add media first.');
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfessionalMediaEditorV2Page(
          mediaPath: media.path,
          isVideo: _isVideo,
        ),
      ),
    );

    if (result == true && mounted) setState(() {});
  }

  Future<void> _publish() async {
    if (_posting) return;
    final media = _media;
    if (media == null) {
      _show('Add a photo or video first.');
      return;
    }
    if (!_legalAccepted) {
      _show('Accept the legal terms before publishing.');
      return;
    }

    setState(() => _posting = true);
    try {
      final post = await _repository.createPost(
        text: _captionController.text.trim(),
        imagePath: media.path,
        mediaType: _addToBeats ? 'beat' : (_isVideo ? 'video' : 'image'),
        audienceCategory: _kidsContent ? 'kids_15_plus' : 'general',
        kidsCategory: _kidsContent ? _kidsCategory : null,
        visibility: _audience == 'Followers' ? 'followers' : (_audience == 'Only me' ? 'private' : 'public'),
        allowComments: _allowComments,
        allowDownloads: _allowDownloads,
      );

      if (!mounted) return;
      _show('Published successfully.');
      Navigator.pop(context, post.id);
    } catch (error) {
      _show(error is StateError ? error.message : 'Could not publish. Please try again.');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = _media;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          onPressed: _posting ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        title: const Text('Create', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _posting ? null : _publish,
              child: _posting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (media != null) _mediaPreview() else _emptyMedia(),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              minLines: 3,
              maxLines: 7,
              maxLength: 2200,
              decoration: const InputDecoration(
                labelText: 'Caption',
                hintText: 'Tell your story...',
                alignLabelWithHint: true,
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _addToBeats,
              onChanged: _posting ? null : (value) => setState(() => _addToBeats = value),
              title: const Text('Add to BEATS', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Make this post discoverable in BEATS.'),
            ),
            if (_addToBeats)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'BEATS works best with vertical short-form video.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Quick edit', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(media == null ? 'Add media to open the editor' : 'Trim, crop, filters, speed and text'),
                trailing: const Icon(Icons.chevron_right_rounded),
                enabled: media != null && !_posting,
                onTap: media == null || _posting ? null : _openTools,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('Audience', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_audience),
                trailing: const Icon(Icons.chevron_right_rounded),
                enabled: !_posting,
                onTap: _posting ? null : _showAudience,
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _allowComments,
              onChanged: _posting ? null : (value) => setState(() => _allowComments = value),
              title: const Text('Allow comments'),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _allowDownloads,
              onChanged: _posting ? null : (value) => setState(() => _allowDownloads = value),
              title: const Text('Allow downloads'),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _kidsContent,
              onChanged: _posting ? null : (value) => setState(() => _kidsContent = value),
              title: const Text('Made for kids', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Applies the appropriate kids-content restrictions.'),
            ),
            if (_kidsContent)
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: _kidsCategory,
                    decoration: const InputDecoration(labelText: 'Kids category'),
                    items: _kidsCategories
                        .map((value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                        .toList(),
                    onChanged: _posting
                        ? null
                        : (value) => setState(() => _kidsCategory = value ?? _kidsCategory),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Card(
              child: CheckboxListTile(
                value: _legalAccepted,
                onChanged: _posting
                    ? null
                    : (value) async {
                        if (value != true) return;
                        try {
                          await _repository.saveCurrentLegalConsent();
                          if (mounted) setState(() => _legalAccepted = true);
                        } catch (_) {
                          _show('Could not save legal consent.');
                        }
                      },
                title: const Text(
                  'I accept Terms, Privacy Policy and Community Guidelines',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Required before publishing user-generated content.'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showAudience() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Who can see this?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            for (final option in ['Everyone', 'Followers', 'Only me'])
              ListTile(
                leading: Icon(
                  _audience == option ? Icons.radio_button_checked : Icons.radio_button_off,
                ),
                title: Text(option),
                onTap: () {
                  setState(() => _audience = option);
                  Navigator.pop(sheet);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _emptyMedia() => InkWell(
        onTap: _posting ? null : _openMediaPicker,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.initialBeat ? Icons.video_library_rounded : Icons.add_photo_alternate_outlined, size: 56),
              const SizedBox(height: 12),
              Text(
                widget.initialBeat ? 'Upload your BEAT video' : 'Add photo or video',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text('Gallery • Camera • Video', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _mediaPreview() {
    final media = _media!;
    final previewHeight = MediaQuery.sizeOf(context).height * 0.58;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _isVideo
              ? SizedBox(
                  height: previewHeight,
                  child: ManoxLocalVideoPreview(path: media.path, height: previewHeight),
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: previewHeight),
                  child: Image.file(File(media.path), fit: BoxFit.contain),
                ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _posting ? null : _openTools,
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Quick edit'),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: 'Replace media',
              onPressed: _posting ? null : _openMediaPicker,
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
          ],
        ),
      ],
    );
  }
}
