import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../search/search_service.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});
  @override State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _controller = TextEditingController();
  final _messages = <String>['Welcome to MANOX Chat 👋', 'Messaging is ready.'];
  bool _emojiOpen = false;
  static const _emojis = ['😀','😂','😍','🥰','😎','🤔','🔥','❤️','👏','🙏','🎉','👍','👎','💯','✨','🚀','😢','😮','😡','🤝','💪','🌟','📸','🎥','🎵','😊','🤣','😘','🥳','🙌'];

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() { _messages.add(text); _controller.clear(); _emojiOpen = false; });
  }

  void _addEmoji(String emoji) { _controller.text += emoji; _controller.selection = TextSelection.collapsed(offset: _controller.text.length); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Messages'), actions: [IconButton(tooltip: 'New message', onPressed: () => _showNewMessage(context), icon: const Icon(Icons.edit_rounded))]),
    body: Column(children: [
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: _messages.length, itemBuilder: (_, i) => Align(alignment: i.isEven ? Alignment.centerLeft : Alignment.centerRight, child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: i.isEven ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.primaryContainer), child: Text(_messages[i]))))),
      if (_emojiOpen) Container(height: 220, padding: const EdgeInsets.all(10), child: GridView.builder(itemCount: _emojis.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8), itemBuilder: (_, i) => InkWell(onTap: () => _addEmoji(_emojis[i]), child: Center(child: Text(_emojis[i], style: const TextStyle(fontSize: 25))))),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(8, 6, 8, 8), child: Row(children: [IconButton(tooltip: 'Emoji', onPressed: () => setState(() => _emojiOpen = !_emojiOpen), icon: const Icon(Icons.emoji_emotions_outlined)), Expanded(child: TextField(controller: _controller, textInputAction: TextInputAction.send, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'Message…', border: OutlineInputBorder()))), const SizedBox(width: 6), IconButton(tooltip: 'Send', onPressed: _send, icon: const Icon(Icons.send_rounded))]))),
    ]),
  );

  Future<void> _showNewMessage(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog<void>(context: context, builder: (dialog) => AlertDialog(title: const Text('New message'), content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Username or profile')), actions: [TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('CANCEL')), FilledButton(onPressed: () { Navigator.pop(dialog); if (controller.text.trim().isNotEmpty) setState(() => _messages.add('Chat with ${controller.text.trim()}')); }, child: const Text('START CHAT'))]));
    controller.dispose();
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Notifications')), body: ListView(children: const [ListTile(leading: Icon(Icons.favorite_outline), title: Text('Notifications'), subtitle: Text('Your MANOX activity will appear here.'))]));
}

class SearchPage extends StatefulWidget { const SearchPage({super.key}); @override State<SearchPage> createState() => _SearchPageState(); }
class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController(); final _service = ManoxSearchService(); Timer? _debounce; List<ManoxSearchResult> _results = []; bool _loading = false; String _error = '';
  @override void dispose() { _debounce?.cancel(); _controller.dispose(); super.dispose(); }
  void _onQueryChanged(String value) { setState(() {}); _debounce?.cancel(); final query = value.trim(); if (query.length < 2) { setState(() { _results = []; _error = ''; _loading = false; }); return; } _debounce = Timer(const Duration(milliseconds: 350), () => _search(query)); }
  Future<void> _search(String value) async { final query = value.trim(); if (query.length < 2) return; setState(() { _loading = true; _error = ''; }); try { final results = await _service.search(query); if (!mounted || _controller.text.trim() != query) return; setState(() => _results = results); } catch (e) { if (!mounted || _controller.text.trim() != query) return; setState(() { _results = []; _error = e.toString().replaceFirst('Exception: ', ''); }); } finally { if (mounted && _controller.text.trim() == query) setState(() => _loading = false); } }
  void _clearSearch() { _debounce?.cancel(); _controller.clear(); setState(() { _results = []; _error = ''; _loading = false; }); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(titleSpacing: 0, title: TextField(controller: _controller, autofocus: true, onChanged: _onQueryChanged, textInputAction: TextInputAction.search, decoration: InputDecoration(hintText: 'Search people and content', border: InputBorder.none, prefixIcon: const Icon(Icons.search_rounded), suffixIcon: _controller.text.isEmpty ? null : IconButton(tooltip: 'Clear search', icon: const Icon(Icons.clear_rounded), onPressed: _clearSearch)))), body: _loading ? const Center(child: CircularProgressIndicator()) : _error.isNotEmpty ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error, textAlign: TextAlign.center))) : _controller.text.trim().length < 2 ? const Center(child: Text('Search MANOX for people, creators and content.')) : _results.isEmpty ? const Center(child: Text('No matching people or content found.')) : ListView.separated(padding: const EdgeInsets.symmetric(vertical: 8), itemCount: _results.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (_, i) { final result = _results[i]; return ListTile(leading: CircleAvatar(child: Icon(result.profile ? Icons.person_outline : Icons.article_outlined)), title: Text(result.title, maxLines: 2, overflow: TextOverflow.ellipsis), subtitle: Text(result.subtitle), trailing: const Icon(Icons.chevron_right_rounded), onTap: () { if (result.profile) { context.push('/profile/${Uri.encodeComponent(result.id)}'); } else { Navigator.pop(context, result.id); } }); }));
}
