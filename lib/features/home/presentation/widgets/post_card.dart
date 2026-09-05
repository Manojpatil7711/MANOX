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
        builder: (sheetContext) {
          final height = MediaQuery.of(sheetContext).size.height * 0.65;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: SizedBox(
              height: height,
              child: Column(
                children: [
                  const Padding(padding: EdgeInsets.all(16), child: Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  Expanded(
                    child: FutureBuilder<List<ManoxComment>>(
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
                            return ListTile(title: Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(comment.body));
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(children: [
                      Expanded(child: TextField(controller: controller, textInputAction: TextInputAction.send, onSubmitted: (_) => _sendComment(controller, r), decoration: const InputDecoration(hintText: 'Write a comment...'))),
                      IconButton(onPressed: () => _sendComment(controller, r), icon: const Icon(Icons.send)),
                    ]),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _sendComment(TextEditingController controller, SupabasePostRepository repository) async {
    if (!widget.data.allowComments) {
      _showError('Comments are disabled for this post.');
      return;
    }
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

  Future<void> _reportContent() async {
    final r = widget.repository;
    if (r == null || !widget.data.isRemote) {
      _showError('Reporting is available on live MANOX content.');
      return;
    }
    const reasons = <String, String>{
      'spam': 'Spam or scam',
      'harassment': 'Harassment or bullying',
      'nudity': 'Nudity or sexual content',
      'violence': 'Violence or dangerous content',
      'hate': 'Hate or abusive content',
      'misinformation': 'False or misleading information',
      'other': 'Something else',
    };
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report post'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: reasons.entries.map((entry) => ListTile(dense: true, leading: const Icon(Icons.flag_outlined), title: Text(entry.value), onTap: () => Navigator.of(dialogContext).pop(entry.key))).toList())),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('CANCEL'))],
      ),
    );
    if (reason == null || !mounted) return;
    try {
      await r.reportContent(widget.data.id, reasonCode: reason);
      if (mounted) _showError('Thanks. The post was reported to MANOX Safety.');
    } catch (e) {
      if (mounted) _showError('Could not submit report: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _blockCreator() async {
    final r = widget.repository;
    final creatorId = widget.data.ownerUserId?.trim();
    if (r == null || creatorId == null || creatorId.isEmpty || _isOwner) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Block creator?'),
        content: Text('You will no longer see ${widget.data.creatorName} or their content in your MANOX experience.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('BLOCK')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await r.blockUser(creatorId);
      if (!mounted) return;
      _showError('${widget.data.creatorName} has been blocked.');
      await widget.onChanged?.call();
    } catch (e) {
      if (mounted) _showError('Could not block creator: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _openMore() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: Icon(_saved ? Icons.bookmark : Icons.bookmark_border), title: Text(_saved ? 'Remove from saved' : 'Save post'), onTap: () { Navigator.pop(sheetContext); _toggleSave(); }),
          if (!_isOwner) ListTile(leading: const Icon(Icons.flag_outlined), title: const Text('Report post'), onTap: () { Navigator.pop(sheetContext); _reportContent(); }),
          if (!_isOwner) ListTile(leading: const Icon(Icons.block_outlined), title: const Text('Block creator'), onTap: () { Navigator.pop(sheetContext); _blockCreator(); }),
          ListTile(leading: const Icon(Icons.not_interested_outlined), title: const Text('Not interested'), onTap: () { Navigator.pop(sheetContext); _showError('We will show you less like this.'); }),
          const SizedBox(height: 8),
        ]),
      ),
    );
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
    if (isManoxVideo(path)) return ManoxMediaPreview(url: path, height: 260);
    final uri = Uri.tryParse(path);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Image.network(path, width: double.infinity, height: 260, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 180, child: Center(child: Icon(Icons.broken_image_outlined))), loadingBuilder: (context, child, progress) => progress == null ? child : const SizedBox(height: 260, child: Center(child: CircularProgressIndicator())));
    }
    return const SizedBox(height: 180, child: Center(child: Icon(Icons.image_not_supported_outlined)));
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.data.imagePath;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ListTile(
          onTap: _openCreator,
          leading: CircleAvatar(child: Text(widget.data.creatorName.isEmpty ? 'M' : widget.data.creatorName[0].toUpperCase())),
          title: Text(widget.data.creatorName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(widget.data.handle),
          trailing: IconButton(tooltip: 'More post actions', onPressed: _openMore, icon: const Icon(Icons.more_horiz_rounded)),
        ),
        if (widget.data.text.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Text(widget.data.text)),
        if (imagePath != null && imagePath.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: _buildMedia(imagePath))),
        OverflowBar(children: [
          TextButton.icon(onPressed: _busy ? null : _toggleLike, icon: Icon(_liked ? Icons.favorite : Icons.favorite_border), label: Text('$_likes')),
          TextButton.icon(onPressed: widget.data.allowComments ? _showComments : null, icon: Icon(widget.data.allowComments ? Icons.comment_outlined : Icons.comments_disabled_outlined), label: Text('$_comments')),
          TextButton.icon(onPressed: _toggleVibe, icon: Icon(_vibed ? Icons.bolt : Icons.bolt_outlined), label: const Text('Vibe')),
          TextButton.icon(onPressed: _share, icon: const Icon(Icons.share_outlined), label: const Text('Share')),
        ]),
      ]),
    );
  }
}
