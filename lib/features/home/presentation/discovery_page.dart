import 'package:flutter/material.dart';
import '../data/demo_posts.dart';
import '../data/supabase_post_repository.dart';
import 'widgets/post_card.dart';

class DiscoveryPage extends StatefulWidget {
  final String title;
  final IconData icon;

  const DiscoveryPage({super.key, required this.title, required this.icon});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  final _repository = SupabasePostRepository();
  final _searchController = TextEditingController();

  List<HomeDemoData> _posts = [];
  bool _loading = true;
  String _trendWindow = '24h';
  String _category = 'All';
  String _sport = 'All Sports';

  bool get _isTrending => widget.title == 'Trending';
  bool get _isSports => widget.title == 'Sports';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _trendScore(dynamic post) => post.likes * 3 + post.comments * 2;

  bool _isSportsPost(dynamic post) {
    final text = '${post.text} ${post.creatorName}'.toLowerCase();
    return RegExp(
      r'football|cricket|soccer|tennis|kabaddi|hockey|basketball|volleyball|badminton|athletics|sports|fifa|ipl|olympic',
    ).hasMatch(text);
  }

  Future<void> _load() async {
    try {
      var posts = await _repository.fetchFeed();

      if (_isSports) {
        posts = posts.where(_isSportsPost).toList();
      }

      if (_isTrending) {
        posts.sort((a, b) => _trendScore(b).compareTo(_trendScore(a)));
      }

      if (!mounted) return;
      setState(() {
        _posts = posts
            .map(
              (post) => HomeDemoData(
                id: post.id,
                creatorName: post.creatorName,
                handle: post.handle,
                text: post.text,
                likes: post.likes,
                comments: post.comments,
                imagePath: post.imageUrl,
                mediaType: post.contentType,
                likedByMe: post.likedByMe,
                isRemote: true,
                ownerUserId: post.ownerUserId,
              ),
            )
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<HomeDemoData> get _filteredPosts {
    var result = List<HomeDemoData>.from(_posts);
    final query = _searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result
          .where(
            (post) =>
                '${post.text} ${post.creatorName} ${post.handle}'
                    .toLowerCase()
                    .contains(query),
          )
          .toList();
    }

    if (_isSports && _sport != 'All Sports') {
      result = result
          .where((post) => post.text.toLowerCase().contains(_sport.toLowerCase()))
          .toList();
    }

    if (_category == 'Videos') {
      result = result.where((post) => post.mediaType == 'video').toList();
    } else if (_category == 'Images') {
      result = result.where((post) => post.mediaType == 'image').toList();
    }

    if (_isTrending) {
      result.sort((a, b) => _trendScore(b).compareTo(_trendScore(a)));
    }

    return result;
  }

  Widget _filterChips() {
    final values = _isSports
        ? ['All', 'Videos', 'Images']
        : ['All', 'Videos', 'Images'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(value),
                selected: _category == value,
                onSelected: (_) => setState(() => _category = value),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sportsHeader() {
    return _headerCard(
      icon: Icons.sports_soccer_rounded,
      title: 'Sports Hub',
      subtitle: 'Discover sports content by game, teams and players.',
      hint: 'Search sports, teams or players…',
      extra: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final sport in [
              'All Sports',
              'Cricket',
              'Football',
              'Tennis',
              'Kabaddi',
              'Hockey',
              'Basketball',
              'Athletics',
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(sport),
                  selected: _sport == sport,
                  onSelected: (_) => setState(() => _sport = sport),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _trendingHeader() {
    return _headerCard(
      icon: Icons.local_fire_department_rounded,
      title: 'Trending Now',
      subtitle: 'Discover rising MANOX topics and content.',
      hint: 'Search a trend or topic…',
      extra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final window in ['24h', '7d', '30d'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(window),
                      selected: _trendWindow == window,
                      onSelected: (_) => setState(() => _trendWindow = window),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _filterChips(),
        ],
      ),
    );
  }

  Widget _headerCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String hint,
    required Widget extra,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
              ),
              const Icon(Icons.insights_rounded),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear_rounded),
                    ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          extra,
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (_isTrending) _trendingHeader(),
        if (_isSports) _sportsHeader(),
        Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(widget.icon, size: 52),
              const SizedBox(height: 12),
              Text(
                'No ${widget.title} content yet.',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Create or publish content and it will appear here.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(widget.icon),
              const SizedBox(width: 8),
              Text(widget.title),
            ],
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final posts = _filteredPosts;
    final hasHeader = _isTrending || _isSports;

    if (posts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: RefreshIndicator(onRefresh: _load, child: _emptyState()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(widget.icon),
            const SizedBox(width: 8),
            Text(widget.title),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(12, hasHeader ? 0 : 12, 12, 28),
          itemCount: posts.length + (hasHeader ? 1 : 0),
          itemBuilder: (_, index) {
            if (index == 0 && _isTrending) return _trendingHeader();
            if (index == 0 && _isSports) return _sportsHeader();
            final post = posts[index - (hasHeader ? 1 : 0)];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PostCard(
                data: post,
                repository: _repository,
                onChanged: _load,
              ),
            );
          },
        ),
      ),
    );
  }
}
