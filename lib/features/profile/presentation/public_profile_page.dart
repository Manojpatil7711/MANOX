import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  String? _error;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final profile = await _profiles.fetchProfileByUserId(widget.userId);
      final posts = await _postsRepo.fetchPostsByOwner(widget.userId);
      if (!mounted) return;
      setState(() { _profile = profile; _posts = posts; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Profile unavailable'; });
    }
  }

  HomeDemoData _data(ManoxPost p) => HomeDemoData(id: p.id, creatorName: p.creatorName, handle: p.handle, text: p.text, likes: p.likes, comments: p.comments, imagePath: p.imageUrl, likedByMe: p.likedByMe, isRemote: true, ownerUserId: p.ownerUserId);

  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new_rounded)), title: const Text('Profile')),
      body: SafeArea(child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.person_off_outlined, size: 48), const SizedBox(height: 10), Text(_error!), const SizedBox(height: 10), OutlinedButton(onPressed: _load, child: const Text('TRY AGAIN'))]))
        : RefreshIndicator(onRefresh: _load, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 18, 16, 32), children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(radius: 46, backgroundImage: _profile!.avatarUrl == null ? null : NetworkImage(_profile!.avatarUrl!), child: _profile!.avatarUrl == null ? const Icon(Icons.person_outline_rounded, size: 42) : null),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_profile!.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: -0.35)),
                const SizedBox(height: 5),
                Text(_profile!.handle.replaceFirst(RegExp(r'^@+'), '@'), maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.15)),
                if (_profile!.isCreator) ...[const SizedBox(height: 7), Row(children: [Icon(Icons.verified_rounded, size: 16, color: theme.colorScheme.primary), const SizedBox(width: 5), const Text('CREATOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8))])],
                if (_profile!.bio.trim().isNotEmpty) ...[const SizedBox(height: 9), Text(_profile!.bio, maxLines: 4, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(height: 1.35))],
              ])),
            ]),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_Stat(value: '${_posts.length}', label: 'Posts'), _Stat(value: '${_profile!.followers}', label: 'Followers'), _Stat(value: '${_profile!.following}', label: 'Following')]),
            const SizedBox(height: 20), const Divider(height: 1), const SizedBox(height: 12),
            if (_posts.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(28), child: Center(child: Text('No public posts yet.')))) else ..._posts.map((p) => Padding(padding: const EdgeInsets.only(bottom: 8), child: PostCard(data: _data(p), repository: _postsRepo, onChanged: _load))),
          ])),
    );
  }
}

class _Stat extends StatelessWidget { final String value; final String label; const _Stat({required this.value, required this.label}); @override Widget build(BuildContext context) => Column(children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(label)]); }
