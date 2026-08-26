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

  @override
  State<PostCard> createState() => _PostCardState();
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
      final value = await r.toggleLike(widget.data.id, _liked);
      if (mounted) {
        setState(() {
          if (value != _liked) _likes += value ? 1 : -1;
          _liked = value;
        });
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showComments() async {
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
                    child: Row(
                      children: [
                        Expanded(child: TextField(controller: controller, textInputAction: TextInputAction.send, onSubmitted: (_) => _sendComment(controller, r), decoration: const InputDecoration(hintText: 'Write a comment...'))),
                        IconButton(onPressed: () => _sendComment(controller, r), icon: const Icon(Icons.send)),
                      ],
                    ),
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
    final text = controller.text.trim();
    if (text.isEmpty) return;
    try {
      await repository.addComment(widget.data.id, text);
      controller.clear();
      if (mounted) setState(() => _comments++);
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _share() async {
    final r = widget.repository;
    var url = 'https://manox.app';
    if (r != null && widget.data.isRemote) {
      try {
        url = await r.createShareUrl(widget.data.id);
        await r.recordShare(widget.data.id);
      } catch (_) {}
    }
    await SharePlus.instance.share(ShareParams(text: 'Open this MANOX content directly:\n$url\n\n${widget.data.text}', title: 'MANOX • ${widget.data.creatorName}'));
  }

  Future<String?> _mediaUrl() async {
    final path = widget.data.imagePath;
    if (path == null) return null;
    return widget.repository?.signedMediaUrl(path);
  }

  Future<void> _openVideoFullScreen() async {
    final path = widget.data.imagePath;
    if (path == null || !isManoxVideo(path)) return;
    final url = await _mediaUrl();
    if (!mounted || url == null || url.isEmpty) return;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (_, __, ___) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(child: ManoxMediaPreview(url: url, height: MediaQuery.sizeOf(context).height, fit: BoxFit.contain, autoPlay: true, fullScreenStyle: true)),
                Positioned(top: 8, left: 8, child: IconButton(onPressed: () => Navigator.pop(context), color: Colors.white, icon: const Icon(Icons.close, size: 30))),
              ],
            ),
          ),
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Widget _media(double height) {
    final path = widget.data.imagePath;
    if (path == null) return const SizedBox.shrink();
    return FutureBuilder<String?>(
      future: _mediaUrl(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox(height: height, child: const Center(child: CircularProgressIndicator()));
        final url = snapshot.data;
        if (url == null || url.isEmpty) return SizedBox(height: height, child: const Center(child: Icon(Icons.broken_image_outlined)));
        if (isManoxVideo(path)) return ManoxMediaPreview(url: url, height: height, fit: BoxFit.cover, onVideoTap: _openVideoFullScreen);
        return ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: double.infinity, height: height, child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined)))));
      },
    );
  }

  Future<void> _editPost() async {
    final r = widget.repository;
    if (r == null) return;
    final controller = TextEditingController(text: widget.data.text);
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit post'),
        content: TextField(controller: controller, maxLines: 6, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
        ],
      ),
    );
    final text = controller.text.trim();
    if (save != true || text.isEmpty) {
      controller.dispose();
      return;
    }
    try {
      await r.updatePost(widget.data.id, text);
      if (mounted) await widget.onChanged?.call();
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      controller.dispose();
    }
  }

  Future<void> _deletePost() async {
    final r = widget.repository;
    if (r == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This post will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await r.deletePost(widget.data.id);
      if (mounted) await widget.onChanged?.call();
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _showPostMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: Icon(_saved ? Icons.bookmark : Icons.bookmark_border), title: Text(_saved ? 'Remove from Saved' : 'Save'), onTap: () => Navigator.pop(sheetContext, 'save')),
            if (_isOwner) ...[
              ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Edit post'), onTap: () => Navigator.pop(sheetContext, 'edit')),
              ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Delete post'), onTap: () => Navigator.pop(sheetContext, 'delete')),
            ],
          ],
        ),
      ),
    );
    if (action == 'save') await _toggleSave();
    if (action == 'edit') await _editPost();
    if (action == 'delete') await _deletePost();
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message.replaceFirst('Exception: ', ''))));

  Widget _creatorHeader() {
    return InkWell(
      onTap: _openCreator,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const CircleAvatar(radius: 22, child: Icon(Icons.person)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.data.creatorName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(widget.data.handle.replaceFirst(RegExp(r'^@+'), '@'), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (!_isOwner)
              SizedBox(
                height: 30,
                child: OutlinedButton(
                  onPressed: _toggleVibe,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(0, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact),
                  child: Text(_vibed ? 'UNVIBE' : 'VIBE', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ),
            IconButton(onPressed: _showPostMenu, tooltip: 'More', icon: const Icon(Icons.more_vert)),
          ],
        ),
      ),
    );
  }

  Widget _engagementRow() {
    return Row(
      children: [
        IconButton(key: Key('post-like-${widget.data.id}'), onPressed: _busy ? null : _toggleLike, icon: Icon(_liked ? Icons.favorite : Icons.favorite_border), tooltip: 'Like'),
        Text('$_likes'),
        const SizedBox(width: 4),
        IconButton(key: Key('post-comment-${widget.data.id}'), onPressed: _showComments, icon: const Icon(Icons.comment_outlined), tooltip: 'Comment'),
        Text('$_comments'),
        const SizedBox(width: 4),
        IconButton(key: Key('post-share-${widget.data.id}'), onPressed: _share, icon: const Icon(Icons.share_outlined), tooltip: 'Share'),
        const Spacer(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Card(
      key: Key('post-card-${data.id}'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _openFullPost,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _creatorHeader(),
              const SizedBox(height: 8),
              if (data.text.isNotEmpty) Text(data.text),
              if (data.imagePath != null) ...[
                const SizedBox(height: 12),
                _media(300),
              ],
              const SizedBox(height: 8),
              _engagementRow(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFullPost() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          minChildSize: 0.55,
          maxChildSize: 0.96,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              _creatorHeader(),
              const SizedBox(height: 16),
              if (widget.data.text.isNotEmpty) Text(widget.data.text, style: Theme.of(context).textTheme.bodyLarge),
              if (widget.data.imagePath != null) ...[
                const SizedBox(height: 16),
                _media(420),
              ],
              const SizedBox(height: 16),
              _engagementRow(),
            ],
          ),
        ),
      ),
    );
  }
}
