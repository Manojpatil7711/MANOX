import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/demo_posts.dart';
import '../../data/supabase_post_repository.dart';

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

  @override
  void initState() {
    super.initState();
    _liked = widget.data.likedByMe;
    _likes = widget.data.likes;
    _comments = widget.data.comments;
    _checkOwner();
  }

  Future<void> _checkOwner() async {
    final repo = widget.repository;
    if (repo == null || !widget.data.isRemote) return;
    try {
      final owner = await repo.isOwner(widget.data.id);
      if (mounted) setState(() => _isOwner = owner);
    } catch (_) {}
  }

  void _toggleVibe() {
    if (_isOwner) return;
    setState(() => _vibed = !_vibed);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_vibed ? 'VIBE added.' : 'VIBE removed.')));
  }

  Future<void> _toggleLike() async {
    if (_busy) return;
    final repo = widget.repository;
    if (repo == null || !widget.data.isRemote) {
      setState(() { _liked = !_liked; _likes += _liked ? 1 : -1; });
      return;
    }
    setState(() => _busy = true);
    try {
      final liked = await repo.toggleLike(widget.data.id, _liked);
      if (!mounted) return;
      setState(() { _liked = liked; _likes += liked ? 1 : -1; });
    } catch (e) { if (mounted) _showError(e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _showComments() async {
    final repo = widget.repository;
    if (repo == null || !widget.data.isRemote) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comments will be available on live posts.')));
      return;
    }
    final controller = TextEditingController();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .65,
            child: Column(children: [
              const Padding(padding: EdgeInsets.all(16), child: Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              Expanded(child: FutureBuilder<List<ManoxComment>>(
                future: repo.fetchComments(widget.data.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return const Center(child: Text('Unable to load comments.'));
                  final comments = snapshot.data ?? const <ManoxComment>[];
                  if (comments.isEmpty) return const Center(child: Text('No comments yet. Be the first!'));
                  return ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: comments.length, separatorBuilder: (_, __) => const Divider(), itemBuilder: (_, i) { final c = comments[i]; return ListTile(contentPadding: EdgeInsets.zero, title: Text(c.userName, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(c.body)); });
                },
              )),
              Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: Row(children: [Expanded(child: TextField(controller: controller, textInputAction: TextInputAction.send, decoration: const InputDecoration(hintText: 'Write a comment...'), onSubmitted: (_) => _sendComment(controller, repo))), IconButton(icon: const Icon(Icons.send), onPressed: () => _sendComment(controller, repo))])),
            ]),
          ),
        ),
      );
    } finally { controller.dispose(); }
  }

  Future<void> _sendComment(TextEditingController controller, SupabasePostRepository repo) async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    try { await repo.addComment(widget.data.id, text); controller.clear(); if (mounted) setState(() => _comments++); }
    catch (e) { if (mounted) _showError(e.toString()); }
  }

  Future<void> _share() async {
    final repo = widget.repository;
    final url = repo == null || !widget.data.isRemote ? 'https://manox.app' : await repo.createShareUrl(widget.data.id);
    if (repo != null && widget.data.isRemote) { try { await repo.recordShare(widget.data.id); } catch (_) {} }
    await SharePlus.instance.share(ShareParams(text: '${widget.data.text}\n\n$url', title: 'Share on MANOX'));
  }

  Future<void> _showPostMenu() async {
    if (!_isOwner) return;
    final choice = await showModalBottomSheet<String>(context: context, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Edit post'), onTap: () => Navigator.pop(context, 'edit')), ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Delete post'), onTap: () => Navigator.pop(context, 'delete'))])));
    if (choice == 'edit') await _editPost();
    if (choice == 'delete') await _deletePost();
  }

  Future<void> _editPost() async {
    final repo = widget.repository;
    if (repo == null) return;
    final controller = TextEditingController(text: widget.data.text);
    final save = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Edit post'), content: TextField(controller: controller, maxLines: 6, autofocus: true), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save'))]));
    if (save != true || controller.text.trim().isEmpty) { controller.dispose(); return; }
    try { await repo.updatePost(widget.data.id, controller.text); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post updated.'))); await widget.onChanged?.call(); } }
    catch (e) { if (mounted) _showError(e.toString()); }
    controller.dispose();
  }

  Future<void> _deletePost() async {
    final repo = widget.repository;
    if (repo == null) return;
    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Delete post?'), content: const Text('This post will be permanently removed.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))]));
    if (confirm != true) return;
    try { await repo.deletePost(widget.data.id); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted.'))); await widget.onChanged?.call(); } }
    catch (e) { if (mounted) _showError(e.toString()); }
  }

  void _showMonetizationLock() { showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('Monetization locked'), content: const Text('This earning feature unlocks after the required subscription or MANOX monetization eligibility level is reached.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))])); }
  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message.replaceFirst('Exception: ', ''))));

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Card(
      key: Key('post-card-${data.id}'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data.creatorName, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(data.handle, style: Theme.of(context).textTheme.bodySmall),
            ])),
            if (!_isOwner) FilledButton.icon(key: Key('post-vibe-${data.id}'), onPressed: _toggleVibe, icon: Icon(_vibed ? Icons.auto_awesome : Icons.auto_awesome_outlined, size: 16), label: const Text('VIBE')),
            if (_isOwner) IconButton(icon: const Icon(Icons.more_vert), onPressed: _showPostMenu, tooltip: 'More'),
          ]),
          const SizedBox(height: 8),
          Text(data.text),
          if (data.imagePath != null) ...[
            const SizedBox(height: 12),
            FutureBuilder<String?>(future: widget.repository?.signedMediaUrl(data.imagePath!), builder: (context, snapshot) { if (!snapshot.hasData) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())); return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(snapshot.data!, width: double.infinity, height: 240, fit: BoxFit.cover)); }),
          ],
          const SizedBox(height: 12),
          Row(children: [
            IconButton(key: Key('post-like-${data.id}'), onPressed: _busy ? null : _toggleLike, icon: Icon(_liked ? Icons.favorite : Icons.favorite_border), tooltip: 'Like'), Text('$_likes'), const SizedBox(width: 8),
            IconButton(key: Key('post-comment-${data.id}'), onPressed: _showComments, icon: const Icon(Icons.comment_outlined), tooltip: 'Comment'), Text('$_comments'), const SizedBox(width: 8),
            IconButton(key: Key('post-monetize-${data.id}'), onPressed: _showMonetizationLock, icon: const Icon(Icons.currency_rupee), tooltip: 'Earnings'), const Icon(Icons.lock_outline, size: 17), const Spacer(),
            IconButton(key: Key('post-share-${data.id}'), onPressed: _share, icon: const Icon(Icons.share_outlined), tooltip: 'Share'),
          ]),
        ]),
      ),
    );
  }
}
