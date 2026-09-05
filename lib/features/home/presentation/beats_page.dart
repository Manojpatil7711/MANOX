import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../data/demo_posts.dart';
import '../data/supabase_post_repository.dart';
import 'widgets/media_preview.dart';

class BeatsPage extends StatefulWidget {
  final bool kidsMode;
  const BeatsPage({super.key, this.kidsMode = false});

  @override
  State<BeatsPage> createState() => _BeatsPageState();
}

class _BeatsPageState extends State<BeatsPage> {
  final _repository = SupabasePostRepository();
  final _controller = PageController();
  List<HomeDemoData> _posts = [];
  bool _loading = true;
  int _activeIndex = 0;

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
      final remote = await _repository.fetchBeats(kidsMode: widget.kidsMode);
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
                  mediaType: post.contentType,
                  likedByMe: post.likedByMe,
                  savedByMe: post.savedByMe,
                  isRemote: true,
                  ownerUserId: post.ownerUserId,
                ))
            .toList();
        _activeIndex = 0;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openBeatUpload() async {
    final published = await context.push<bool>('/create?beat=true');
    if (published == true && mounted) {
      setState(() {
        _loading = true;
        _activeIndex = 0;
      });
      await _load();
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_posts.isEmpty)
            Center(
              child: Text(
                widget.kidsMode ? 'No Kids BEATS yet.' : 'No public BEATS yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            )
          else
            PageView.builder(
              controller: _controller,
              scrollDirection: Axis.vertical,
              physics: const PageScrollPhysics(),
              itemCount: _posts.length,
              onPageChanged: (index) {
                if (mounted) setState(() => _activeIndex = index);
              },
              itemBuilder: (context, index) => _BeatItem(
                key: ValueKey(_posts[index].id),
                post: _posts[index],
                repository: _repository,
                isActive: index == _activeIndex,
              ),
            ),
          Positioned(
            top: 8,
            left: 8,
            child: SafeArea(
              child: IconButton(
                tooltip: 'Close BEATS',
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            top: 18,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Text(
                  widget.kidsMode ? 'KIDS BEATS' : 'BEATS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
          if (!widget.kidsMode)
            Positioned(
              right: 14,
              top: 8,
              child: SafeArea(
                child: FilledButton.icon(
                  onPressed: _openBeatUpload,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Upload Beat'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BeatItem extends StatefulWidget {
  final HomeDemoData post;
  final SupabasePostRepository repository;
  final bool isActive;

  const _BeatItem({
    super.key,
    required this.post,
    required this.repository,
    required this.isActive,
  });

  @override
  State<_BeatItem> createState() => _BeatItemState();
}

class _BeatItemState extends State<_BeatItem> {
  String? _url;
  bool _loading = true;
  bool _liked = false;
  bool _saved = false;
  bool _following = false;
  int _likes = 0;
  int _comments = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.post.likedByMe;
    _likes = widget.post.likes;
    _comments = widget.post.comments;
    _saved = widget.post.savedByMe;
    _resolve();
    _resolveFollow();
  }

  Future<void> _resolve() async {
    final path = widget.post.imagePath;
    if (path == null || path.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final url = await widget.repository.signedMediaUrl(path);
      if (mounted) setState(() { _url = url; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolveFollow() async {
    final id = widget.post.ownerUserId;
    if (id == null || id.isEmpty) return;
    try {
      final following = await widget.repository.isFollowing(id);
      if (mounted) setState(() => _following = following);
    } catch (_) {}
  }

  void _openCreator() {
    final id = widget.post.ownerUserId;
    if (id != null && id.isNotEmpty) {
      context.push('/profile/${Uri.encodeComponent(id)}');
    }
  }

  Future<void> _toggleFollow() async {
    final id = widget.post.ownerUserId;
    if (id == null || id.isEmpty || _busy) return;
    final previous = _following;
    setState(() => _following = !previous);
    try {
      await widget.repository.toggleFollow(id, currentlyFollowing: previous);
    } catch (_) {
      if (mounted) setState(() => _following = previous);
    }
  }

  Future<void> _toggleLike() async {
    if (_busy) return;
    final previous = _liked;
    setState(() {
      _busy = true;
      _liked = !previous;
      _likes += previous ? -1 : 1;
    });
    try {
      await widget.repository.toggleLike(widget.post.id, previous);
    } catch (_) {
      if (mounted) setState(() { _liked = previous; _likes += previous ? 1 : -1; });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _commentsSheet() async {
    final comments = await widget.repository.fetchComments(widget.post.id);
    if (!mounted) return;
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Comments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: comments.isEmpty
                    ? const Center(child: Text('No comments yet.'))
                    : ListView(
                        children: comments.map((c) => ListTile(title: Text(c.userName), subtitle: Text(c.body))).toList(),
                      ),
              ),
              TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(hintText: 'Add a comment…'),
                onSubmitted: (_) async {
                  final body = controller.text.trim();
                  if (body.isEmpty) return;
                  try {
                    await widget.repository.addComment(widget.post.id, body);
                    controller.clear();
                    if (mounted) setState(() => _comments += 1);
                  } catch (_) {}
                },
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _toggleSave() async {
    try {
      if (_saved) {
        await widget.repository.unsaveContent(widget.post.id);
      } else {
        await widget.repository.saveContent(widget.post.id);
      }
      if (mounted) setState(() => _saved = !_saved);
    } catch (_) {}
  }

  Future<void> _share() async {
    try {
      final url = await widget.repository.createShareUrl(widget.post.id);
      await widget.repository.recordShare(widget.post.id);
      if (mounted) {
        await SharePlus.instance.share(
          ShareParams(text: '${widget.post.text}\n$url', subject: 'Check out this BEAT on MANOX'),
        );
      }
    } catch (_) {}
  }

  Future<void> _moreActions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report BEAT'),
              subtitle: const Text('Report content that violates MANOX rules.'),
              onTap: () => Navigator.pop(sheetContext, 'report'),
            ),
            if (widget.post.ownerUserId != null)
              ListTile(
                leading: const Icon(Icons.person_off_outlined),
                title: const Text('Block creator'),
                subtitle: const Text('Hide this creator from your experience.'),
                onTap: () => Navigator.pop(sheetContext, 'block'),
              ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Not interested'),
              subtitle: const Text('Show fewer BEATS like this.'),
              onTap: () => Navigator.pop(sheetContext, 'not_interested'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'report') {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Report BEAT'),
          content: const Text('Use Community Safety to submit and manage content reports. The report is kept separate from creator analytics.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CLOSE')),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.push('/community-safety');
              },
              child: const Text('OPEN SAFETY'),
            ),
          ],
        ),
      );
    } else if (action == 'not_interested') {
      final page = context.findAncestorStateOfType<_BeatsPageState>();
      if (page != null && page.mounted) {
        page.setState(() {
          page._posts.removeWhere((p) => p.id == widget.post.id);
          page._activeIndex = page._posts.isEmpty ? 0 : page._activeIndex.clamp(0, page._posts.length - 1);
        });
      }
    } else if (action == 'block') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Creator blocking is available from the public profile safety controls.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_loading)
          const Center(child: CircularProgressIndicator(color: Colors.white))
        else if (_url != null && isManoxVideo(widget.post.imagePath ?? ''))
          ManoxMediaPreview(
            key: ValueKey('${widget.post.id}-${widget.isActive}'),
            url: _url!,
            height: double.infinity,
            fit: BoxFit.cover,
            autoPlay: widget.isActive,
            loop: true,
            fullScreenStyle: true,
          )
        else
          const _BeatFallback(),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [.55, 1],
              ),
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
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _openCreator,
                      child: Text(
                        widget.post.handle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  if (widget.post.ownerUserId != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: OutlinedButton(
                        onPressed: _toggleFollow,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Text(_following ? 'Following' : 'Follow'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.post.text,
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
              _BeatAction(icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, value: '$_likes', onTap: _toggleLike, semanticLabel: _liked ? 'Unlike' : 'Like'),
              const SizedBox(height: 16),
              _BeatAction(icon: _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, value: _saved ? 'Saved' : 'Save', onTap: _toggleSave, semanticLabel: _saved ? 'Unsave' : 'Save'),
              const SizedBox(height: 16),
              _BeatAction(icon: Icons.mode_comment_outlined, value: '$_comments', onTap: _commentsSheet, semanticLabel: 'Comments'),
              const SizedBox(height: 16),
              _BeatAction(icon: Icons.share_outlined, value: 'Share', onTap: _share, semanticLabel: 'Share'),
              const SizedBox(height: 16),
              _BeatAction(icon: Icons.currency_rupee_rounded, value: '₹ 🔒', onTap: () => context.push('/monetization'), semanticLabel: 'Monetization'),
              const SizedBox(height: 16),
              _BeatAction(icon: Icons.more_horiz_rounded, value: 'More', onTap: _moreActions, semanticLabel: 'More actions'),
            ],
          ),
        ),
      ],
    );
  }
}

class _BeatAction extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final String semanticLabel;

  const _BeatAction({required this.icon, required this.value, required this.onTap, required this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(23)),
            child: IconButton(
              tooltip: semanticLabel,
              padding: EdgeInsets.zero,
              onPressed: onTap,
              icon: Icon(icon, color: Colors.white),
            ),
          ),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _BeatFallback extends StatelessWidget {
  const _BeatFallback();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF111111),
        alignment: Alignment.center,
        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white54, size: 72),
      );
}
