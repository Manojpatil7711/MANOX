import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../data/demo_posts.dart';
import '../data/supabase_post_repository.dart';
import 'widgets/media_preview.dart';

class BeatsPage extends StatefulWidget {
  const BeatsPage({super.key});
  @override State<BeatsPage> createState() => _BeatsPageState();
}

class _BeatsPageState extends State<BeatsPage> {
  final _repository = SupabasePostRepository();
  final _controller = PageController();
  List<HomeDemoData> _posts = [];
  bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  Future<void> _load() async {
    try {
      final remote = await _repository.fetchBeats();
      if (!mounted) return;
      setState(() { _posts = remote.map((post) => HomeDemoData(id: post.id, creatorName: post.creatorName, handle: post.handle, text: post.text, likes: post.likes, comments: post.comments, imagePath: post.imageUrl, mediaType: post.contentType, likedByMe: post.likedByMe, isRemote: true, ownerUserId: post.ownerUserId)).toList(); _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: Colors.black, body: SafeArea(child: Stack(children: [
    if (_loading) const Center(child: CircularProgressIndicator())
    else if (_posts.isEmpty) const Center(child: Text('No BEATS yet.\nCreate a video to be the first.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16)))
    else PageView.builder(controller: _controller, scrollDirection: Axis.vertical, itemCount: _posts.length, itemBuilder: (context, index) => _BeatItem(post: _posts[index], repository: _repository)),
    Positioned(top: 8, left: 8, child: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded, color: Colors.white))),
    const Positioned(top: 18, left: 0, right: 0, child: Center(child: Text('BEATS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 2)))),
  ])));
}

class _BeatItem extends StatefulWidget {
  final HomeDemoData post; final SupabasePostRepository repository;
  const _BeatItem({required this.post, required this.repository});
  @override State<_BeatItem> createState() => _BeatItemState();
}
class _BeatItemState extends State<_BeatItem> {
  String? _url; bool _loading = true; late bool _liked; late int _likes; late int _comments; late bool _saved; bool _busy = false;
  @override void initState() { super.initState(); _liked = widget.post.likedByMe; _likes = widget.post.likes; _comments = widget.post.comments; _saved = false; _resolve(); }
  Future<void> _resolve() async { final path = widget.post.imagePath; if (path == null || path.isEmpty) { if (mounted) setState(() => _loading = false); return; } try { final url = await widget.repository.signedMediaUrl(path); if (mounted) setState(() { _url = url; _loading = false; }); } catch (_) { if (mounted) setState(() => _loading = false); } }
  void _openCreator() { final id = widget.post.ownerUserId; if (id != null && id.isNotEmpty) context.push('/profile/${Uri.encodeComponent(id)}'); }
  Future<void> _toggleLike() async { if (_busy) return; final previous = _liked; setState(() { _busy = true; _liked = !previous; _likes += previous ? -1 : 1; }); try { await widget.repository.toggleLike(widget.post.id, previous); } catch (_) { if (mounted) setState(() { _liked = previous; _likes += previous ? 1 : -1; }); } finally { if (mounted) setState(() => _busy = false); } }
  Future<void> _commentsSheet() async { final comments = await widget.repository.fetchComments(widget.post.id); if (!mounted) return; final controller = TextEditingController(); await showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (sheetContext) => SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16), child: StatefulBuilder(builder: (context, setSheetState) => SizedBox(height: MediaQuery.of(context).size.height * .65, child: Column(children: [const Align(alignment: Alignment.centerLeft, child: Text('Comments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))), const SizedBox(height: 10), Expanded(child: comments.isEmpty ? const Center(child: Text('No comments yet. Be the first.')) : ListView.separated(itemCount: comments.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (_, index) => ListTile(leading: const CircleAvatar(child: Icon(Icons.person_outline)), title: Text(comments[index].userName), subtitle: Text(comments[index].body)))), Row(children: [Expanded(child: TextField(controller: controller, textInputAction: TextInputAction.send, onSubmitted: (_) => _submitComment(controller, setSheetState), decoration: const InputDecoration(hintText: 'Add a comment…'))), const SizedBox(width: 8), IconButton(icon: const Icon(Icons.send_rounded), onPressed: () => _submitComment(controller, setSheetState))])]))))); controller.dispose(); if (mounted) setState(() {}); }
  Future<void> _submitComment(TextEditingController controller, StateSetter setSheetState) async { final body = controller.text.trim(); if (body.isEmpty) return; try { await widget.repository.addComment(widget.post.id, body); controller.clear(); _comments++; setState(() {}); setSheetState(() {}); } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not add comment.'))); } }
  Future<void> _toggleSave() async { try { if (_saved) await widget.repository.unsaveContent(widget.post.id); else await widget.repository.saveContent(widget.post.id); if (mounted) setState(() => _saved = !_saved); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update Save: $e'))); } }
  Future<void> _share() async { try { final url = await widget.repository.createShareUrl(widget.post.id); await widget.repository.recordShare(widget.post.id); if (!mounted) return; await SharePlus.instance.share(ShareParams(text: '${widget.post.text}\n$url', subject: 'Check out this BEAT on MANOX')); } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not share this BEAT.'))); } }
  void _openMonetization() { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('₹ Earnings are locked until monetization is enabled.'))); context.push('/monetization'); }
  @override Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
    if (_loading) const Center(child: CircularProgressIndicator(color: Colors.white))
    else if (_url != null && isManoxVideo(widget.post.imagePath ?? '')) ManoxMediaPreview(url: _url!, height: double.infinity, fit: BoxFit.cover, autoPlay: true, loop: false, fullScreenStyle: true)
    else const _BeatFallback(),
    const IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87], stops: [.55, 1])))),
    Positioned(left: 16, right: 78, bottom: 28, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [InkWell(onTap: _openCreator, child: Text(widget.post.handle.replaceFirst(RegExp(r'^@+'), '@'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800))), const SizedBox(height: 8), Text(widget.post.text, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3))])),
    Positioned(right: 12, bottom: 26, child: Column(children: [
      _BeatAction(icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, value: '$_likes', onTap: _toggleLike), const SizedBox(height: 18),
      _BeatAction(icon: Icons.mode_comment_outlined, value: '$_comments', onTap: _commentsSheet), const SizedBox(height: 18),
      _BeatAction(icon: _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, value: _saved ? 'Saved' : 'Save', onTap: _toggleSave), const SizedBox(height: 18),
      _BeatAction(icon: Icons.share_outlined, value: 'Share', onTap: _share), const SizedBox(height: 18),
      _BeatAction(icon: Icons.currency_rupee_rounded, value: '₹ 🔒', onTap: _openMonetization),
    ])),
  ]);
}
class _BeatAction extends StatelessWidget { final IconData icon; final String value; final VoidCallback onTap; const _BeatAction({required this.icon, required this.value, required this.onTap}); @override Widget build(BuildContext context) => Column(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(22)), child: IconButton(padding: EdgeInsets.zero, onPressed: onTap, icon: Icon(icon, color: Colors.white))), const SizedBox(height: 3), Text(value, style: const TextStyle(color: Colors.white, fontSize: 11))]); }
class _BeatFallback extends StatelessWidget { const _BeatFallback(); @override Widget build(BuildContext context) => Container(color: const Color(0xFF111111), alignment: Alignment.center, child: const Icon(Icons.auto_awesome_rounded, color: Colors.white54, size: 72)); }
