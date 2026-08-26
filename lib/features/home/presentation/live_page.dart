import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});
  @override State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  final _picker = ImagePicker();
  bool _starting = false;

  Future<void> _startLive() async {
    setState(() => _starting = true);
    try {
      final clip = await _picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(hours: 1));
      if (!mounted) return;
      if (clip != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Live camera is ready. MANOX live broadcasting backend is not enabled yet.')));
      }
    } on PlatformException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Camera unavailable: ${e.message ?? 'unknown error'}')));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Live', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.live_tv_rounded, size: 56), const SizedBox(height: 12),
        const Text('Go Live', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6), const Text('Start your creator broadcast from MANOX.', textAlign: TextAlign.center),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: _starting ? null : _startLive, icon: const Icon(Icons.videocam_rounded), label: Text(_starting ? 'Opening camera…' : 'Start Live')),
        const SizedBox(height: 8),
        const Text('Note: camera preview is available, but real-time multi-user streaming requires a live-stream service/backend.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
      ]))),
      const SizedBox(height: 18),
      const Text('Creators', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      ...List.generate(5, (i) => Card(child: ListTile(
        leading: CircleAvatar(child: Text('${i + 1}')),
        title: Text('MANOX Creator ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: const Text('Creator • Continue watching'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push('/search'),
      ))),
    ]),
  );
}
