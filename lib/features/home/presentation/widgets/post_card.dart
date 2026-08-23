import 'package:flutter/material.dart';

import '../../data/demo_posts.dart';

class PostCard extends StatefulWidget {
  final HomeDemoData data;
  const PostCard({super.key, required this.data});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _liked;
  late int _likes;

  @override
  void initState() {
    super.initState();
    _liked = false;
    _likes = widget.data.likes;
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
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
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                  tooltip: 'More',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(data.text),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      key: Key('post-like-${data.id}'),
                      onPressed: _toggleLike,
                      icon: Icon(_liked ? Icons.favorite : Icons.favorite_border, color: _liked ? Colors.red : null),
                      tooltip: 'Like',
                      semanticLabel: 'Like',
                    ),
                    Text('$_likes'),
                    const SizedBox(width: 12),
                    IconButton(
                      key: Key('post-comment-${data.id}'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment action (demo)')));
                      },
                      icon: const Icon(Icons.comment_outlined),
                      tooltip: 'Comment',
                      semanticLabel: 'Comment',
                    ),
                    Text('${data.comments}'),
                  ],
                ),
                IconButton(
                  key: Key('post-share-${data.id}'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share action (demo)')));
                  },
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Share',
                  semanticLabel: 'Share',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
