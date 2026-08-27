import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manox/features/home/data/demo_posts.dart';
import 'package:manox/features/home/data/supabase_post_repository.dart';
import 'package:manox/features/home/presentation/widgets/post_card.dart';
import '../data/demo_profile.dart';
import '../data/supabase_profile_repository.dart';
import '../domain/profile_repository.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  final ProfileRepository? repository;
  const ProfilePage({super.key, this.repository});
  @override State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileRepository _repo;
  final SupabasePostRepository _postRepo = SupabasePostRepository();
  ProfileData? _profile;
  List<ManoxPost> _posts = <ManoxPost>[];
  bool _loading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? SupabaseProfileRepository();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final profile = await _repo.fetchProfile();
      final posts = await _postRepo.fetchMyPosts();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _posts = posts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _posts = <ManoxPost>[];
        _loading = false;
      });
    }
  }

  Future<void> _editProfile() async {
    final profile = _profile;
    if (profile == null) return;
    final updated = await Navigator.of(context).push<ProfileData>(
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          repository: _repo,
          initialName: profile.displayName,
          initialUsername: profile.handle,
          initialBio: profile.bio,
          initialAvatarUrl: profile.avatarUrl,
          initialCountryCode: profile.countryCode,
          initialGender: profile.gender,
          initialProfession: profile.profession,
          initialDateOfBirth: profile.dateOfBirth,
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

  Future<void> _shareProfile() async {
    if (_profile == null) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ListTile(
                leading: Icon(Icons.ios_share_rounded),
                title: Text('Share profile'),
                subtitle: Text('MANOX profile sharing'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('DONE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProfileSection(String label) {
    if (label == 'Monetization') {
      context.push('/monetization');
    } else if (label == 'Wallet') {
      context.push('/payout');
    }
  }

  HomeDemoData _toHomePost(ManoxPost post) {
    return HomeDemoData(
      id: post.id,
      creatorName: post.creatorName,
      handle: post.handle,
      text: post.text,
      likes: post.likes,
      comments: post.comments,
      imagePath: post.imageUrl,
      likedByMe: post.likedByMe,
      isRemote: true,
      ownerUserId: post.ownerUserId,
    );
  }

  Widget _profileDetails(ProfileData profile) {
    final details = <String>[];
    final country = profile.countryCode?.trim() ?? '';
    final gender = switch (profile.gender) {
      'female' => 'Female',
      'male' => 'Male',
      'other' => 'Other',
      _ => '',
    };
    final profession = profile.profession?.trim() ?? '';
    if (country.isNotEmpty) details.add(country.toUpperCase());
    if (profession.isNotEmpty) details.add(profession);
    if (gender.isNotEmpty) details.add(gender);
    if (details.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: details
            .map(
              (text) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_profile == null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.person_off_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('Unable to load profile'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('TRY AGAIN'),
            ),
          ],
        ),
      );
    } else {
      final profile = _profile!;
      final children = <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              key: const Key('profile-avatar'),
              radius: 48,
              backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
              child: profile.avatarUrl == null ? const Icon(Icons.person_outline_rounded, size: 48) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(profile.displayName, key: const Key('profile-name'), maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 23, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(profile.handle, key: const Key('profile-handle'), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (profile.isCreator)
                    Row(children: <Widget>[
                      Icon(Icons.verified_rounded, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 5),
                      const Text('CREATOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ]),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (profile.bio.trim().isNotEmpty) Text(profile.bio, key: const Key('profile-bio'), maxLines: 4, overflow: TextOverflow.ellipsis),
        _profileDetails(profile),
        const SizedBox(height: 12),
        Row(children: <Widget>[
          Expanded(child: OutlinedButton.icon(key: const Key('profile-edit-button'), onPressed: _editProfile, icon: const Icon(Icons.edit_outlined), label: const Text('EDIT PROFILE'))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(key: const Key('profile-share-button'), onPressed: _shareProfile, icon: const Icon(Icons.ios_share_outlined), label: const Text('SHARE'))),
        ]),
        const SizedBox(height: 18),
        Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 15), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
          _Stat(value: '${profile.postIds.length}', label: 'Posts'),
          _Stat(value: '${profile.followers}', label: 'Followers'),
          _Stat(value: '${profile.following}', label: 'Following'),
        ]))),
        const SizedBox(height: 14),
        Row(children: <Widget>[
          Expanded(child: _ProfileAction(icon: Icons.monetization_on_outlined, title: 'Monetization', subtitle: profile.isCreator ? 'Creator earnings' : 'Creator tools', onTap: () => _openProfileSection('Monetization'))),
          const SizedBox(width: 10),
          Expanded(child: _ProfileAction(icon: Icons.account_balance_wallet_outlined, title: 'Wallet', subtitle: 'Balance & payouts', onTap: () => _openProfileSection('Wallet'))),
        ]),
        const SizedBox(height: 22),
        Row(children: <Widget>[
          _ProfileTab(icon: Icons.grid_on_rounded, label: 'POSTS', selected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
          _ProfileTab(icon: Icons.play_circle_outline_rounded, label: 'BEATS', selected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
          _ProfileTab(icon: Icons.video_library_outlined, label: 'MEDIA', selected: _selectedTab == 2, onTap: () => setState(() => _selectedTab = 2)),
        ]),
        Divider(height: 1, color: theme.dividerColor),
        const SizedBox(height: 12),
      ];
      if (_selectedTab == 0) {
        if (_posts.isEmpty) {
          children.add(const _EmptySection(message: 'Your posts will appear here.'));
        } else {
          children.addAll(_posts.map((post) => Padding(padding: const EdgeInsets.only(bottom: 8), child: PostCard(data: _toHomePost(post), repository: _postRepo, onChanged: _load))));
        }
      } else {
        children.add(_EmptySection(message: _selectedTab == 1 ? 'Your BEATS will appear here.' : 'Your media will appear here.'));
      }
      body = RefreshIndicator(onRefresh: _load, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: children));
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(key: const Key('profile-back-button'), icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: _goBack),
        title: const Text('Profile'),
        actions: <Widget>[
          IconButton(key: const Key('profile-settings-button'), onPressed: () => context.push('/settings'), icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ProfileAction({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(13), child: Row(children: <Widget>[
    Icon(icon, size: 24), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 3), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
    ])),
  ]))));
}

class _ProfileTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ProfileTab({required this.icon, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(children: <Widget>[
    Icon(icon, size: 21, color: selected ? Theme.of(context).colorScheme.primary : null),
    const SizedBox(height: 5), Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  ]))));
}

class _EmptySection extends StatelessWidget {
  final String message;
  const _EmptySection({required this.message});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(28), child: Column(children: <Widget>[
    const Icon(Icons.inbox_outlined, size: 42), const SizedBox(height: 8), Text(message),
  ])));
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: <Widget>[
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(label),
  ]);
}
