import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../data/supabase_post_repository.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});
  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  final _picker = ImagePicker();
  final _repository = SupabasePostRepository();
  bool _starting = false;
  bool _loading = true;
  List<ManoxPost> _creators = const [];

  @override
  void initState() {
    super.initState();
    _loadCreators();
  }

  Future<void> _loadCreators() async {
    try {
      final posts = await _repository.fetchFeed();
      final seen = <String>{};
      final unique = posts
          .where((p) => p.ownerUserId != null && seen.add(p.ownerUserId!))
          .take(20)
          .toList();
      if (mounted) setState(() { _creators = unique; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startLive() async {
    setState(() => _starting = true);
    try {
      final clip = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(hours: 1),
      );
      if (!mounted) return;
      if (clip != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera is ready. Real-time broadcast needs the MANOX streaming backend.')),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera unavailable: ${e.message ?? 'unknown error'}')),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Live', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.live_tv_rounded, size: 56),
                    const SizedBox(height: 12),
                    const Text('Go Live', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    const Text('Start your creator broadcast from MANOX.', textAlign: TextAlign.center),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _starting ? null : _startLive,
                      icon: const Icon(Icons.videocam_rounded),
                      label: Text(_starting ? 'Opening camera…' : 'Start Live'),
                    ),
                    const SizedBox(height: 8),
                    const Text('Camera access is wired. Live multi-user streaming will be enabled when the streaming service is connected.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Creators', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_creators.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Text('No creators available yet.'))
            else
              ..._creators.map(
                (creator) => Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(creator.creatorName.isEmpty ? 'M' : creator.creatorName[0].toUpperCase())),
                    title: Text(creator.creatorName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${creator.handle} • Continue watching'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/profile/${Uri.encodeComponent(creator.ownerUserId!)}'),
                  ),
                ),
              ),
          ],
        ),
      );
}
