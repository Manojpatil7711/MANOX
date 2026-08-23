import 'package:flutter/material.dart';

import '../data/demo_posts.dart';
import 'widgets/post_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _composerCtrl = TextEditingController();
  final List<HomeDemoData> _posts = List<HomeDemoData>.from(demoPosts);
  bool _posting = false;

  @override
  void dispose() {
    _composerCtrl.dispose();
    super.dispose();
  }

  void _submitPost() {
    final text = _composerCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _posting = true;
    });

    // Local UI-only post addition
    final newPost = HomeDemoData(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      creatorName: 'You',
      handle: '@you',
      text: text,
      likes: 0,
      comments: 0,
    );

    setState(() {
      _posts.insert(0, newPost);
      _composerCtrl.clear();
      _posting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MANOX', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(
            Icons.public,
            key: Key('manox-home-logo'),
            size: 28,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          return Row(
            children: [
              Expanded(
                flex: isWide ? 2 : 1,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Welcome card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              const CircleAvatar(child: Icon(Icons.people)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Welcome to the MANOX Creator Community', style: TextStyle(fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text('Share what you create, follow creators, and grow together.'),
                                  ],
                                ),
                              ),
                              TextButton(onPressed: () {}, child: const Text('Get started')),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Composer
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                key: const Key('post-composer-field'),
                                controller: _composerCtrl,
                                maxLines: 4,
                                minLines: 1,
                                decoration: const InputDecoration(
                                  hintText: 'Share something with the community...',
                                  border: InputBorder.none,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    key: const Key('post-compose-submit'),
                                    onPressed: _posting ? null : _submitPost,
                                    child: _posting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Post'),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Feed
                      if (_posts.isEmpty)
                        SizedBox(
                          height: 200,
                          child: Center(child: Text('No posts yet. Be the first to create!', style: theme.textTheme.bodyMedium)),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final post = _posts[index];
                            return PostCard(data: post);
                          },
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemCount: _posts.length,
                        ),
                    ],
                  ),
                ),
              ),

              if (isWide)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        Card(child: Padding(padding: EdgeInsets.all(12), child: Text('Trending creators and communities'))),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}
