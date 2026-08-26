import 'package:flutter/material.dart';

class EntertainmentPage extends StatelessWidget {
  const EntertainmentPage({super.key});

  static const _categories = ['Movies', 'Serials', 'Web Series'];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Entertainment', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 28), children: [
      const Text('Movies, Serials & Web Series', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      const Text('16:9 screen-first entertainment experience'),
      const SizedBox(height: 14),
      for (final category in _categories) ...[
        Text(category, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) => AspectRatio(
              aspectRatio: 16 / 9,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Stack(fit: StackFit.expand, children: [
                  Container(color: Theme.of(context).colorScheme.surfaceContainerHighest, alignment: Alignment.center, child: const Icon(Icons.play_circle_outline_rounded, size: 48)),
                  Positioned(left: 10, right: 10, bottom: 8, child: Text('$category ${index + 1}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
      const Text('16:9 is used as the native content frame so movies, serials and web-series previews do not appear stretched or vertically cropped.', style: TextStyle(fontSize: 12)),
    ]),
  );
}
