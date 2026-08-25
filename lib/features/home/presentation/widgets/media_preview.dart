import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ManoxMediaPreview extends StatefulWidget {
  final String url;
  final double height;
  final BoxFit fit;
  const ManoxMediaPreview({super.key, required this.url, this.height = 240, this.fit = BoxFit.cover});

  @override
  State<ManoxMediaPreview> createState() => _ManoxMediaPreviewState();
}

class _ManoxMediaPreviewState extends State<ManoxMediaPreview> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setLooping(true);
      setState(() {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed) {
      return SizedBox(height: widget.height, child: const Center(child: Text('Video unavailable')));
    }
    if (controller == null || !controller.value.isInitialized) {
      return SizedBox(height: widget.height, child: const Center(child: CircularProgressIndicator()));
    }
    return GestureDetector(
      onTap: () => setState(() => controller.value.isPlaying ? controller.pause() : controller.play()),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox.expand(child: FittedBox(fit: widget.fit, child: SizedBox(width: controller.value.size.width, height: controller.value.size.height, child: VideoPlayer(controller)))),
            ),
            if (!controller.value.isPlaying)
              Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54), padding: const EdgeInsets.all(12), child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34)),
          ],
        ),
      ),
    );
  }
}

bool isManoxVideo(String path) {
  final clean = path.toLowerCase().split('?').first;
  return clean.endsWith('.mp4') || clean.endsWith('.mov') || clean.endsWith('.m4v') || clean.endsWith('.webm') || clean.endsWith('.3gp');
}
