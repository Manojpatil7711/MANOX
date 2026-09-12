import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/demo_posts.dart';
import '../../data/supabase_post_repository.dart';
import 'media_preview.dart';

class PostCard extends StatefulWidget {
  final HomeDemoData data;
  final SupabasePostRepository? repository;
  final Future<void> Function()? onChanged;
  const PostCard({super.key, required this.data, this.repository, this.onChanged});
  @override State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _liked;
  late int _likes;
  late int _comments;
  bool _busy = false;
  bool _isOwner = false;
  bool _vibed = false;
  bool _saved = false;
  bool _saveBusy = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.data.likedByMe;
    _likes = widget.data.likes;
    _comments = widget.data.comments;
    _checkOwner();
    _checkSaved();
  }

  Future<void> _checkOwner() async {
    final r = widget.repository;
    if (r == null || !widget.data.isRemote) return;
    try {
      final value = await r.isOwner(widget.data.id);
      if (mounted) setState(() => _isOwner = value);
    } catch (_) {}
  }

  Future<void> _checkSaved() async {
    final r = widget.repository;
    if (r == null || !widget.data.isRemote) return;
    try {
      final value = await r.isSaved(widget.data.id);
      if (mounted) setState(() => _saved = value);
    } catch (_) {}
  }

  void _openCreator() {
    final id = widget.data.ownerUserId;
    if (id == null || id.trim().isEmpty) return;
    context.push('/profile/${Uri.encodeComponent(id)}');
  }

  void _toggleVibe() {
    if (_isOwner) return;
    setState(() => _vibed = !_vibed);
  }

  Future<void> _toggleSave() async {
    if (_saveBusy) return;
    final r = widget.repository;
    if (r == null || !widget.data.isRemote) {
      setState(() => _saved = !_saved);
      return;
    }
    setState(() => _saveBusy = true);
    try {
      if (_saved) {
        await r.unsaveContent(widget.data.id);
      } else {
        await r.saveContent(widget.data.id);
      }
      if (mounted) setState(() => _saved = !_saved);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _saveBusy = false);
    }
  }

  Future<void> _toggleLike() async {
    if (_busy) return;
    final r = widget.repository;
    if (r == null || !widget.data.isRemote) {
      setState(() {
        _liked = !_liked;
        _likes = (_likes + (_liked ? 1 : -1)).clamp(0, 1 << 30);
      });
      return;
    }
    setState(() => _busy = true);
    try {
      final wasLiked = _liked;
      await r.toggleLike(widget.data.id, wasLiked);
      if (mounted) {
        setState(() {
          _liked = !wasLiked;
          _likes = (_likes + (_liked ? 1 : -1)).clamp(0, 1 << 30);
        });
        await widget.onChanged?.call();
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showComments() async {
    if (!widget.data.allowComments) {
      _showError('Comments are disabled for this post.');
      return;
    }
    final r = widget.repository;
    if (r == null || !widget.data.isRemote) {
      _showError('Comments will be available on live posts.');
      return;
    }
    final controller = TextEditingController();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) {
          final height = MediaQuery.of(sheetContext).size.height * 0.65;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: SizedBox(
              height: height,
              child: Column(children: [
                const Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 12), child: Text('Comments', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
                Expanded(child: FutureBuilder<List<ManoxComment>>(
                  future: r.fetchComments(widget.data.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError) return const Center(child: Text('Unable to load comments.'));
                    final comments = snapshot.data ?? const <ManoxComment>[];
                    if (comments.isEmpty) return const Center(child: Text('No comments yet. Be the first!'));
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: comments.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, index) {
                        final comment = comments[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(comment.body),
                        );
                      },
                    );
                  },
                )),
                Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: Row(children: [
                  Expanded(child: TextField(controller: controller, textInputAction: TextInputAction.send, onSubmitted: (_) => _sendComment(controller, r), decoration: const InputDecoration(hintText: 'Write a comment...'))),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: () => _sendComment(controller, r), icon: const Icon(Icons.send_rounded)),
                ])),
              ]),
            ),
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _sendComment(TextEditingController controller, SupabasePostRepository repository) async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    try {
      await repository.addComment(widget.data.id, text);
      controller.clear();
      if (mounted) {
        setState(() => _comments += 1);
        await widget.onChanged?.call();
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _share() async {
    final r = widget.repository;
    if (r == null || !widget.data.isRemote) {
      await SharePlus.instance.share(ShareParams(text: widget.data.text.isEmpty ? 'Check out this MANOX post.' : widget.data.text));
      return;
    }
    try {
      final url = await r.createShareUrl(widget.data.id);
      await SharePlus.instance.share(ShareParams(text: '${widget.data.text}\n$url'));
      await r.recordShare(widget.data.id);
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  Widget _buildMedia(String path) {
    if (isManoxVideo(path)) return ManoxMediaPreview(url: path, height: 300);
    final uri = Uri.tryParse(path);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Image.network(path, width: double.infinity, height: 300, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(height: 180, child: Center(child: Icon(Icons.broken_image_outlined))),
        loadingBuilder: (context, child, progress) => progress == null ? child : const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
      );
    }
    return const SizedBox(height: 180, child: Center(child: Icon(Icons.image_not_supported_outlined)));
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.data.imagePath;
    final theme = Theme.of(context);
    final creator = widget.data.creatorName.isEmpty ? 'MANOX Creator' : widget.data.creatorName;
    final initial = creator.substring(0, 1).toUpperCase();
    return Card(
      margin: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
          child: Row(children: [
            InkWell(onTap: _openCreator, borderRadius: BorderRadius.circular(24), child: CircleAvatar(radius: 22, backgroundColor: theme.colorScheme.primaryContainer, child: Text(initial, style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w900)))),
            const SizedBox(width: 11),
            Expanded(child: InkWell(onTap: _openCreator, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(creator, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 2),
              Text(widget.data.handle, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
            ]))),
            IconButton(tooltip: _saved ? 'Unsave' : 'Save', onPressed: _saveBusy ? null : _toggleSave, icon: Icon(_saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded)),
            PopupMenuButton<String>(onSelected: (value) async {
              if (value == 'save') await _toggleSave();
              if (value == 'delete' && _isOwner) {
                final r = widget.repository;
                if (r == null) return;
                try { await r.deletePost(widget.data.id); await widget.onChanged?.call(); } catch (e) { if (mounted) _showError(e.toString()); }
              }
            }, itemBuilder: (_) => [PopupMenuItem(value: 'save', child: Text(_saved ? 'Unsave post' : 'Save post')), if (_isOwner) const PopupMenuItem(value: 'delete', child: Text('Delete'))]),
          ]),
        ),
        if (widget.data.text.isNotEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Text(widget.data.text, style: const TextStyle(fontSize: 14.5, height: 1.4))),
        if (imagePath != null && imagePath.isNotEmpty)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: ClipRRect(borderRadius: BorderRadius.circular(15), child: _buildMedia(imagePath))),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
          child: Row(children: [
            _ActionButton(icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, label: '$_likes', active: _liked, onTap: _busy ? null : _toggleLike),
            _ActionButton(icon: widget.data.allowComments ? Icons.comment_outlined : Icons.comments_disabled_outlined, label: '$_comments', onTap: widget.data.allowComments ? _showComments : null),
            _ActionButton(icon: _vibed ? Icons.bolt_rounded : Icons.bolt_outlined, label: 'Vibe', active: _vibed, onTap: _toggleVibe),
            const Spacer(),
            _ActionButton(icon: Icons.ios_share_rounded, label: 'Share', onTap: _share),
          ]),
        ),
      ]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    final color = active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8), minimumSize: const Size(0, 40)),
        icon: Icon(icon, size: 20, color: color),
        label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }
}
