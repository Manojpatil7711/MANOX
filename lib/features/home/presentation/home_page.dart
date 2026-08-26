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
      if (mounted) _showMessage('Video could not be selected: ${_cleanError(e)}');
    }
  }

  Future<void> _openCreate() async {
    final posted = await context.push<bool>('/create');
    if (posted == true && mounted) await _loadFeed();
  }

  void _openLiveCamera() => _pickVideo(ImageSource.camera);
  void _openBeats() => context.push('/beats');
  void _openNotifications() => context.push('/notifications');
  void _openMessages() => context.push('/messages');
  void _openSearch() => context.push('/search');
  void _showDiscovery(String label) => _showMessage('$label discovery selected.');

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _cleanError(Object error) => error.toString().replaceFirst('Exception: ', '');

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
                        IconButton(
                          tooltip: 'Create post',
                          icon: const Icon(Icons.add_box_outlined),
                          onPressed: _openCreate,
                        ),
                      IconButton(
                        tooltip: 'Messages',
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        onPressed: _openMessages,
                      ),
                      IconButton(
                        tooltip: 'Notifications',
                        icon: const Icon(Icons.notifications_none_rounded),
                        onPressed: _openNotifications,
                      ),
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
                  if (!_loadingFeed) Text('${_posts.length}', style: theme.textTheme.bodySmall),
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
                    child: PostCard(data: post, repository: _repository, onChanged: _loadFeed),
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
                _showDiscovery(item.label);
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openCreate,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const ManoxMark(size: 40),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Create a post…',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Add photo or video',
                onPressed: _openCreate,
                icon: const Icon(Icons.image_outlined),
              ),
              FilledButton(
                onPressed: _openCreate,
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
