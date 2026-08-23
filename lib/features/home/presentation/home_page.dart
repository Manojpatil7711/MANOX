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
    if (text.isEmpty && _selectedImagePath == null) return;

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
        _posts.insert(0, HomeDemoData(
          id: post.id,
          creatorName: post.creatorName,
          handle: post.handle,
          text: post.text,
          likes: 0,
          comments: 0,
          imagePath: post.imageUrl,
          isRemote: true,
        ));
        _composerCtrl.clear();
        _selectedImagePath = null;
        _posting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _posting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post failed: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const ManoxBrand(compact: true),
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadingFeed ? null : _loadFeed,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          return Row(
            children: [
              Expanded(
                flex: isWide ? 2 : 1,
                child: RefreshIndicator(
                  onRefresh: _loadFeed,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const ManoxBrand(),
                                const SizedBox(height: 18),
                                Text('Creator community', style: theme.textTheme.headlineSmall),
                                const SizedBox(height: 6),
                                Text('Share what you create, discover makers, and grow together.', style: theme.textTheme.bodyMedium),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: OutlinedButton(
                                    onPressed: () => context.push('/auth'),
                                    child: const Text('Get started'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const ManoxMark(size: 34),
                                    const SizedBox(width: 10),
                                    Text('Create a post', style: theme.textTheme.titleMedium),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  key: const Key('post-composer-field'),
                                  controller: _composerCtrl,
                                  maxLines: 4,
                                  minLines: 2,
                                  decoration: const InputDecoration(
                                    hintText: 'Share something with the community...',
                                  ),
                                ),
                                if (_selectedImagePath != null) ...[
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(File(_selectedImagePath!), height: 180, fit: BoxFit.cover),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _posting ? null : _pickImage,
                                      icon: const Icon(Icons.image_outlined),
                                      label: const Text('Add image'),
                                    ),
                                    const Spacer(),
                                    ElevatedButton(
                                      key: const Key('post-compose-submit'),
                                      onPressed: _posting ? null : _submitPost,
                                      child: _posting
                                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Text('Post'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Text('Community', style: theme.textTheme.titleLarge),
                            const Spacer(),
                            if (!_loadingFeed) Text('${_posts.length} posts', style: theme.textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_loadingFeed)
                          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                        else if (_posts.isEmpty)
                          SizedBox(height: 180, child: Center(child: Text('No posts yet. Be the first to create!', style: theme.textTheme.bodyMedium)))
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) => PostCard(data: _posts[index], repository: _repository),
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemCount: _posts.length,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isWide)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ManoxMark(size: 34),
                            const SizedBox(height: 16),
                            Text('Build your identity.', style: theme.textTheme.headlineSmall),
                            const SizedBox(height: 8),
                            Text('Create. Connect. Grow.', style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}
