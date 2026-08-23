import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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

    // Keep the selected file path only for this composer session.
    // The actual bytes are read at post time so the file is not uploaded prematurely.
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
        _posts.insert(
          0,
          HomeDemoData(
            id: post.id,
            creatorName: post.creatorName,
            handle: post.handle,
            text: post.text,
            likes: 0,
            comments: 0,
            imagePath: post.imageUrl,
            isRemote: true,
          ),
        );
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
        title: const Text('MANOX', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.public, key: Key('manox-home-logo'), size: 28),
        ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                const CircleAvatar(child: Icon(Icons.people)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text('Welcome to the MANOX Creator Community', style: TextStyle(fontWeight: FontWeight.bold)),
                                      SizedBox(height: 4),
                                      Text('Share what you create, follow creators, and grow together.'),
                                    ],
                                  ),
                                ),
                                TextButton(onPressed: () => context.push('/auth'), child: const Text('Get started')),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  key: const Key('post-composer-field'),
                                  controller: _composerCtrl,
                                  maxLines: 4,
                                  minLines: 1,
                                  decoration: const InputDecoration(
                                    hintText: 'Share something with the community...',
                                    border: InputBorder.none,
                                  ),
                                ),
                                if (_selectedImagePath != null) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(_selectedImagePath!, height: 160, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _posting ? null : _pickImage,
                                      icon: const Icon(Icons.image_outlined),
                                      label: const Text('Image'),
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
                        const SizedBox(height: 12),
                        if (_loadingFeed)
                          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                        else if (_posts.isEmpty)
                          SizedBox(
                            height: 200,
                            child: Center(child: Text('No posts yet. Be the first to create!', style: theme.textTheme.bodyMedium)),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) => PostCard(data: _posts[index], repository: _repository),
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
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
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        Card(child: Padding(padding: EdgeInsets.all(12), child: Text('Trending creators and communities'))),
                      ],
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
