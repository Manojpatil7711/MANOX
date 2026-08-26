import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class KidsHomePage extends StatelessWidget {
  const KidsHomePage({super.key});
  static const _items = <Map<String, dynamic>>[
    {'title': 'Science Experiments', 'icon': Icons.science_outlined},
    {'title': 'History', 'icon': Icons.account_balance_outlined},
    {'title': 'Geography Knowledge', 'icon': Icons.public_outlined},
    {'title': 'GK', 'icon': Icons.menu_book_outlined},
    {'title': 'Cartoon', 'icon': Icons.smart_toy_outlined},
    {'title': 'Beats', 'icon': Icons.music_note_outlined},
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MANOX Kids', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: () => context.push('/kids-protection'), icon: const Icon(Icons.lock_rounded))]),
    body: GridView.builder(
      padding: const EdgeInsets.all(16), itemCount: _items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05),
      itemBuilder: (_, i) { final x = _items[i]; return Card(child: InkWell(borderRadius: BorderRadius.circular(12), onTap: () { if (x['title'] == 'Beats') context.push('/beats'); }, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(x['icon'] as IconData, size: 42), const SizedBox(height: 12), Text(x['title'] as String, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), const Icon(Icons.lock_outline_rounded, size: 16)]))); },
    ),
  );
}
