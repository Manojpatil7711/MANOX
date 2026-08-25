import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/demo_posts.dart';
import '../data/supabase_post_repository.dart';

class BeatsPage extends StatefulWidget {
  const BeatsPage({super.key});

  @override
  State<BeatsPage> createState() => _BeatsPageState();
}

class _BeatsPageState extends State<BeatsPage> {
  final _repository = SupabasePostRepository();
  final _controller = PageController();
  List<HomeDemoData> _posts = [];
  bool _loading = true;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
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
        )).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _next() {
    if (_index + 1 < _posts.length) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_posts.isEmpty)
              const Center(
                child: Text(
                  'No BEATS yet.\nCreate the first one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
            else
              PageView.builder(
                controller: _controller,
                scrollDirection: Axis.vertical,
                itemCount: _posts.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) => _BeatItem(
                  post: _posts[index],
                  onNext: _next,
                ),
              ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                tooltip: 'Back',
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            const Positioned(
              top: 18,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'BEATS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeatItem extends StatelessWidget {
  final HomeDemoData post;
  final VoidCallback onNext;

  const _BeatItem({required this.post, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final image = post.imagePath;

    return GestureDetector(
      onDoubleTap: onNext,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image != null && image.isNotEmpty)
            Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _BeatFallback(),
            )
          else
            const _BeatFallback(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [0.55, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 78,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: Text(
                    '@${post.handle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            bottom: 26,
            child: Column(
              children: [
                _BeatAction(icon: Icons.favorite_border_rounded, value: '${post.likes}'),
                const SizedBox(height: 18),
                _BeatAction(icon: Icons.mode_comment_outlined, value: '${post.comments}'),
                const SizedBox(height: 18),
                const _BeatAction(icon: Icons.bookmark_border_rounded, value: 'Save'),
                const SizedBox(height: 18),
                const _BeatAction(icon: Icons.share_outlined, value: 'Share'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BeatAction extends StatelessWidget {
  final IconData icon;
  final String value;
  const _BeatAction({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(22),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {},
            icon: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }
}

class _BeatFallback extends StatelessWidget {
  const _BeatFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      alignment: Alignment.center,
      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white54, size: 72),
    );
  }
}
