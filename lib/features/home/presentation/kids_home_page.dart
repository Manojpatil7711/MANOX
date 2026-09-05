import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manox/features/home/data/demo_posts.dart';
import 'package:manox/features/home/data/supabase_post_repository.dart';
import 'package:manox/features/home/presentation/widgets/post_card.dart';

class KidsHomePage extends StatefulWidget {
  const KidsHomePage({super.key});

  @override
  State<KidsHomePage> createState() => _KidsHomePageState();
}

class _KidsHomePageState extends State<KidsHomePage> {
  final SupabasePostRepository _repository = SupabasePostRepository();
  static const _items = <({String title, IconData icon})>[
    (title: 'Science Experiments', icon: Icons.science_outlined),
    (title: 'History', icon: Icons.account_balance_outlined),
    (title: 'Geography Knowledge', icon: Icons.public_outlined),
    (title: 'GK', icon: Icons.menu_book_outlined),
    (title: 'Cartoon', icon: Icons.smart_toy_outlined),
  ];

  List<ManoxPost> _posts = <ManoxPost>[];
  String? _selectedCategory;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load([String? category]) async {
    setState(() => _loading = true);
    try {
      final posts = await _repository.fetchKidsContent(category: category);
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _selectedCategory = category;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kids content unavailable: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  HomeDemoData _toHomePost(ManoxPost post) => HomeDemoData(
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
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('MANOX Kids', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Parent controls',
            onPressed: () => context.push('/kids-protection'),
            icon: const Icon(Icons.lock_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(_selectedCategory),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            children: [
              Card(
                color: theme.colorScheme.tertiaryContainer,
                child: const Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user_rounded, size: 30),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kids Space', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                            SizedBox(height: 4),
                            Text('A focused, age-appropriate experience. Monetization and adult features stay outside this space.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Explore', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, index) {
                    final item = _items[index];
                    final selected = item.title == _selectedCategory;
                    return SizedBox(
                      width: 126,
                      child: Card(
                        color: selected ? theme.colorScheme.primaryContainer : null,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _load(item.title),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(item.icon, size: 28),
                                const SizedBox(height: 7),
                                Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: Text(_selectedCategory ?? 'Recommended for Kids', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                  if (_selectedCategory != null) TextButton(onPressed: () => _load(), child: const Text('ALL')),
                ],
              ),
              const SizedBox(height: 8),
              if (_loading)
                const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
              else if (_posts.isEmpty)
                Card(child: Padding(padding: const EdgeInsets.all(28), child: Column(children: const [Icon(Icons.auto_awesome_outlined, size: 40), SizedBox(height: 8), Text('No Kids content in this category yet.'), SizedBox(height: 4), Text('Try another category.', textAlign: TextAlign.center)])))
              else
                ..._posts.map((post) => Padding(padding: const EdgeInsets.only(bottom: 10), child: PostCard(data: _toHomePost(post), repository: _repository, onChanged: () => _load(_selectedCategory)))),
            ],
          ),
        ),
      ),
    );
  }
}
