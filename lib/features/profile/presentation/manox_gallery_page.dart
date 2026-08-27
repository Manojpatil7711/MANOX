import 'package:flutter/material.dart';
import 'package:manox/features/home/data/supabase_post_repository.dart';

/// Independent MANOX profile gallery: POSTS, SAVED and BEATS.
/// Saved items remain private to the signed-in user through the repository.
class ManoxGalleryPage extends StatefulWidget {
  const ManoxGalleryPage({super.key});

  @override
  State<ManoxGalleryPage> createState() => _ManoxGalleryPageState();
}

class _ManoxGalleryPageState extends State<ManoxGalleryPage> {
  final SupabasePostRepository _repository = SupabasePostRepository();
  int _tab = 0;
  bool _loading = true;
  String? _error;
  List<ManoxPost> _posts = <ManoxPost>[];
  List<ManoxPost> _saved = <ManoxPost>[];
  List<ManoxPost> _beats = <ManoxPost>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await _repository.fetchMyPosts();
      final savedItems = await _repository.fetchSavedItems();
      final feed = await _repository.fetchFeed();
      final savedIds = savedItems.map((item) => item.contentId).toSet();
      final saved = feed.where((post) => savedIds.contains(post.id)).toList();
      final beats = posts.where((post) => post.contentType == 'video').toList();
      if (!mounted) return;
      setState(() {
        _posts = posts.where((post) => post.contentType != 'video').toList();
        _saved = saved;
        _beats = beats;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<ManoxPost> get _items => switch (_tab) {
        0 => _posts,
        1 => _saved,
        _ => _beats,
      };

  String get _emptyMessage => switch (_tab) {
        0 => 'Your posts will appear here.',
        1 => 'Saved content is private to you.',
        _ => 'Your BEATS will appear here.',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MANOX GALLERY'),
        actions: <Widget>[
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: <Widget>[
                  _tabButton(0, Icons.grid_view_rounded, 'POSTS'),
                  _tabButton(1, Icons.bookmark_border_rounded, 'SAVED'),
                  _tabButton(2, Icons.play_circle_outline_rounded, 'BEATS'),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _errorView()
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: _items.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: <Widget>[
                                    SizedBox(height: MediaQuery.sizeOf(context).height * .25),
                                    Center(child: Text(_emptyMessage)),
                                  ],
                                )
                              : GridView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(2),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 2,
                                    mainAxisSpacing: 2,
                                  ),
                                  itemCount: _items.length,
                                  itemBuilder: (context, index) => _tile(_items[index]),
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(int index, IconData icon, String label) {
    final selected = _tab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: <Widget>[
              Icon(icon, size: 21, color: selected ? Theme.of(context).colorScheme.primary : null),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w600, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(ManoxPost post) {
    final image = post.imageUrl;
    return InkWell(
      onTap: () => _open(post),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (image != null && image.isNotEmpty)
            Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback(post))
          else
            _fallback(post),
          if (post.contentType == 'video')
            const Align(
              alignment: Alignment.center,
              child: Icon(Icons.play_circle_fill_rounded, size: 38, color: Colors.white),
            ),
          if (_tab == 1)
            const Positioned(
              right: 6,
              top: 6,
              child: Icon(Icons.bookmark_rounded, size: 18, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _fallback(ManoxPost post) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Text(post.text.isEmpty ? 'MANOX' : post.text, maxLines: 4, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
      );

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.cloud_off_rounded, size: 44),
              const SizedBox(height: 10),
              const Text('Gallery could not load.'),
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('TRY AGAIN')),
            ],
          ),
        ),
      );

  Future<void> _open(ManoxPost post) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(post.contentType == 'video' ? 'BEAT' : 'POST'),
                subtitle: Text(post.text.isEmpty ? 'MANOX content' : post.text, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(sheetContext).pop(),
                icon: const Icon(Icons.check_rounded),
                label: const Text('OPEN IN MANOX VIEWER'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
