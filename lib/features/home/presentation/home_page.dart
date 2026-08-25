import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/manox_brand.dart';
import '../data/demo_posts.dart';
import '../data/supabase_post_repository.dart';
import 'widgets/media_preview.dart';
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
  final _feedScrollController = ScrollController();

  List<HomeDemoData> _posts = List<HomeDemoData>.from(demoPosts);
  String? _selectedMediaPath;
  bool _selectedVideo = false;
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
    _feedScrollController.dispose();
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
                  ownerUserId: post.ownerUserId,
                ))
            .toList();
        _loadingFeed = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingFeed = false);
      _showMessage('Live feed unavailable: ${_cleanError(e)}');
    }
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (image != null && mounted) {
      setState(() {
        _selectedMediaPath = image.path;
        _selectedVideo = false;
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 10),
      );
      if (video != null && mounted) {
        setState(() {
          _selectedMediaPath = video.path;
          _selectedVideo = true;
        });
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Video could not be selected: ${_cleanError(e)}');
      }
    }
  }

  Future<void> _chooseVideoSource() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Record video'),
              onTap: () {
                Navigator.pop(sheet);
                _pickVideo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheet);
                _pickVideo(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLiveCamera() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 2000,
      );
      if (image == null || !mounted) return;
      setState(() {
        _selectedMediaPath = image.path;
        _selectedVideo = false;
      });
      _showMessage('Camera opened.');
    } catch (e) {
      if (mounted) {
        _showMessage('Camera could not open: ${_cleanError(e)}');
      }
    }
  }

  void _openBeats() => context.push('/beats');
  void _openNotifications() => context.push('/notifications');
  void _openMessages() => context.push('/messages');
  void _openSearch() => context.push('/search');
  void _showDiscovery(String label) => _showMessage('$label discovery selected.');
  void _showComingSoon(String feature) => _showMessage('$feature is being prepared for MANOX.');

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _cleanError(Object error) => error.toString().replaceFirst('Exception: ', '');

  Future<void> _submitPost() async {
    final text = _composerCtrl.text.trim();
    if (text.isEmpty && _selectedMediaPath == null) {
      _showMessage('Add text, image or video before posting.');
      return;
    }

    setState(() => _posting = true);
    try {
      String? mediaPath;
      var mediaType = 'post';

      if (_selectedMediaPath != null) {
        final picked = XFile(_selectedMediaPath!);
        final bytes = await picked.readAsBytes();
        final extension = picked.path.split('.').last.toLowerCase();

        if (_selectedVideo) {
          mediaPath = await _repository.uploadVideo(
            bytes,
            extension,
            picked.mimeType,
          );
          mediaType = 'video';
        } else {
          mediaPath = await _repository.uploadImage(
            bytes,
            extension,
            picked.mimeType,
          );
          mediaType = 'image';
        }
      }

      final post = await _repository.createPost(
        text: text,
        imagePath: mediaPath,
        mediaType: mediaType,
      );

      if (!mounted) return;
      setState(() {
        _posts.insert(
          0,
          HomeDemoData(
            id: post.id,
            creatorName: post.creatorName,
            handle: post.handle,
            text: post.text,
            imagePath: post.imageUrl,
            isRemote: true,
            ownerUserId: post.ownerUserId,
          ),
        );
        _composerCtrl.clear();
        _selectedMediaPath = null;
        _selectedVideo = false;
        _posting = false;
      });
      _showMessage('Posted successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _posting = false);
      _showMessage('Post failed: ${_cleanError(e)}');
    }
  }

  void _openEntertainment() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        const items = <({String name, IconData icon})>[
          (name: 'Comedy', icon: Icons.emoji_emotions_outlined),
          (name: 'Movies', icon: Icons.movie_outlined),
          (name: 'Web Series', icon: Icons.live_tv_outlined),
          (name: 'Music', icon: Icons.music_note_outlined),
          (name: 'BEATS', icon: Icons.auto_awesome_rounded),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Entertainment',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items
                      .map(
                        (item) => ActionChip(
                          avatar: Icon(item.icon, size: 19),
                          label: Text(item.name),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            item.name == 'BEATS'
                                ? _openBeats()
                                : _showDiscovery(item.name);
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCreateSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Create on MANOX',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _createAction(sheetContext, Icons.image_outlined, 'Image', _pickImage),
                  _createAction(sheetContext, Icons.videocam_outlined, 'Video', _chooseVideoSource),
                  _createAction(sheetContext, Icons.bolt_rounded, 'Shorts', () => _showComingSoon('Shorts')),
                  _createAction(sheetContext, Icons.school_outlined, 'Lecture', () => _showComingSoon('Lecture')),
                  _createAction(sheetContext, Icons.radio_outlined, 'Live', _openLiveCamera),
                  _createAction(sheetContext, Icons.edit_outlined, 'Text', () {
                    Navigator.pop(sheetContext);
                    FocusScope.of(context).requestFocus();
                  }),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _posting ? null : () => Navigator.pop(sheetContext),
                icon: const Icon(Icons.post_add_rounded),
                label: const Text('Open post composer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createAction(
    BuildContext sheetContext,
    IconData icon,
    String label,
    VoidCallback action,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 19),
      label: Text(label),
      onPressed: () {
        Navigator.pop(sheetContext);
        action();
      },
    );
  }

  Widget _headerIcon(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 390;
              return Material(
                color: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Search MANOX',
                        icon: const Icon(Icons.search_rounded),
                        onPressed: _openSearch,
                      ),
                      Expanded(
                        child: Align(
                          alignment: compact ? Alignment.center : Alignment.centerLeft,
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ManoxBrand(compact: true),
                          ),
                        ),
                      ),
                      if (!compact)
                        _headerIcon(Icons.add_box_outlined, 'Create', _openCreateSheet),
                      _headerIcon(Icons.chat_bubble_outline_rounded, 'Messages', _openMessages),
                      _headerIcon(Icons.notifications_none_rounded, 'Notifications', _openNotifications),
                      IconButton(
                        tooltip: 'Profile',
                        icon: const Icon(Icons.person_outline_rounded),
                        onPressed: () => context.push('/profile'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFeed,
          child: ListView(
            controller: _feedScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
            children: [
              _discoveryRow(theme),
              const SizedBox(height: 12),
              _composerCard(theme),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'For You',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  if (!_loadingFeed)
                    Text('${_posts.length}', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 10),
              if (_loadingFeed)
                const Padding(
                  padding: EdgeInsets.all(36),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_posts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(36),
                  child: Center(child: Text('No content yet. Be the first to create.')),
                )
              else
                ..._posts.map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PostCard(data: post, repository: _repository),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _discoveryRow(ThemeData theme) {
    const items = <({String label, IconData icon})>[
      (label: 'BEATS', icon: Icons.auto_awesome_rounded),
      (label: 'Live', icon: Icons.radio_rounded),
      (label: 'Trending', icon: Icons.local_fire_department_rounded),
      (label: 'Learn', icon: Icons.school_rounded),
      (label: 'Entertainment', icon: Icons.movie_rounded),
      (label: 'Sports', icon: Icons.sports_soccer_rounded),
    ];

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final item = items[index];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (item.label == 'BEATS') {
                _openBeats();
              } else if (item.label == 'Live') {
                _openLiveCamera();
              } else if (item.label == 'Entertainment') {
                _openEntertainment();
              } else {
                _showDiscovery(item.label);
              }
            },
            child: Container(
              width: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 23),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _composerCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                const ManoxMark(size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    key: const Key('post-composer-field'),
                    controller: _composerCtrl,
                    maxLines: 2,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Share a Beat…',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Add image',
                  onPressed: _posting ? null : _pickImage,
                  icon: const Icon(Icons.image_outlined),
                ),
              ],
            ),
            if (_selectedMediaPath != null) ...[
              const SizedBox(height: 8),
              if (_selectedVideo)
                ManoxLocalVideoPreview(path: _selectedMediaPath!, height: 150)
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_selectedMediaPath!),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              if (_selectedVideo)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'VIDEO • ready to post',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
            const Divider(height: 16),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _posting ? null : _openCreateSheet,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Create'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _posting ? null : _submitPost,
                  child: _posting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
