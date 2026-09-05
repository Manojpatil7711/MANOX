import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:manox/features/home/data/demo_posts.dart';
import 'package:manox/features/home/data/supabase_post_repository.dart';
import 'package:manox/features/home/presentation/widgets/post_card.dart';
import '../data/demo_profile.dart';
import '../data/supabase_profile_repository.dart';

class PublicProfilePage extends StatefulWidget {
  final String userId;
  const PublicProfilePage({super.key, required this.userId});
  @override State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  final _profiles = SupabaseProfileRepository();
  final _postsRepo = SupabasePostRepository();
  ProfileData? _profile;
  List<ManoxPost> _posts = const [];
  bool _loading = true;
  bool _followBusy = false;
  bool _isFollowing = false;
  int _followers = 0;
  int _following = 0;
  String? _error;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final profile = await _profiles.fetchProfileByUserId(widget.userId);
      List<ManoxPost> posts = const [];
      try { posts = await _postsRepo.fetchPostsByOwner(widget.userId); } catch (_) {}
      final currentUserId = _profiles.currentUserId;
      final self = currentUserId == widget.userId;
      var following = false;
      if (!self) { try { following = await _postsRepo.isFollowing(widget.userId); } catch (_) {} }
      var followers = 0;
      var followingCount = 0;
      try {
        followers = await _postsRepo.followerCount(widget.userId);
        followingCount = await _postsRepo.followingCount(widget.userId);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _posts = posts;
        _isFollowing = following;
        _followers = followers;
        _following = followingCount;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _loading = false; _error = error is StateError ? error.message : 'Unable to load profile.'; });
    }
  }

  Future<void> _toggleFollow() async {
    final profile = _profile;
    if (profile == null || _followBusy) return;
    setState(() => _followBusy = true);
    final previous = _isFollowing;
    try {
      final next = await _postsRepo.toggleFollow(profile.id, currentlyFollowing: previous);
      if (!mounted) return;
      setState(() {
        _isFollowing = next;
        _followers = (_followers + (next ? 1 : -1)).clamp(0, 1 << 30);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  HomeDemoData _data(ManoxPost post) => HomeDemoData(
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
    allowComments: post.allowComments,
    allowDownloads: post.allowDownloads,
  );

  String _flagForCountry(String? code) {
    final value = code?.trim().toUpperCase() ?? '';
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(value)) return '';
    return value.runes.map((rune) => String.fromCharCode(0x1F1E6 + rune - 65)).join();
  }

  Future<void> _openLink(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildMetadata(ThemeData theme, ProfileData profile) {
    final items = <Widget>[];
    final profession = profile.profession?.trim() ?? '';
    final flag = _flagForCountry(profile.countryCode);
    if (profession.isNotEmpty) items.add(Text(profession, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)));
    if (flag.isNotEmpty) items.add(Text(flag, style: const TextStyle(fontSize: 20)));
    final link = profile.otherLink?.trim() ?? '';
    if (link.isNotEmpty) {
      items.add(InkWell(onTap: () => _openLink(link), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.link_outlined, size: 18), SizedBox(width: 5), Text('Link', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))])));
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(top: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final item in items) Padding(padding: const EdgeInsets.only(bottom: 3), child: item)]));
  }

  Widget _buildProfileContent(ThemeData theme, ProfileData profile) {
    final isSelf = _profiles.currentUserId == widget.userId;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 46,
                backgroundImage: profile.avatarUrl == null ? null : NetworkImage(profile.avatarUrl!),
                child: profile.avatarUrl == null ? const Icon(Icons.person_outline_rounded, size: 42) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: -0.35)),
                    const SizedBox(height: 5),
                    Text(profile.handle.replaceFirst(RegExp(r'^@+'), '@'), maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.15)),
                    if (profile.isCreator) ...[
                      const SizedBox(height: 7),
                      Row(children: [
                        Icon(Icons.verified_rounded, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 5),
                        const Text('CREATOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (!isSelf) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _followBusy ? null : _toggleFollow,
                icon: _followBusy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_isFollowing ? Icons.person_remove_alt_1_rounded : Icons.person_add_alt_1_rounded),
                label: Text(_isFollowing ? 'Following' : 'Follow'),
              ),
            ),
          ],
          if (profile.bio.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(profile.bio, maxLines: 4, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
          ],
          _buildMetadata(theme, profile),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _Stat(value: '${_posts.length}', label: 'Posts'),
            _Stat(value: '$_followers', label: 'Followers'),
            _Stat(value: '$_following', label: 'Following'),
          ]),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (_posts.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(28), child: Center(child: Text('No public posts yet.'))))
          else
            for (final post in _posts)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: PostCard(data: _data(post), repository: _postsRepo, onChanged: _load)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null || _profile == null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.person_off_outlined, size: 48),
        const SizedBox(height: 10),
        Text(_error ?? 'Profile unavailable'),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: _load, child: const Text('TRY AGAIN')),
      ]));
    }
    return _buildProfileContent(theme, _profile!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new_rounded)), title: const Text('Profile')),
      body: SafeArea(child: _buildBody(theme)),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(label)]);
}
