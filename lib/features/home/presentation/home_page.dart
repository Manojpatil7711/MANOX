import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  final _repository = SupabasePostRepository();
  final _feedScrollController = ScrollController();
  List<HomeDemoData> _posts = List<HomeDemoData>.from(demoPosts);
  bool _loadingFeed = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _feedError;
  String? _nextPublishedAt;
  String? _nextId;
  int _selectedFeed = 0;

  @override
  void initState() {
    super.initState();
    _feedScrollController.addListener(_onFeedScroll);
    _loadFeed();
  }

  @override
  void dispose() {
    _feedScrollController.removeListener(_onFeedScroll);
    _feedScrollController.dispose();
    super.dispose();
  }

  void _onFeedScroll() {
    if (!_feedScrollController.hasClients || _loadingFeed || _loadingMore || !_hasMore) return;
    if (_feedScrollController.position.pixels >= _feedScrollController.position.maxScrollExtent - 700) {
      _loadMoreFeed();
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
        allowComments: post.allowComments,
        allowDownloads: post.allowDownloads,
      );

  Future<void> _loadFeed() async {
    if (mounted) {
      setState(() {
        _loadingFeed = true;
        _feedError = null;
      });
    }
    try {
      if (_selectedFeed == 1) {
        final posts = await _repository.fetchFollowingFeed(limit: 50);
        if (!mounted) return;
        setState(() {
          _posts = posts.map(_toHomePost).toList();
          _nextPublishedAt = null;
          _nextId = null;
          _hasMore = false;
          _loadingFeed = false;
          _feedError = null;
        });
      } else if (_selectedFeed == 2) {
        final posts = await _repository.fetchLatestFeed(limit: 50);
        if (!mounted) return;
        setState(() {
          _posts = posts.map(_toHomePost).toList();
          _nextPublishedAt = null;
          _nextId = null;
          _hasMore = false;
          _loadingFeed = false;
          _feedError = null;
        });
      } else {
        final page = await _repository.fetchFeedPage(pageSize: 20);
        if (!mounted) return;
        setState(() {
          _posts = page.posts.map(_toHomePost).toList();
          _nextPublishedAt = page.nextPublishedAt;
          _nextId = page.nextId;
          _hasMore = page.hasMore;
          _loadingFeed = false;
          _feedError = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingFeed = false;
        _feedError = _cleanError(e);
      });
      _showMessage('Feed unavailable. Pull to refresh or tap Retry.');
    }
  }

  Future<void> _loadMoreFeed() async {
    if (_selectedFeed != 0 || _loadingFeed || _loadingMore || !_hasMore || _nextPublishedAt == null || _nextId == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repository.fetchFeedPage(
        beforePublishedAt: _nextPublishedAt,
        beforeId: _nextId,
        pageSize: 20,
      );
      if (!mounted) return;
      final existingIds = _posts.map((post) => post.id).toSet();
      final additional = page.posts
          .where((post) => !existingIds.contains(post.id))
          .map(_toHomePost)
          .toList();
      setState(() {
        _posts = [..._posts, ...additional];
        _nextPublishedAt = page.nextPublishedAt;
        _nextId = page.nextId;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      _showMessage('Could not load more posts: ${_cleanError(e)}');
    }
  }

  Future<void> _openCreate() async {
    final posted = await context.push<bool>('/create');
    if (posted == true && mounted) await _loadFeed();
  }

  void _openProfile() => context.push('/profile');
  void _openMessages() => context.push('/messages');
  void _openNotifications() => context.push('/notifications');
  void _openSearch() => context.push('/search');

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _cleanError(Object error) => error.toString().replaceFirst('Exception: ', '');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFeed,
          child: CustomScrollView(
            controller: _feedScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _topBar()),
              SliverToBoxAdapter(child: _creatorDiscovery(theme)),
              SliverToBoxAdapter(child: _safetyHub(theme)),
              SliverToBoxAdapter(child: _feedTabs(theme)),
              SliverToBoxAdapter(child: _composer(theme)),
              SliverToBoxAdapter(child: _sectionHeader(theme)),
              if (_loadingFeed)
                SliverToBoxAdapter(child: _feedSkeleton(theme))
              else if (_feedError != null && _posts.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _feedErrorState(theme))
              else if (_posts.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _emptyFeed(theme))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 112),
                  sliver: SliverList.builder(
                    itemCount: _posts.length + (_loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _posts.length) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PostCard(
                          data: _posts[index],
                          repository: _repository,
                          onChanged: _loadFeed,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomNav(theme),
    );
  }

  Widget _feedSkeleton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 112),
      child: Column(
        children: List.generate(
          2,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _SkeletonBox(width: 44, height: 44, radius: 22, color: theme.colorScheme.surfaceContainerHighest),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SkeletonBox(width: 120, height: 13, color: theme.colorScheme.surfaceContainerHighest),
                              const SizedBox(height: 7),
                              _SkeletonBox(width: 75, height: 10, color: theme.colorScheme.surfaceContainerHighest),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SkeletonBox(width: double.infinity, height: 12, color: theme.colorScheme.surfaceContainerHighest),
                    const SizedBox(height: 8),
                    _SkeletonBox(width: 190, height: 12, color: theme.colorScheme.surfaceContainerHighest),
                    const SizedBox(height: 14),
                    _SkeletonBox(width: double.infinity, height: 190, radius: 15, color: theme.colorScheme.surfaceContainerHighest),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _feedErrorState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(color: theme.colorScheme.errorContainer, shape: BoxShape.circle),
              child: Icon(Icons.cloud_off_rounded, size: 32, color: theme.colorScheme.onErrorContainer),
            ),
            const SizedBox(height: 16),
            Text(
              'Your feed is taking a break',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              _feedError ?? 'Something went wrong while loading your feed.',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loadFeed,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyFeed(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 46, color: theme.colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              'Your creator journey starts here',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              'Be the first to share something worth seeing.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _openCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create a post'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 8),
      child: Row(
        children: [
          const Expanded(child: ManoxBrand(compact: true)),
          IconButton(tooltip: 'Search', visualDensity: VisualDensity.compact, icon: const Icon(Icons.search_rounded), onPressed: _openSearch),
          IconButton(tooltip: 'Notifications', visualDensity: VisualDensity.compact, icon: const Icon(Icons.notifications_none_rounded), onPressed: _openNotifications),
          IconButton(tooltip: 'Messages', visualDensity: VisualDensity.compact, icon: const Icon(Icons.chat_bubble_outline_rounded), onPressed: _openMessages),
          InkWell(
            key: const Key('home-profile-button'),
            borderRadius: BorderRadius.circular(22),
            onTap: _openProfile,
            child: const ManoxMark(size: 38),
          ),
        ],
      ),
    );
  }

  Widget _creatorDiscovery(ThemeData theme) {
    const items = [
      ('Beats', Icons.auto_awesome_rounded, '/beats'),
      ('Live', Icons.radio_rounded, '/live'),
      ('Trending', Icons.local_fire_department_rounded, '/trending'),
      ('Learn', Icons.school_rounded, '/learn'),
      ('Entertainment', Icons.movie_rounded, '/entertainment'),
      ('Sports', Icons.sports_soccer_rounded, '/sports'),
    ];

    return SizedBox(
      height: 112,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push(item.$3),
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surfaceContainerHighest,
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Icon(item.$2, size: 27),
                  ),
                  const SizedBox(height: 7),
                  Text(item.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _safetyHub(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: _SafetyCard(
              color: theme.colorScheme.errorContainer,
              icon: Icons.emergency_outlined,
              title: 'Women Safety',
              subtitle: 'Safety tools',
              onTap: () => context.push('/women-safety'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SafetyCard(
              color: theme.colorScheme.tertiaryContainer,
              icon: Icons.child_care_rounded,
              title: 'Kids Space',
              subtitle: 'Protected mode',
              onTap: () => context.push('/kids-home'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedTabs(ThemeData theme) {
    const labels = ['For You', 'Following', 'Latest'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = _selectedFeed == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async { if (_selectedFeed == index) return; setState(() => _selectedFeed = index); await _loadFeed(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? theme.colorScheme.onSurface : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: active ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _composer(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _openCreate,
          child: const Padding(
            padding: EdgeInsets.all(13),
            child: Row(
              children: [
                ManoxMark(size: 42),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Share your world', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      SizedBox(height: 3),
                      Text('Photo  •  Video  •  Beat  •  Thought', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.add_circle_rounded, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Row(
        children: [
          Text('Your feed', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const Spacer(),
          if (!_loadingFeed)
            Text('${_posts.length}${_hasMore ? '+' : ''}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _bottomNav(ThemeData theme) {
    return NavigationBar(
      height: 72,
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 1) context.push('/trending');
        if (index == 2) _openCreate();
        if (index == 3) context.push('/beats');
        if (index == 4) _openProfile();
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore_rounded), label: 'Discover'),
        NavigationDestination(icon: Icon(Icons.add_rounded), selectedIcon: Icon(Icons.add_circle_rounded), label: 'Create'),
        NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome_rounded), label: 'Beats'),
        NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }
}

class _SafetyCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SafetyCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Color color;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.color,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
    );
  }
}
