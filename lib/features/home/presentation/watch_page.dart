import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../data/demo_posts.dart';
import '../data/supabase_post_repository.dart';
import 'widgets/media_preview.dart';

class WatchPage extends StatefulWidget {
  const WatchPage({super.key});
  @override State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  final _repo = SupabasePostRepository();
  final _controller = PageController();
  final Map<String, String> _urlCache = {};
  List<HomeDemoData> _posts = [];
  bool _loading = true;
  int _active = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final posts = await _repo.fetchLatestFeed(limit: 50);
      if (!mounted) return;
      final videos = posts.map((p) => HomeDemoData(
        id: p.id, creatorName: p.creatorName, handle: p.handle, text: p.text,
        likes: p.likes, comments: p.comments, imagePath: p.imageUrl, mediaType: p.contentType,
        likedByMe: p.likedByMe, savedByMe: p.savedByMe, isRemote: true, ownerUserId: p.ownerUserId,
      )).where((p) => isManoxVideo(p.imagePath ?? '')).toList();
      setState(() { _posts = videos; _loading = false; });
      await _primeAround(0);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _primeAround(int index) async {
    for (final i in <int>[index, index + 1, index - 1]) {
      if (i < 0 || i >= _posts.length) continue;
      final post = _posts[i];
      if (_urlCache.containsKey(post.id)) continue;
      final path = post.imagePath;
      if (path == null || path.isEmpty) continue;
      try {
        final url = await _repo.signedMediaUrl(path);
        if (mounted) setState(() => _urlCache[post.id] = url);
      } catch (_) {}
    }
  }

  void _pageChanged(int index) {
    setState(() => _active = index);
    _primeAround(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _posts.isEmpty
              ? const Center(child: Text('No videos yet.', style: TextStyle(color: Colors.white)))
              : PageView.builder(
                  controller: _controller,
                  scrollDirection: Axis.vertical,
                  physics: const PageScrollPhysics(),
                  itemCount: _posts.length,
                  onPageChanged: _pageChanged,
                  itemBuilder: (_, index) => _WatchItem(
                    key: ValueKey(_posts[index].id),
                    post: _posts[index],
                    repo: _repo,
                    active: index == _active,
                    initialUrl: _urlCache[_posts[index].id],
                  ),
                ),
    );
  }
}

class _WatchItem extends StatefulWidget {
  final HomeDemoData post;
  final SupabasePostRepository repo;
  final bool active;
  final String? initialUrl;

  const _WatchItem({super.key, required this.post, required this.repo, required this.active, this.initialUrl});
  @override State<_WatchItem> createState() => _WatchItemState();
}

class _WatchItemState extends State<_WatchItem> {
  String? _url;
  late bool _liked;
  late bool _saved;
  late int _likes;
  bool _busy = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.post.likedByMe;
    _saved = widget.post.savedByMe;
    _likes = widget.post.likes;
    _url = widget.initialUrl;
    if (_url == null) _resolve();
  }

  @override
  void didUpdateWidget(covariant _WatchItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active && !widget.active && mounted) setState(() => _playing = false);
    if (_url == null && widget.initialUrl != null) setState(() => _url = widget.initialUrl);
  }

  Future<void> _resolve() async {
    try {
      final path = widget.post.imagePath;
      if (path == null || path.isEmpty) return;
      final url = await widget.repo.signedMediaUrl(path);
      if (mounted) setState(() => _url = url);
    } catch (_) {}
  }

  void _profile() {
    final id = widget.post.ownerUserId;
    if (id != null && id.isNotEmpty) context.push('/profile/${Uri.encodeComponent(id)}');
  }

  Future<void> _like() async {
    if (_busy) return;
    final previous = _liked;
    setState(() { _busy = true; _liked = !previous; _likes += previous ? -1 : 1; });
    try {
      await widget.repo.toggleLike(widget.post.id, previous);
    } catch (_) {
      if (mounted) setState(() { _liked = previous; _likes += previous ? 1 : -1; });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    try {
      if (_saved) await widget.repo.unsaveContent(widget.post.id);
      else await widget.repo.saveContent(widget.post.id);
      if (mounted) setState(() => _saved = !_saved);
    } catch (_) {}
  }

  Future<void> _share() async {
    try {
      final url = await widget.repo.createShareUrl(widget.post.id);
      await widget.repo.recordShare(widget.post.id);
      await SharePlus.instance.share(ShareParams(text: '${widget.post.text}\n$url', subject: 'Watch on MANOX'));
    } catch (_) {}
  }

  String get _hook {
    final text = widget.post.text.trim();
    if (text.isEmpty) return 'Watch this';
    final first = text.split(RegExp(r'(?<=[.!?])\s+')).first.trim();
    return first.length > 64 ? '${first.substring(0, 61)}…' : first;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_url != null)
          ManoxMediaPreview(
            key: ValueKey('${widget.post.id}-$_url'),
            url: _url!,
            height: double.infinity,
            fit: BoxFit.cover,
            autoPlay: widget.active,
            loop: true,
            fullScreenStyle: true,
            showProgress: true,
            onPlaybackChanged: (playing) { if (mounted) setState(() => _playing = playing); },
          )
        else
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.black45, Colors.transparent, Colors.black87],
                stops: [0, .48, 1],
              ),
            ),
          ),
        ),
        Positioned(
          top: 18, left: 12,
          child: SafeArea(child: IconButton(
            tooltip: 'Close',
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          )),
        ),
        const Positioned(
          top: 28, left: 0, right: 0,
          child: Center(child: Text('WATCH', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2.4))),
        ),
        if (!_playing && _url != null)
          const IgnorePointer(
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: Padding(padding: EdgeInsets.all(14), child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36)),
              ),
            ),
          ),
        Positioned(
          left: 16, right: 78, bottom: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
                child: const Text('HOOK', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
              const SizedBox(height: 7),
              Text(_hook, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.05)),
              const SizedBox(height: 9),
              InkWell(onTap: _profile, child: Text(widget.post.handle, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800))),
              if (widget.post.text.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(widget.post.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.25)),
              ],
            ],
          ),
        ),
        Positioned(
          right: 12, bottom: 30,
          child: Column(
            children: [
              _Action(icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, text: _likes.toString(), onTap: _like),
              const SizedBox(height: 18),
              _Action(icon: _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, text: _saved ? 'Saved' : 'Save', onTap: _save),
              const SizedBox(height: 18),
              _Action(icon: Icons.share_rounded, text: 'Share', onTap: _share),
            ],
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Material(color: Colors.black45, shape: const CircleBorder(), child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: 46, height: 46, child: Icon(icon, color: Colors.white))),
      const SizedBox(height: 4),
      Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    ],
  );
}
