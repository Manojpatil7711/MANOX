import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/manox_brand.dart';
import '../data/demo_posts.dart';
import '../data/supabase_post_repository.dart';
import 'widgets/post_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _composerCtrl = TextEditingController();
  final _repository = SupabasePostRepository();
  final _picker = ImagePicker();
  List<HomeDemoData> _posts = List<HomeDemoData>.from(demoPosts);
  String? _selectedImagePath;
  bool _loadingFeed = true;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  @override
  void dispose() {
    _composerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    try {
      final remote = await _repository.fetchFeed();
      if (!mounted) return;
      setState(() {
        _posts = remote
            .map((post) => HomeDemoData(
                  id: post.id,
                  creatorName: post.creatorName,
                  handle: post.handle,
                  text: post.text,
                  likes: post.likes,
                  comments: post.comments,
                  imagePath: post.imageUrl,
                  likedByMe: post.likedByMe,
                  isRemote: true,
                ))
            .toList();
        _loadingFeed = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingFeed = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Live feed unavailable: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 2000);
    if (image == null) return;
    setState(() => _selectedImagePath = image.path);
  }

  Future<void> _submitPost() async {
    final text = _composerCtrl.text.trim();
    if (text.isEmpty && _selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add text or an image before posting.')));
      return;
    }
    setState(() => _posting = true);
    try {
      String? imagePath;
      if (_selectedImagePath != null) {
        final picked = XFile(_selectedImagePath!);
        final bytes = await picked.readAsBytes();
        final extension = picked.path.split('.').last.toLowerCase();
        imagePath = await _repository.uploadImage(bytes, extension, picked.mimeType);
      }
      final post = await _repository.createPost(text: text, imagePath: imagePath);
      if (!mounted) return;
      setState(() {
        _posts.insert(0, HomeDemoData(id: post.id, creatorName: post.creatorName, handle: post.handle, text: post.text, likes: 0, comments: 0, imagePath: post.imageUrl, isRemote: true));
        _composerCtrl.clear();
        _selectedImagePath = null;
        _posting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Posted successfully.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _posting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post failed: ${e.toString().replaceFirst('Exception: ', '')}')));
    }
  }

  void _openCreateSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Align(alignment: Alignment.centerLeft, child: Text('Create on MANOX', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _createAction(sheetContext, Icons.image_outlined, 'Image', _pickImage),
              _createAction(sheetContext, Icons.videocam_outlined, 'Video', () => _showComingSoon('Video upload')),
              _createAction(sheetContext, Icons.bolt_rounded, 'Shorts', () => _showComingSoon('Shorts')), 
              _createAction(sheetContext, Icons.school_outlined, 'Lecture', () => _showComingSoon('Lecture')), 
              _createAction(sheetContext, Icons.radio_outlined, 'Live', () => _showComingSoon('Live')), 
              _createAction(sheetContext, Icons.edit_outlined, 'Text', () { Navigator.pop(sheetContext); FocusScope.of(context).requestFocus(); }),
            ]),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _posting ? null : () { Navigator.pop(sheetContext); }, icon: const Icon(Icons.post_add_rounded), label: const Text('Open post composer')),
          ]),
        ),
      ),
    );
  }

  Widget _createAction(BuildContext sheetContext, IconData icon, String label, VoidCallback action) {
    return ActionChip(avatar: Icon(icon, size: 19), label: Text(label), onPressed: () { Navigator.pop(sheetContext); action(); });
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$feature is being prepared for MANOX.')));
  }

  void _openNotifications() => context.push('/notifications');

  void _openMessages() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Messages are ready to open from the chat entry when messaging is enabled.')));
  }

  void _openSearch() {
    try {
      context.push('/search');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search is not available yet.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const ManoxBrand(compact: true),
        leading: IconButton(tooltip: 'Search MANOX', icon: const Icon(Icons.search_rounded), onPressed: _openSearch),
        actions: [
          _headerIcon(Icons.add_box_outlined, 'Create', _openCreateSheet),
          _headerIcon(Icons.chat_bubble_outline_rounded, 'Messages', _openMessages),
          _headerIcon(Icons.notifications_none_rounded, 'Notifications', _openNotifications),
          IconButton(tooltip: 'Profile', icon: const Icon(Icons.person_outline_rounded), onPressed: () => context.push('/profile')),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFeed,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
            children: [
              _discoveryRow(theme),
              const SizedBox(height: 12),
              _composerCard(theme),
              const SizedBox(height: 16),
              Row(children: [Text('For You', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const Spacer(), if (!_loadingFeed) Text('${_posts.length}', style: theme.textTheme.bodySmall)]),
              const SizedBox(height: 10),
              if (_loadingFeed)
                const Padding(padding: EdgeInsets.all(36), child: Center(child: CircularProgressIndicator()))
              else if (_posts.isEmpty)
                const Padding(padding: EdgeInsets.all(36), child: Center(child: Text('No content yet. Be the first to create.')))
              else
                ..._posts.map((post) => Padding(padding: const EdgeInsets.only(bottom: 10), child: PostCard(data: post, repository: _repository))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIcon(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(tooltip: tooltip, icon: Icon(icon), onPressed: onPressed);
  }

  Widget _discoveryRow(ThemeData theme) {
    const items = [
      ('Live', Icons.radio_rounded),
      ('Trending', Icons.local_fire_department_rounded),
      ('Learn', Icons.school_rounded),
      ('Entertainment', Icons.movie_rounded),
      ('Sports', Icons.sports_soccer_rounded),
      ('BEATS', Icons.auto_awesome_rounded),
    ];
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) => InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${items[index].$1} discovery selected.'))),
          child: Container(
            width: 82,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: theme.dividerColor)),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(items[index].$2, size: 25), const SizedBox(height: 5), Text(items[index].$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))]),
          ),
        ),
      ),
    );
  }

  Widget _composerCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [const ManoxMark(size: 34), const SizedBox(width: 10), Expanded(child: TextField(key: const Key('post-composer-field'), controller: _composerCtrl, maxLines: 2, minLines: 1, decoration: const InputDecoration(hintText: 'Share a Beat…', border: InputBorder.none))), IconButton(tooltip: 'Add image', onPressed: _posting ? null : _pickImage, icon: const Icon(Icons.image_outlined))]),
          if (_selectedImagePath != null) ...[const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_selectedImagePath!), height: 150, width: double.infinity, fit: BoxFit.cover))],
          const Divider(height: 16),
          Row(children: [TextButton.icon(onPressed: _posting ? null : _openCreateSheet, icon: const Icon(Icons.add_circle_outline_rounded), label: const Text('Create')), const Spacer(), FilledButton(onPressed: _posting ? null : _submitPost, child: _posting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Post'))]),
        ]),
      ),
    );
  }
}
