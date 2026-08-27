import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../search/search_service.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Messages')), body: ListView(children: const [ListTile(leading: CircleAvatar(child: Icon(Icons.person_outline)), title: Text('MANOX Chat'), subtitle: Text('Your messages will appear here.'))]));
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Notifications')), body: ListView(children: const [ListTile(leading: Icon(Icons.favorite_outline), title: Text('Notifications'), subtitle: Text('Your MANOX activity will appear here.'))]));
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _service = ManoxSearchService();
  Timer? _debounce;
  List<ManoxSearchResult> _results = [];
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() { _results = []; _error = ''; _loading = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    if (query.length < 2) return;
    setState(() { _loading = true; _error = ''; });
    try {
      final results = await _service.search(query);
      if (!mounted || _controller.text.trim() != query) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted || _controller.text.trim() != query) return;
      setState(() {
        _results = [];
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted && _controller.text.trim() == query) setState(() => _loading = false);
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _controller.clear();
    setState(() { _results = []; _error = ''; _loading = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      titleSpacing: 0,
      title: TextField(
        controller: _controller,
        autofocus: true,
        onChanged: _onQueryChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search people and content',
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _controller.text.isEmpty ? null : IconButton(tooltip: 'Clear search', icon: const Icon(Icons.clear_rounded), onPressed: _clearSearch),
        ),
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error.isNotEmpty
            ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error, textAlign: TextAlign.center)))
            : _controller.text.trim().length < 2
                ? const Center(child: Text('Search MANOX for people, creators and content.'))
                : _results.isEmpty
                    ? const Center(child: Text('No matching people or content found.'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final result = _results[i];
                          return ListTile(
                            leading: CircleAvatar(child: Icon(result.profile ? Icons.person_outline : Icons.article_outlined)),
                            title: Text(result.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text(result.subtitle),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              if (result.profile) {
                                context.push('/profile/${Uri.encodeComponent(result.id)}');
                              } else {
                                Navigator.pop(context, result.id);
                              }
                            },
                          );
                        },
                      ),
  );
}
