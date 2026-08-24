import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manox/features/home/data/demo_posts.dart';
import 'package:manox/features/home/presentation/widgets/post_card.dart';

import '../data/demo_profile.dart';
import '../data/local_profile_repository.dart';
import '../data/supabase_profile_repository.dart';
import '../domain/profile_repository.dart';
import 'edit_profile_page.dart';

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
    _repo = widget.repository ?? const SupabaseProfileRepository();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final p = await _repo.fetchProfile();
      final ids = await _repo.fetchPostIds();
      final posts = demoPosts.where((d) => ids.contains(d.id)).toList();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _posts = posts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _posts = [];
        _loading = false;
      });
    }
  }

  Future<void> _editProfile() async {
    final p = _profile;
    if (p == null) return;
    final updated = await Navigator.of(context).push<ProfileData>(
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          repository: _repo,
          initialName: p.displayName,
          initialUsername: p.handle,
          initialBio: p.bio,
          initialAvatarUrl: p.avatarUrl,
        ),
      ),
    );
    if (updated != null && mounted) setState(() => _profile = updated);
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
            onPressed: () => GoRouter.of(context).go('/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _profile == null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Unable to load profile'),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _load, child: const Text('TRY AGAIN')),
                    ]),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                key: const Key('profile-avatar'),
                                radius: 42,
                                backgroundImage: _profile!.avatarUrl != null ? NetworkImage(_profile!.avatarUrl!) : null,
                                child: _profile!.avatarUrl == null ? const Icon(Icons.person, size: 42) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_profile!.displayName, key: const Key('profile-name'), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(_profile!.handle, key: const Key('profile-handle'), style: theme.textTheme.bodySmall),
                                    const SizedBox(height: 10),
                                    Text(_profile!.bio, key: const Key('profile-bio')),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        key: const Key('profile-edit-button'),
                                        onPressed: _editProfile,
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        label: const Text('EDIT PROFILE'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _Stat(value: '${_profile!.postIds.length}', label: 'Posts'),
                                  _Stat(value: '${_profile!.followers}', label: 'Followers'),
                                  _Stat(value: '${_profile!.following}', label: 'Following'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('Posts', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 8),
                          if (_posts.isEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(children: const [Icon(Icons.inbox_outlined, size: 48), SizedBox(height: 8), Text('Your posts will appear here.')]),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) => PostCard(data: _posts[index]),
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemCount: _posts.length,
                            ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(label)]);
}
