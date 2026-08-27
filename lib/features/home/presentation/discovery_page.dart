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
  final _trendController = TextEditingController();
  List<HomeDemoData> _posts = [];
  bool _loading = true;
  String _trendWindow = '24h';
  String _category = 'All';

  bool get _isTrending => widget.title == 'Trending';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _trendController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      var posts = await _repository.fetchFeed();
      if (_isTrending) {
        posts.sort((a, b) => _trendScore(b).compareTo(_trendScore(a)));
      } else if (widget.title == 'Sports') {
        final sports = RegExp(r'sport|football|cricket|soccer|tennis|kabaddi|hockey|basketball');
        posts = posts.where((p) => '${p.text} ${p.creatorName}'.toLowerCase().contains(sports)).toList();
      }
      if (!mounted) return;
      setState(() {
        _posts = posts.map((p) => HomeDemoData(
          id: p.id,
          creatorName: p.creatorName,
          handle: p.handle,
          text: p.text,
          likes: p.likes,
          comments: p.comments,
          imagePath: p.imageUrl,
          mediaType: p.contentType,
          likedByMe: p.likedByMe,
          isRemote: true,
          ownerUserId: p.ownerUserId,
        )).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _trendScore(HomeDemoData post) => post.likes * 3 + post.comments * 2;

  List<HomeDemoData> get _filteredPosts {
    var result = List<HomeDemoData>.from(_posts);
    final query = _trendController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((p) => '${p.text} ${p.creatorName} ${p.handle}'.toLowerCase().contains(query)).toList();
    }
    if (_category == 'Videos') {
      result = result.where((p) => p.mediaType == 'video').toList();
    } else if (_category == 'Images') {
      result = result.where((p) => p.mediaType == 'image').toList();
    }
    if (_isTrending) {
      result.sort((a, b) => _trendScore(b).compareTo(_trendScore(a)));
    }
    return result;
  }

  Widget _trendingHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.local_fire_department_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(child: Text('Trending Now', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900))),
              const Icon(Icons.insights_rounded),
            ]),
            const SizedBox(height: 6),
            const Text('Discover rising MANOX topics and content. Search interest integration is designed for Google Trends API access when available.'),
            const SizedBox(height: 14),
            TextField(
              controller: _trendController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search a trend or topic…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _trendController.text.isEmpty
                    ? null
                    : IconButton(onPressed: () { _trendController.clear(); setState(() {}); }, icon: const Icon(Icons.clear_rounded)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final window in ['24h', '7d', '30d'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(window), selected: _trendWindow == window, onSelected: (_) => setState(() => _trendWindow = window)),
                  ),
                const SizedBox(width: 4),
                for (final category in ['All', 'Videos', 'Images'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(label: Text(category), selected: _category == category, onSelected: (_) => setState(() => _category = category)),
                  ),
              ]),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(children: [
          const Icon(Icons.trending_up_rounded, size: 19),
          const SizedBox(width: 6),
          Text('Rising on MANOX • $_trendWindow', style: const TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          Text('${_filteredPosts.length} results', style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    ],
  );

  Widget _empty() => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      if (_isTrending) _trendingHeader(),
      Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          Icon(widget.icon, size: 52),
          const SizedBox(height: 12),
          Text('No ${widget.title} content yet.', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Create or publish content and it will appear here.', textAlign: TextAlign.center),
        ]),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: Row(children: [Icon(widget.icon), const SizedBox(width: 8), Text(widget.title)])), body: const Center(child: CircularProgressIndicator()));
    }

    final posts = _filteredPosts;
    final content = posts.isEmpty
        ? _empty()
        : ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(12, _isTrending ? 0 : 12, 12, 28),
            itemCount: posts.length + (_isTrending ? 1 : 0),
            itemBuilder: (_, index) {
              if (_isTrending && index == 0) return _trendingHeader();
              final post = posts[_isTrending ? index - 1 : index];
              return Padding(padding: const EdgeInsets.only(bottom: 10), child: PostCard(data: post, repository: _repository, onChanged: _load));
            },
          );

    return Scaffold(
      appBar: AppBar(title: Row(children: [Icon(widget.icon), const SizedBox(width: 8), Text(widget.title)])),
      body: RefreshIndicator(onRefresh: _load, child: content),
    );
  }
}
