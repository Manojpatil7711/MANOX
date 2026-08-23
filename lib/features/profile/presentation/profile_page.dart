import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manox/features/home/data/demo_posts.dart';
import 'package:manox/features/home/presentation/widgets/post_card.dart';

import '../data/demo_profile.dart';
import '../data/local_profile_repository.dart';
import '../domain/profile_repository.dart';

class ProfilePage extends StatefulWidget {
  final ProfileRepository? repository;
  const ProfilePage({super.key, this.repository});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileRepository _repo;
  ProfileData? _profile;
  bool _loading = true;
  List<HomeDemoData> _posts = [];

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? const LocalProfileRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await _repo.fetchProfile();
      final ids = await _repo.fetchPostIds();
      // Map ids to demo posts from home demo data
      final posts = demoPosts.where((d) => ids.contains(d.id)).toList();
      setState(() {
        _profile = p;
        _posts = posts;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _profile = null;
        _posts = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            key: const Key('profile-settings-button'),
            onPressed: () {
              // Use GoRouter for navigation
              GoRouter.of(context).go('/settings');
            },
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _profile == null
                ? const Center(child: Text('Unable to load profile'))
                : LayoutBuilder(builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(key: Key('profile-avatar'), radius: 36, child: Icon(Icons.person, size: 36)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_profile!.displayName, key: const Key('profile-name'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(_profile!.handle, key: const Key('profile-handle'), style: theme.textTheme.bodySmall),
                                    const SizedBox(height: 8),
                                    Text(_profile!.bio, key: const Key('profile-bio')),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (_profile!.isCreator)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                                            child: const Text('Creator', style: TextStyle(color: Colors.white)),
                                          ),
                                        const SizedBox(width: 12),
                                        ElevatedButton(
                                          key: const Key('profile-edit-button'),
                                          onPressed: () {},
                                          child: const Text('Edit Profile'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Text('${_profile!.postIds.length}', key: const Key('profile-post-count'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Text('Posts'),
                                  const SizedBox(height: 8),
                                  Text('${_profile!.followers}', key: const Key('profile-followers-count'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Text('Followers'),
                                  const SizedBox(height: 8),
                                  Text('${_profile!.following}', key: const Key('profile-following-count'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Text('Following'),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text('Posts', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 8),
                          if (_posts.isEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: const [
                                    Icon(Icons.inbox_outlined, size: 48),
                                    SizedBox(height: 8),
                                    Text('No posts yet'),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) => PostCard(data: _posts[index]),
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemCount: _posts.length,
                            )
                        ],
                      ),
                    );
                  }),
      ),
    );
  }
}
