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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('MANOX Kids', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Parent unlock',
            onPressed: () => context.push('/kids-protection'),
            icon: const Icon(Icons.lock_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox.expand(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Text(
                      'Safe learning & fun',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Only parent-approved Kids content is available here.'),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: _items.length,
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 420,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.15,
                      ),
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: item['title'] == 'Beats'
                                ? () => context.push('/beats?mode=kids')
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(item['icon'] as IconData, size: 42),
                                  const SizedBox(height: 12),
                                  Text(
                                    item['title'] as String,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text('Kids safe', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
