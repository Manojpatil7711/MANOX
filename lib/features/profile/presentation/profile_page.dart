import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
  void initState() { super.initState(); _repo = widget.repository ?? SupabaseProfileRepository(); _load(); }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    ProfileData? profile;
    List<ManoxPost> posts = <ManoxPost>[];
    try { profile = await _repo.fetchProfile(); } catch (_) {}
    if (profile != null) {
      try { posts = await _postRepo.fetchMyPosts(); } catch (_) {}
    }
    if (!mounted) return;
    setState(() { _profile = profile; _posts = posts; _loading = false; });
  }

  Future<void> _editProfile() async {
    var profile = _profile;
    if (profile == null) { await _load(); profile = _profile; }
    if (profile == null || !mounted) { _show('Profile is still loading. Please try again.'); return; }
    final current = profile;
    final updated = await Navigator.of(context).push<ProfileData>(MaterialPageRoute(builder: (_) => EditProfilePage(
      repository: _repo,
      initialName: current.displayName,
      initialUsername: current.handle,
      initialBio: current.bio,
      initialAvatarUrl: current.avatarUrl,
      initialCountryCode: current.countryCode,
      initialGender: current.gender,
      initialProfession: current.profession,
      initialDateOfBirth: current.dateOfBirth,
      initialSkills: current.skills,
      initialCreatorCategory: current.creatorCategory,
      initialOtherLink: current.otherLink,
    )));
    if (updated != null && mounted) setState(() => _profile = updated);
  }

  void _show(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  void _goBack() { if (context.canPop()) context.pop(); else context.go('/home'); }

  Future<void> _shareProfile() async {
    final profile = _profile;
    if (profile == null) return;
    final username = profile.handle.replaceFirst(RegExp(r'^@+'), '').trim();
    final profileUrl = 'https://manox.app/profile/$username';
    try {
      await SharePlus.instance.share(ShareParams(text: 'Follow ${profile.displayName} on MANOX\n$profileUrl'));
    } catch (e) {
      if (mounted) _show('Unable to share profile: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  void _openProfileSection(String label) { if (label == 'Monetization') context.push('/monetization'); else if (label == 'Wallet') context.push('/payout'); }
  HomeDemoData _toHomePost(ManoxPost post) => HomeDemoData(id: post.id, creatorName: post.creatorName, handle: post.handle, text: post.text, likes: post.likes, comments: post.comments, imagePath: post.imageUrl, likedByMe: post.likedByMe, isRemote: true, ownerUserId: post.ownerUserId);
  String _flagForCountry(String? code) { final value = code?.trim().toUpperCase() ?? ''; if (!RegExp(r'^[A-Z]{2}$').hasMatch(value)) return ''; return value.runes.map((r) => String.fromCharCode(0x1F1E6 + r - 65)).join(); }
  Future<void> _openOtherLink(String value) async { final uri = Uri.tryParse(value); if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return; await launchUrl(uri, mode: LaunchMode.externalApplication); }

  List<ManoxPost> get _visiblePosts {
    if (_selectedTab == 0) return _posts;
    if (_selectedTab == 1) return _posts.where((post) => post.contentType == 'beat').toList();
    return _posts.where((post) => post.contentType != 'beat').toList();
  }

  Widget _profileDetails(ProfileData profile) {
    final flag = _flagForCountry(profile.countryCode);
    final profession = profile.profession?.trim() ?? '';
    final children = <Widget>[];
    if (profession.isNotEmpty) children.add(Text(profession, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)));
    if (flag.isNotEmpty) children.add(Text(flag, style: const TextStyle(fontSize: 20)));
    final otherLink = profile.otherLink?.trim();
    if (otherLink != null && otherLink.isNotEmpty) children.add(Padding(padding: const EdgeInsets.only(top: 4), child: InkWell(onTap: () => _openOtherLink(otherLink), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.link_outlined, size: 18), SizedBox(width: 5), Text('Link', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))]))));
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(top: 6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children.map((w) => Padding(padding: const EdgeInsets.only(bottom: 3), child: w)).toList()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget body;
    if (_loading) body = const Center(child: CircularProgressIndicator());
    else if (_profile == null) body = Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.person_off_outlined, size: 48), const SizedBox(height: 12), const Text('Unable to load profile'), const SizedBox(height: 12), OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('TRY AGAIN'))]));
    else {
      final profile = _profile!;
      final visiblePosts = _visiblePosts;
      final children = <Widget>[
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [CircleAvatar(key: const Key('profile-avatar'), radius: 48, backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null, child: profile.avatarUrl == null ? const Icon(Icons.person_outline_rounded, size: 48) : null), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(profile.displayName, key: const Key('profile-name'), maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 23, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(profile.handle, key: const Key('profile-handle'), maxLines: 1, overflow: TextOverflow.ellipsis), if (profile.isCreator) Row(children: [Icon(Icons.verified_rounded, size: 16, color: theme.colorScheme.primary), const SizedBox(width: 5), const Text('CREATOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))])]))]),
        const SizedBox(height: 14), if (profile.bio.trim().isNotEmpty) Text(profile.bio, key: const Key('profile-bio'), maxLines: 4, overflow: TextOverflow.ellipsis), _profileDetails(profile), const SizedBox(height: 12),
        Row(children: [Expanded(child: OutlinedButton.icon(key: const Key('profile-edit-button'), onPressed: _loading ? null : _editProfile, icon: const Icon(Icons.edit_outlined), label: const Text('EDIT PROFILE'))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(key: const Key('profile-share-button'), onPressed: _shareProfile, icon: const Icon(Icons.ios_share_outlined), label: const Text('SHARE')))]),
        const SizedBox(height: 18), Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 15), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_Stat(value: '${profile.postIds.length}', label: 'Posts'), _Stat(value: '${profile.followers}', label: 'Followers'), _Stat(value: '${profile.following}', label: 'Following')]))), const SizedBox(height: 14),
        Row(children: [Expanded(child: _ProfileAction(icon: Icons.monetization_on_outlined, title: 'Monetization', subtitle: profile.isCreator ? 'Creator earnings' : 'Creator tools', onTap: () => _openProfileSection('Monetization'))), const SizedBox(width: 10), Expanded(child: _ProfileAction(icon: Icons.account_balance_wallet_outlined, title: 'Wallet', subtitle: 'Balance & payouts', onTap: () => _openProfileSection('Wallet')))]),
        const SizedBox(height: 22), Row(children: [_ProfileTab(icon: Icons.grid_on_rounded, label: 'POSTS', selected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)), _ProfileTab(icon: Icons.play_circle_outline_rounded, label: 'BEATS', selected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)), _ProfileTab(icon: Icons.video_library_outlined, label: 'MEDIA', selected: _selectedTab == 2, onTap: () => setState(() => _selectedTab = 2))]), Divider(height: 1, color: theme.dividerColor), const SizedBox(height: 12),
      ];
      if (visiblePosts.isEmpty) children.add(_EmptySection(message: _selectedTab == 0 ? 'Your posts will appear here.' : _selectedTab == 1 ? 'Your BEATS will appear here.' : 'Your media will appear here.'));
      else children.addAll(visiblePosts.map((post) => Padding(padding: const EdgeInsets.only(bottom: 8), child: PostCard(data: _toHomePost(post), repository: _postRepo, onChanged: _load))));
      body = RefreshIndicator(onRefresh: _load, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: children));
    }
    return Scaffold(appBar: AppBar(leading: IconButton(key: const Key('profile-back-button'), icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: _goBack), title: const Text('Profile'), actions: [IconButton(key: const Key('profile-settings-button'), onPressed: () => context.push('/settings'), icon: const Icon(Icons.settings_outlined))]), body: SafeArea(child: body));
  }
}

class _ProfileAction extends StatelessWidget { final IconData icon; final String title; final String subtitle; final VoidCallback onTap; const _ProfileAction({required this.icon, required this.title, required this.subtitle, required this.onTap}); @override Widget build(BuildContext context) => Card(child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(13), child: Row(children: [Icon(icon, size: 24), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis)]))])))); }
class _ProfileTab extends StatelessWidget { final IconData icon; final String label; final bool selected; final VoidCallback onTap; const _ProfileTab({required this.icon, required this.label, required this.selected, required this.onTap}); @override Widget build(BuildContext context) => Expanded(child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(children: [Icon(icon, size: 21, color: selected ? Theme.of(context).colorScheme.primary : null), const SizedBox(height: 5), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))])))); }
class _EmptySection extends StatelessWidget { final String message; const _EmptySection({required this.message}); @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(28), child: Column(children: [const Icon(Icons.inbox_outlined, size: 42), const SizedBox(height: 8), Text(message)]))); }
class _Stat extends StatelessWidget { final String value; final String label; const _Stat({required this.value, required this.label}); @override Widget build(BuildContext context) => Column(children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(label)]); }
