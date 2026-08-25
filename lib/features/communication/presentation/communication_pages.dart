import 'package:flutter/material.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Messages')),
    body: ListView(children: const [
      ListTile(leading: CircleAvatar(child: Icon(Icons.person_outline)), title: Text('MANOX Chat'), subtitle: Text('Your messages will appear here.')),
    ]),
  );
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: ListView(children: const [
      ListTile(leading: Icon(Icons.favorite_outline), title: Text('Notifications'), subtitle: Text('Your MANOX activity will appear here.')),
    ]),
  );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _categories = const ['Police Bharti', 'MPSC', 'Railway', 'Entertainment', 'BEATS'];
  String _query = '';
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final results = _categories.where((x) => _query.isEmpty || x.toLowerCase().contains(_query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: TextField(controller: _controller, autofocus: true, onChanged: (v) => setState(() => _query = v), decoration: const InputDecoration(hintText: 'Search MANOX', border: InputBorder.none))),
      body: ListView.builder(itemCount: results.length, itemBuilder: (_, i) => ListTile(leading: const Icon(Icons.search), title: Text(results[i]), onTap: () => Navigator.pop(context))),
    );
  }
}
