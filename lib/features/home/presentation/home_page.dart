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
  int _selectedFeed = 0;

  @override
  void initState() { super.initState(); _loadFeed(); }
  @override
  void dispose() { _feedScrollController.dispose(); super.dispose(); }

  Future<void> _loadFeed() async {
    try {
      final remote = await _repository.fetchFeed();
      if (!mounted) return;
      setState(() {
        _posts = remote.map((post) => HomeDemoData(
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
        )).toList();
        _loadingFeed = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingFeed = false);
      _showMessage('Feed unavailable: ${_cleanError(e)}');
    }
  }

  Future<void> _openCreate() async {
    final posted = await context.push<bool>('/create');
    if (posted == true && mounted) await _loadFeed();
  }

  void _openProfile() => context.go('/profile');
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
              SliverToBoxAdapter(child: _topBar(theme)),
              SliverToBoxAdapter(child: _creatorDiscovery(theme)),
              SliverToBoxAdapter(child: _safetyHub(theme)),
              SliverToBoxAdapter(child: _feedTabs(theme)),
              SliverToBoxAdapter(child: _composer(theme)),
              SliverToBoxAdapter(child: _sectionHeader(theme)),
              if (_loadingFeed)
                const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
              else if (_posts.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Your creator journey starts here.\nBe the first to share something worth seeing.', textAlign: TextAlign.center),
                  )),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 112),
                  sliver: SliverList.builder(
                    itemCount: _posts.length,
                    itemBuilder: (_, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PostCard(data: _posts[index], repository: _repository, onChanged: _loadFeed),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomNav(theme),
    );
  }

  Widget _topBar(ThemeData theme) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 10, 8),
    child: Row(children: [
      const Expanded(child: ManoxBrand(compact: true)),
      IconButton(tooltip: 'Search', visualDensity: VisualDensity.compact, icon: const Icon(Icons.search_rounded), onPressed: _openSearch),
      IconButton(tooltip: 'Notifications', visualDensity: VisualDensity.compact, icon: const Icon(Icons.notifications_none_rounded), onPressed: _openNotifications),
      IconButton(tooltip: 'Messages', visualDensity: VisualDensity.compact, icon: const Icon(Icons.chat_bubble_outline_rounded), onPressed: _openMessages),
      InkWell(key: const Key('home-profile-button'), borderRadius: BorderRadius.circular(22), onTap: _openProfile, child: const ManoxMark(size: 38)),
    ]),
  );

  Widget _creatorDiscovery(ThemeData theme) {
    const items = <({String label, IconData icon, String route})>[
      (label: 'Beats', icon: Icons.auto_awesome_rounded, route: '/beats'),
      (label: 'Live', icon: Icons.radio_rounded, route: '/live'),
      (label: 'Trending', icon: Icons.local_fire_department_rounded, route: '/trending'),
      (label: 'Learn', icon: Icons.school_rounded, route: '/learn'),
      (label: 'Entertainment', icon: Icons.movie_rounded, route: '/entertainment'),
      (label: 'Sports', icon: Icons.sports_soccer_rounded, route: '/sports'),
    ];
    return SizedBox(
      height: 112,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final item = items[index];
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push(item.route),
            child: SizedBox(
              width: 72,
              child: Column(children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.surfaceContainerHighest, border: Border.all(color: theme.colorScheme.outlineVariant)),
                  child: Icon(item.icon, size: 27),
                ),
                const SizedBox(height: 7),
                Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _safetyHub(ThemeData theme) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
    child: Row(children: [
      Expanded(child: Card(color: theme.colorScheme.errorContainer, child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/women-safety'),
        child: const Padding(padding: EdgeInsets.all(12), child: Row(children: [
          Icon(Icons.emergency_outlined, size: 24), SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Women Safety', style: TextStyle(fontWeight: FontWeight.w900)), SizedBox(height: 2), Text('Safety tools', style: TextStyle(fontSize: 11))])),
        ])),
      ))),
      const SizedBox(width: 10),
      Expanded(child: Card(color: theme.colorScheme.tertiaryContainer, child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/kids-home'),
        child: const Padding(padding: EdgeInsets.all(12), child: Row(children: [
          Icon(Icons.child_care_rounded, size: 24), SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Kids Space', style: TextStyle(fontWeight: FontWeight.w900)), SizedBox(height: 2), Text('Protected mode', style: TextStyle(fontSize: 11))])),
        ])),
      ))),
    ]),
  );

  Widget _feedTabs(ThemeData theme) {
    const labels = ['For You', 'Following', 'Latest'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
      child: Row(children: List.generate(labels.length, (index) {
        final active = _selectedFeed == index;
        return Expanded(child: Padding(
          padding: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _selectedFeed = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: active ? theme.colorScheme.onSurface : theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
              child: Text(labels[index], style: TextStyle(color: active ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ),
        ));
      })),
    );
  }

  Widget _composer(ThemeData theme) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
    child: Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _openCreate,
        child: const Padding(padding: EdgeInsets.all(13), child: Row(children: [
          ManoxMark(size: 42), SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Share your world', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)), SizedBox(height: 3), Text('Photo  •  Video  •  Beat  •  Thought', style: TextStyle(fontSize: 11))])),
          Icon(Icons.add_circle_rounded, size: 30),
        ])),
      ),
    ),
  );

  Widget _sectionHeader(ThemeData theme) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
    child: Row(children: [Text('Your feed', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const Spacer(), if (!_loadingFeed) Text('${_posts.length}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700))]),
  );

  Widget _bottomNav(ThemeData theme) => NavigationBar(
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
