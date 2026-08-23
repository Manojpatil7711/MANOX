import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/demo_posts.dart';
import '../../data/supabase_post_repository.dart';

class PostCard extends StatefulWidget {
  final HomeDemoData data;
  final SupabasePostRepository? repository;

  const PostCard({
    super.key,
    required this.data,
    this.repository,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _liked;
  late int _likes;
  late int _comments;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.data.likedByMe;
    _likes = widget.data.likes;
    _comments = widget.data.comments;
  }

  Future<void> _toggleLike() async {
    if (_busy) return;
    final repo = widget.repository;
    if (repo == null || !widget.data.isRemote) {
      setState(() {
        _liked = !_liked;
        _likes += _liked ? 1 : -1;
      });
      return;
    }

    setState(() => _busy = true);
    try {
      final liked = await repo.toggleLike(widget.data.id, _liked);
      if (!mounted) return;
      setState(() {
        _liked = liked;
        _likes += liked ? 1 : -1;
      });
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showComments() async {
    final repo = widget.repository;
    if (repo == null || !widget.data.isRemote) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comments will be available on live posts.')));
      }
      return;
    }

    final controller = TextEditingController();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: FutureBuilder<List<ManoxComment>>(
                          future: repo.fetchComments(widget.data.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('Unable to load comments.'));
                            }
                            final comments = snapshot.data ?? const <ManoxComment>[];
                            if (comments.isEmpty) {
                              return const Center(child: Text('No comments yet. Be the first!'));
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: comments.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (_, index) {
                                final comment = comments[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(comment.body),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                textInputAction: TextInputAction.send,
                                decoration: const InputDecoration(hintText: 'Write a comment...'),
                                onSubmitted: (_) async {
                                  if (controller.text.trim().isEmpty) return;
                                  await repo.addComment(widget.data.id, controller.text);
                                  controller.clear();
                                  setSheetState(() {});
                                  if (mounted) setState(() => _comments += 1);
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () async {
                                if (controller.text.trim().isEmpty) return;
                                try {
                                  await repo.addComment(widget.data.id, controller.text);
                                  controller.clear();
                                  setSheetState(() {});
                                  if (mounted) setState(() => _comments += 1);
                                } catch (e) {
                                  if (mounted) _showError(e.toString());
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
    final repo = widget.repository;
    final url = repo == null || !widget.data.isRemote
        ? 'https://manox.app'
        : await repo.createShareUrl(widget.data.id);
    if (repo != null && widget.data.isRemote) {
      try {
        await repo.recordShare(widget.data.id);
      } catch (_) {
        // Sharing should still work even if analytics recording fails.
      }
    }
    await SharePlus.instance.share(ShareParams(
      text: '${widget.data.text}\n\n$url',
      title: 'Share on MANOX',
    ));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message.replaceFirst('Exception: ', ''))));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Card(
      key: Key('post-card-${data.id}'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.creatorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(data.handle, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}, tooltip: 'More'),
              ],
            ),
            const SizedBox(height: 8),
            Text(data.text),
            if (data.imagePath != null) ...[
              const SizedBox(height: 12),
              FutureBuilder<String?>(
                future: widget.repository?.signedMediaUrl(data.imagePath!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(snapshot.data!, width: double.infinity, height: 240, fit: BoxFit.cover),
                  );
                },
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      key: Key('post-like-${data.id}'),
                      onPressed: _busy ? null : _toggleLike,
                      icon: Icon(_liked ? Icons.favorite : Icons.favorite_border, color: _liked ? Colors.red : null),
                      tooltip: 'Like',
                    ),
                    Text('$_likes'),
                    const SizedBox(width: 12),
                    IconButton(
                      key: Key('post-comment-${data.id}'),
                      onPressed: _showComments,
                      icon: const Icon(Icons.comment_outlined),
                      tooltip: 'Comment',
                    ),
                    Text('$_comments'),
                  ],
                ),
                IconButton(
                  key: Key('post-share-${data.id}'),
                  onPressed: _share,
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Share',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
