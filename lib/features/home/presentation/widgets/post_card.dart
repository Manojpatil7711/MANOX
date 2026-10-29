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
  final Map<String, Future<String?>> _mediaUrlFutures = <String, Future<String?>>{};

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
        // Keep the feed position stable; the local like count is already updated.
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
    final repository = widget.repository;
    if (repository == null || !widget.data.isRemote) {
      _showError('Comments will be available on live posts.');
      return;
    }

    final controller = TextEditingController();
    final comments = <ManoxComment>[];
    bool loading = true;
    bool sending = false;
    bool loadStarted = false;
    String? loadError;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        builder: (sheetContext) {
          final height = MediaQuery.of(sheetContext).size.height * 0.65;
          return StatefulBuilder(
            builder: (context, setSheetState) {
              if (!loadStarted) {
                loadStarted = true;
                Future<void>(() async {
                  try {
                    final result = await repository.fetchComments(widget.data.id);
                    if (!sheetContext.mounted) return;
                    setSheetState(() {
                      comments
                        ..clear()
                        ..addAll(result);
                      loading = false;
                      loadError = null;
                    });
                  } catch (_) {
                    if (!sheetContext.mounted) return;
                    setSheetState(() {
                      loading = false;
                      loadError = 'Unable to load comments. Tap retry to try again.';
                    });
                  }
                });
              }

              Future<void> sendComment() async {
                final body = controller.text.trim();
                if (body.isEmpty || sending) return;
                if (body.length > 1000) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(content: Text('Comment must be 1000 characters or fewer.')),
                  );
                  return;
                }
                setSheetState(() => sending = true);
                try {
                  await repository.addComment(widget.data.id, body);
                  if (!sheetContext.mounted) return;
                  controller.clear();
                  setSheetState(() {
                    comments.add(ManoxComment(
                      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
                      userName: 'You',
                      body: body,
                      createdAt: DateTime.now(),
                    ));
                    sending = false;
                    loadError = null;
                  });
                  if (mounted) setState(() => _comments = (_comments + 1).clamp(0, 1 << 30));
                } catch (error) {
                  if (!sheetContext.mounted) return;
                  setSheetState(() => sending = false);
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(content: Text('Comment could not be sent: ${error.toString().replaceFirst('Exception: ', '')}')),
                  );
                }
              }

              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
                child: SizedBox(
                  height: height,
                  child: Column(children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Text('Comments', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                    ),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : loadError != null && comments.isEmpty
                              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Text(loadError!, textAlign: TextAlign.center),
                                  const SizedBox(height: 8),
                                  FilledButton.tonal(
                                    onPressed: () {
                                      setSheetState(() { loading = true; loadError = null; loadStarted = false; });
                                    },
                                    child: const Text('RETRY'),
                                  ),
                                ]))
                              : comments.isEmpty
                                  ? const Center(child: Text('No comments yet. Be the first!'))
                                  : ListView.separated(
                                      key: const PageStorageKey<String>('manox-comments-list'),
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
                                    ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            maxLength: 1000,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => sendComment(),
                            decoration: const InputDecoration(
                              hintText: 'Write a comment...',
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: 'Send comment',
                          onPressed: sending ? null : sendComment,
                          icon: sending
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send_rounded),
                        ),
                      ]),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
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
    final uri = Uri.tryParse(path);
    final isRemoteUrl = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    final future = _mediaUrlFutures.putIfAbsent(path, () {
      if (isRemoteUrl) return Future<String?>.value(path);
      final repository = widget.repository;
      if (repository == null) return Future<String?>.value(null);
      return repository.signedMediaUrl(path);
    });

    return FutureBuilder<String?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final resolvedUrl = snapshot.data;
        if (snapshot.hasError || resolvedUrl == null || resolvedUrl.isEmpty) {
          return const SizedBox(
            height: 180,
            child: Center(child: Icon(Icons.broken_image_outlined)),
          );
        }
        if (isManoxVideo(path)) {
          return ManoxMediaPreview(url: resolvedUrl, height: 300);
        }
        return Image.network(
          resolvedUrl,
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox(
            height: 180,
            child: Center(child: Icon(Icons.broken_image_outlined)),
          ),
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                ),
        );
      },
    );
  }


  Future<void> _reportContent() async {
    final r = widget.repository;
    if (r == null || !widget.data.isRemote) return;
    const reasons = ['spam', 'harassment', 'hate', 'sexual', 'violence', 'illegal', 'other'];
    final reason = await showDialog<String>(context: context, builder: (dialog) => SimpleDialog(
      title: const Text('Report content'),
      children: [for (final value in reasons) SimpleDialogOption(onPressed: () => Navigator.pop(dialog, value), child: Text(value[0].toUpperCase() + value.substring(1)))],
    ));
    if (reason == null) return;
    try { await r.reportContent(widget.data.id, reason); if (mounted) _showError('Report submitted.'); }
    catch (e) { if (mounted) _showError(e.toString()); }
  }

  Future<void> _blockCreator() async {
    final r = widget.repository;
    final id = widget.data.ownerUserId;
    if (r == null || id == null || id.isEmpty || _isOwner) return;
    final confirm = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
      title: const Text('Block this user?'),
      content: const Text('Their content should no longer appear in your experience.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('CANCEL')), FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('BLOCK'))],
    ));
    if (confirm != true) return;
    try { await r.blockUser(id); if (mounted) { _showError('User blocked.'); await widget.onChanged?.call(); } }
    catch (e) { if (mounted) _showError(e.toString()); }
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.data.imagePath;
    final theme = Theme.of(context);
    final creator = widget.data.creatorName.isEmpty ? 'MANOX Creator' : widget.data.creatorName;
    final initial = creator.substring(0, 1).toUpperCase();
    return RepaintBoundary(
      child: Card(
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
              if (value == 'report') await _reportContent();
              if (value == 'block') await _blockCreator();
              if (value == 'delete' && _isOwner) {
                final r = widget.repository;
                if (r == null) return;
                try { await r.deletePost(widget.data.id); await widget.onChanged?.call(); } catch (e) { if (mounted) _showError(e.toString()); }
              }
            }, itemBuilder: (_) => [PopupMenuItem(value: 'save', child: Text(_saved ? 'Unsave post' : 'Save post')), if (!_isOwner && widget.data.isRemote) const PopupMenuItem(value: 'report', child: Text('Report content')), if (!_isOwner && widget.data.isRemote) const PopupMenuItem(value: 'block', child: Text('Block user')), if (_isOwner) const PopupMenuItem(value: 'delete', child: Text('Delete'))]),
          ]),
        ),
        if (widget.data.text.isNotEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Text(widget.data.text, style: const TextStyle(fontSize: 14.5, height: 1.4))),
        if (imagePath != null && imagePath.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: widget.data.isRemote && widget.repository != null
                  ? FutureBuilder<String?>(
                      future: widget.repository!.signedMediaUrl(imagePath),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
                        }
                        final resolved = snapshot.data;
                        if (resolved == null || resolved.isEmpty) {
                          return const SizedBox(height: 180, child: Center(child: Icon(Icons.broken_image_outlined)));
                        }
                        return _buildMedia(resolved);
                      },
                    )
                  : _buildMedia(imagePath),
            ),
          ),
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
      ),
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
