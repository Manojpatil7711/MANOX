import 'package:flutter/material.dart';
import '../data/demo_posts.dart';
import '../data/supabase_post_repository.dart';
import 'widgets/post_card.dart';

class DiscoveryPage extends StatefulWidget {
  final String title;
  final IconData icon;
  const DiscoveryPage({super.key, required this.title, required this.icon});
  @override State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  final _repository = SupabasePostRepository();
  List<HomeDemoData> _posts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      var posts = await _repository.fetchFeed();
      if (widget.title == 'Trending') {
        posts.sort((a, b) => b.likes.compareTo(a.likes));
      } else if (widget.title == 'Sports') {
        final sports = RegExp(r'sport|football|cricket|soccer|tennis|kabaddi|hockey|basketball');
        posts = posts.where((p) => '${p.text} ${p.creatorName}'.toLowerCase().contains(sports)).toList();
      }
      if (!mounted) return;
      setState(() {
        _posts = posts.map((p) => HomeDemoData(id: p.id, creatorName: p.creatorName, handle: p.handle, text: p.text, likes: p.likes, comments: p.comments, imagePath: p.imageUrl, mediaType: p.contentType, likedByMe: p.likedByMe, isRemote: true, ownerUserId: p.ownerUserId)).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _empty() => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
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
    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_posts.isEmpty) {
      content = _empty();
    } else {
      content = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        itemCount: _posts.length,
        itemBuilder: (_, i) => Padding(padding: const EdgeInsets.only(bottom: 10), child: PostCard(data: _posts[i], repository: _repository, onChanged: _load)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Row(children: [Icon(widget.icon), const SizedBox(width: 8), Text(widget.title)])),
      body: RefreshIndicator(onRefresh: _load, child: content),
    );
  }
}
