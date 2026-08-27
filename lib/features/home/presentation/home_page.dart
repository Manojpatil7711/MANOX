import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/manox_brand.dart';
import '../data/demo_posts.dart';
import '../data/supabase_post_repository.dart';
import 'widgets/post_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repository = SupabasePostRepository();
  final _feedScrollController = ScrollController();
  List<HomeDemoData> _posts = List<HomeDemoData>.from(demoPosts);
  bool _loadingFeed = true;

  @override void initState() { super.initState(); _loadFeed(); }
  @override void dispose() { _feedScrollController.dispose(); super.dispose(); }

  Future<void> _loadFeed() async {
    try {
      final remote = await _repository.fetchFeed();
      if (!mounted) return;
      setState(() { _posts = remote.map((post) => HomeDemoData(id: post.id, creatorName: post.creatorName, handle: post.handle, text: post.text, likes: post.likes, comments: post.comments, imagePath: post.imageUrl, likedByMe: post.likedByMe, isRemote: true, ownerUserId: post.ownerUserId)).toList(); _loadingFeed = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingFeed = false);
      _showMessage('Live feed unavailable: ${_cleanError(e)}');
    }
  }

  Future<void> _openCreate() async { final posted = await context.push<bool>('/create'); if (posted == true && mounted) await _loadFeed(); }
  void _openBeats() => context.push('/beats');
  void _openNotifications() => context.push('/notifications');
  void _openMessages() => context.push('/messages');
  void _openSearch() => context.push('/search');
  void _showMessage(String message) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); }
  String _cleanError(Object error) => error.toString().replaceFirst('Exception: ', '');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 8,
        title: Row(children: [const Expanded(child: ManoxBrand(compact: true)), IconButton(tooltip: 'Search MANOX', icon: const Icon(Icons.search_rounded), onPressed: _openSearch)]),
        actions: [
          IconButton(tooltip: 'Create', icon: const Icon(Icons.add_circle_outline_rounded), onPressed: _openCreate),
          IconButton(tooltip: 'Messages', icon: const Icon(Icons.chat_bubble_outline_rounded), onPressed: _openMessages),
          IconButton(tooltip: 'Notifications', icon: const Icon(Icons.notifications_none_rounded), onPressed: _openNotifications),
          IconButton(tooltip: 'Profile', icon: const Icon(Icons.person_outline_rounded), onPressed: () => context.push('/profile')),
        ],
      ),
      body: SafeArea(child: RefreshIndicator(onRefresh: _loadFeed, child: ListView(
        controller: _feedScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 92),
        children: [
          _discoveryRow(theme),
          const SizedBox(height: 14),
          _feedFilter(theme),
          const SizedBox(height: 12),
          _composerCard(),
          const SizedBox(height: 18),
          Row(children: [Text('For You', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const Spacer(), if (!_loadingFeed) Text('${_posts.length} posts', style: theme.textTheme.bodySmall)]),
          const SizedBox(height: 10),
          if (_loadingFeed) const Padding(padding: EdgeInsets.all(36), child: Center(child: CircularProgressIndicator()))
          else if (_posts.isEmpty) const Padding(padding: EdgeInsets.all(36), child: Center(child: Text('No content yet. Be the first to create.')))
          else ..._posts.map((post) => Padding(padding: const EdgeInsets.only(bottom: 10), child: PostCard(data: post, repository: _repository, onChanged: _loadFeed))),
        ],
      ))),
      bottomNavigationBar: _bottomNav(theme),
    );
  }

  Widget _feedFilter(ThemeData theme) => SizedBox(height: 38, child: Row(children: [
    Expanded(child: _filterChip('For You', true, theme)),
    const SizedBox(width: 8), Expanded(child: _filterChip('Following', false, theme)),
    const SizedBox(width: 8), Expanded(child: _filterChip('Latest', false, theme)),
  ]));

  Widget _filterChip(String label, bool active, ThemeData theme) => Container(alignment: Alignment.center, decoration: BoxDecoration(color: active ? theme.colorScheme.onSurface : theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(color: active ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 12)));

  Widget _discoveryRow(ThemeData theme) {
    const items = <({String label, IconData icon, String route})>[
      (label: 'BEATS', icon: Icons.auto_awesome_rounded, route: '/beats'),
      (label: 'LIVE', icon: Icons.radio_rounded, route: '/live'),
      (label: 'TRENDING', icon: Icons.local_fire_department_rounded, route: '/trending'),
      (label: 'LEARN', icon: Icons.school_rounded, route: '/learn'),
      (label: 'ENTERTAIN', icon: Icons.movie_rounded, route: '/entertainment'),
      (label: 'SPORTS', icon: Icons.sports_soccer_rounded, route: '/sports'),
    ];
    return SizedBox(height: 92, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, index) {
      final item = items[index];
      return InkWell(borderRadius: BorderRadius.circular(22), onTap: () => context.push(item.route), child: Container(width: 82, decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [theme.colorScheme.surfaceContainerHighest, theme.colorScheme.surface])), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: theme.colorScheme.outline)), child: Icon(item.icon, size: 22)), const SizedBox(height: 6), Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800))])));
    }));
  }

  Widget _composerCard() => Card(child: InkWell(borderRadius: BorderRadius.circular(18), onTap: _openCreate, child: const Padding(padding: EdgeInsets.all(14), child: Row(children: [ManoxMark(size: 42), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Create something', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), SizedBox(height: 3), Text('Post a thought, photo, video or Beat', style: TextStyle(fontSize: 12))])), Icon(Icons.add_circle_rounded, size: 28)]))));

  Widget _bottomNav(ThemeData theme) => NavigationBar(selectedIndex: 0, onDestinationSelected: (index) { if (index == 1) context.push('/trending'); else if (index == 2) _openCreate(); else if (index == 3) _openBeats(); else if (index == 4) context.push('/profile'); }, destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'), NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore_rounded), label: 'Discover'), NavigationDestination(icon: Icon(Icons.add_rounded), selectedIcon: Icon(Icons.add_circle_rounded), label: 'Create'), NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome_rounded), label: 'Beats'), NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile')]);
}
