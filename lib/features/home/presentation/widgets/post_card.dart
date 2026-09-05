import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/models/demo_posts.dart';
import '../../data/supabase_post_repository.dart';
import 'media_preview.dart';

class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.data, this.onChanged});
  final DemoPost data;
  final VoidCallback? onChanged;
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _liked = false, _busy = false, _isOwner = false, _vibed = false, _saved = false, _saveBusy = false;
  int _likes = 0, _comments = 0;

  @override
  void initState() {
    super.initState();
    _likes = widget.data.likes;
    _comments = widget.data.comments;
    _checkOwner();
    _checkSaved();
  }

  Future<void> _checkOwner() async {
    final owner = await SupabasePostRepository().isOwner(widget.data.ownerId);
    if (mounted) setState(() => _isOwner = owner);
  }

  Future<void> _checkSaved() async {
    final saved = await SupabasePostRepository().isSaved(widget.data.id);
    if (mounted) setState(() => _saved = saved);
  }

  void _openCreator() {
    if (widget.data.ownerId.isNotEmpty) context.push('/profile/${widget.data.ownerId}');
  }

  void _toggleVibe() => setState(() => _vibed = !_vibed);

  Future<void> _toggleSave() async {
    if (_saveBusy) return;
    setState(() => _saveBusy = true);
    try {
      final r = SupabasePostRepository();
      if (_saved) {
        await r.unsaveContent(widget.data.id);
      } else {
        await r.saveContent(widget.data.id);
      }
      if (mounted) {
        setState(() => _saved = !_saved);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_saved ? 'Saved to your collection.' : 'Removed from saved.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update saved post: $e')));
    } finally {
      if (mounted) setState(() => _saveBusy = false);
    }
  }

  Future<void> _toggleLike() async {
    if (_busy) return;
    setState(() {
      _liked = !_liked;
      _likes = (_likes + (_liked ? 1 : -1)).clamp(0, 1 << 30).toInt();
    });
    try {
      await SupabasePostRepository().toggleLike(widget.data.id, _liked);
    } catch (e) {
      if (mounted) {
        setState(() {
          _liked = !_liked;
          _likes = (_likes + (_liked ? 1 : -1)).clamp(0, 1 << 30).toInt();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update like: $e')));
      }
    }
  }

  Future<void> _openComments() async {
    final controller = TextEditingController();
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20),
        child: Row(children: [
          Expanded(child: TextField(controller: controller, autofocus: true, maxLength: 500, decoration: const InputDecoration(hintText: 'Add a comment…', border: OutlineInputBorder()))),
          const SizedBox(width: 10),
          IconButton(tooltip: 'Post comment', onPressed: () => Navigator.of(sheetContext).pop(controller.text.trim()), icon: const Icon(Icons.send_rounded)),
        ]),
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty) return;
    try {
      await SupabasePostRepository().addComment(widget.data.id, text);
      if (mounted) {
        setState(() => _comments++);
        widget.onChanged?.call();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not post comment: $e')));
    }
  }

  Future<void> _reportContent() async {
    const reasons = <String, String>{
      'spam': 'Spam or scam', 'harassment': 'Harassment or bullying', 'sexual': 'Nudity or sexual content',
      'violence': 'Violence or dangerous content', 'hate': 'Hate or abusive content',
      'misinformation': 'False or misleading information', 'other': 'Something else',
    };
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report post'),
        content: SizedBox(width: 420, child: ListView(shrinkWrap: true, children: reasons.entries.map((entry) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.flag_outlined),
          title: Text(entry.value),
          onTap: () => Navigator.of(dialogContext).pop(entry.key),
        )).toList())),
      ),
    );
    if (reason == null) return;
    try {
      await SupabasePostRepository().reportContent(widget.data.id, reasonCode: reason);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks. The post was reported to MANOX Safety.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not send report: $e')));
    }
  }

  Future<void> _blockCreator() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Block creator?'),
        content: const Text('You will no longer see this creator’s content. You can manage blocks from Community Safety.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Block')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabasePostRepository().blockUser(widget.data.ownerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Creator blocked.')));
        widget.onChanged?.call();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not block creator: $e')));
    }
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This permanently removes the post from MANOX.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabasePostRepository().deletePost(widget.data.id);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete post: $e')));
    }
  }

  Future<void> _openMore() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: Icon(_saved ? Icons.bookmark_remove_outlined : Icons.bookmark_add_outlined), title: Text(_saved ? 'Remove from saved' : 'Save post'), onTap: () { Navigator.of(sheetContext).pop(); _toggleSave(); }),
        if (!_isOwner) ListTile(leading: const Icon(Icons.flag_outlined), title: const Text('Report post'), onTap: () { Navigator.of(sheetContext).pop(); _reportContent(); }),
        if (!_isOwner) ListTile(leading: const Icon(Icons.person_off_outlined), title: const Text('Block creator'), onTap: () { Navigator.of(sheetContext).pop(); _blockCreator(); }),
        if (_isOwner) ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Delete post'), onTap: () { Navigator.of(sheetContext).pop(); _deletePost(); }),
      ])),
    );
  }

  Future<void> _share() async {
    try {
      final r = SupabasePostRepository();
      final url = await r.createShareUrl(widget.data.id);
      await Share.share(url ?? 'Check this post on MANOX.');
      await r.recordShare(widget.data.id);
    } catch (_) {
      await Share.share('Check this post on MANOX.');
    }
  }

  Widget _buildMedia() {
    final urls = widget.data.mediaUrls;
    if (urls.isNotEmpty) return MediaPreview(urls: urls, fit: BoxFit.cover, aspectRatio: 1);
    return Container(color: Theme.of(context).colorScheme.surfaceContainerHighest, alignment: Alignment.center, child: const Icon(Icons.image_not_supported_outlined, size: 42));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(clipBehavior: Clip.antiAlias, margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ListTile(
        leading: CircleAvatar(backgroundImage: widget.data.ownerAvatarUrl == null ? null : NetworkImage(widget.data.ownerAvatarUrl!), child: widget.data.ownerAvatarUrl == null ? const Icon(Icons.person_outline) : null),
        title: Text(widget.data.ownerName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('@${widget.data.ownerUsername}'),
        onTap: _openCreator,
        trailing: IconButton(tooltip: 'More actions', onPressed: _openMore, icon: const Icon(Icons.more_horiz_rounded)),
      ),
      _buildMedia(),
      Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton(tooltip: _liked ? 'Unlike' : 'Like', onPressed: _toggleLike, icon: Icon(_liked ? Icons.favorite : Icons.favorite_border)), Text('$_likes'),
          const SizedBox(width: 8),
          IconButton(tooltip: 'Comments', onPressed: _openComments, icon: const Icon(Icons.chat_bubble_outline)), Text('$_comments'),
          const SizedBox(width: 8),
          IconButton(tooltip: 'Share', onPressed: _share, icon: const Icon(Icons.share_outlined)),
          const Spacer(),
          IconButton(tooltip: _vibed ? 'Remove vibe' : 'Vibe', onPressed: _toggleVibe, icon: Icon(_vibed ? Icons.bolt : Icons.bolt_outlined)),
        ]),
        if (widget.data.description.isNotEmpty) Text(widget.data.description, maxLines: 4, overflow: TextOverflow.ellipsis),
        if (widget.data.isMonetizable) Padding(padding: const EdgeInsets.only(top: 8), child: Text('₹  Earn from engagement', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700))),
      ])),
    ]));
  }
}
