import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manox/features/home/data/supabase_post_repository.dart';
import 'package:manox/features/home/presentation/widgets/post_card.dart';

import '../data/demo_profile.dart';
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
  final SupabasePostRepository _postRepo = SupabasePostRepository();
  ProfileData? _profile;
  bool _loading = true;
  List<ManoxPost> _posts = [];

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? SupabaseProfileRepository();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final p = await _repo.fetchProfile();
      final posts = await _postRepo.fetchMyPosts();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _posts = posts;
        _loading = false;
      });
    } catch (e) {
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

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('profile-back-button'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Back',
          onPressed: _goBack,
        ),
        title: const Text('Profile'),
        actions: [
          IconButton(
            key: const Key('profile-settings-button'),
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings & privacy',
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _profile == null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.person_off_outlined, size: 48),
                      const SizedBox(height: 12),
                      const Text('Unable to load profile'),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('TRY AGAIN'),
                      ),
                    ]),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              key: const Key('profile-avatar'),
                              radius: 48,
                              backgroundImage: _profile!.avatarUrl != null ? NetworkImage(_profile!.avatarUrl!) : null,
                              child: _profile!.avatarUrl == null ? const Icon(Icons.person_outline_rounded, size: 48) : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_profile!.displayName, key: const Key('profile-name'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(_profile!.handle, key: const Key('profile-handle'), style: theme.textTheme.bodyMedium),
                                  if (_profile!.bio.trim().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(_profile!.bio, key: const Key('profile-bio')),
                                  ],
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
                        const SizedBox(height: 24),
                        Text('Posts', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        if (_posts.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(children: const [Icon(Icons.inbox_outlined, size: 48), SizedBox(height: 8), Text('Your posts will appear here.')]),
                            ),
                          )
                        else
                          ..._posts.map((post) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: PostCard(data: HomeDemoData(id: post.id, creatorName: post.creatorName, handle: post.handle, text: post.text, likes: post.likes, comments: post.comments, imagePath: post.imageUrl, likedByMe: post.likedByMe, isRemote: true), repository: _postRepo, onChanged: _load),
                              )),
                      ],
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
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label),
        ],
      );
}
