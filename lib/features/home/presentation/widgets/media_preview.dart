import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ManoxMediaPreview extends StatefulWidget {
  final String url;
  final double height;
  final BoxFit fit;
  final bool autoPlay;
  final bool loop;
  final bool fullScreenStyle;
  final VoidCallback? onVideoTap;

  const ManoxMediaPreview({
    super.key,
    required this.url,
    this.height = 240,
    this.fit = BoxFit.cover,
    this.autoPlay = false,
    this.loop = true,
    this.fullScreenStyle = false,
    this.onVideoTap,
  });

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
    VideoPlayerController? controller;
    try {
      final uri = Uri.tryParse(widget.url);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        if (mounted) setState(() => _failed = true);
        return;
      }

      controller = VideoPlayerController.networkUrl(uri);
      _controller = controller;
      await controller.initialize();

      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(widget.loop);
      if (widget.autoPlay && mounted) {
        await controller.play();
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
      if (controller != null && _controller == controller) {
        _controller = null;
        await controller.dispose();
      } else {
        await controller?.dispose();
      }
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || !mounted) return;
    try {
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        await controller.play();
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: Text('Video unavailable')),
      );
    }
    if (controller == null || !controller.value.isInitialized) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: widget.onVideoTap ?? _togglePlayback,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: widget.fullScreenStyle
                  ? BorderRadius.zero
                  : BorderRadius.circular(12),
              child: SizedBox.expand(
                child: FittedBox(
                  fit: widget.fit,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            ),
            if (!controller.value.isPlaying && !widget.fullScreenStyle)
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ManoxLocalVideoPreview extends StatefulWidget {
  final String path;
  final double height;

  const ManoxLocalVideoPreview({
    super.key,
    required this.path,
    this.height = 150,
  });

  @override
  State<ManoxLocalVideoPreview> createState() => _ManoxLocalVideoPreviewState();
}

class _ManoxLocalVideoPreviewState extends State<ManoxLocalVideoPreview> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    VideoPlayerController? controller;
    try {
      if (widget.path.trim().isEmpty) return;
      controller = VideoPlayerController.file(File(widget.path));
      _controller = controller;
      await controller.initialize();
      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }
      setState(() {});
    } catch (_) {
      if (controller != null && _controller == controller) {
        _controller = null;
        await controller.dispose();
      } else {
        await controller?.dispose();
      }
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || !mounted) return;
    try {
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        await controller.play();
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        height: widget.height,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.video_file_outlined, size: 42),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: _togglePlayback,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
              if (!controller.value.isPlaying)
                const CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.play_arrow_rounded, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

bool isManoxVideo(String path) {
  final clean = path.toLowerCase().split('?').first;
  return clean.endsWith('.mp4') ||
      clean.endsWith('.mov') ||
      clean.endsWith('.m4v') ||
      clean.endsWith('.webm') ||
      clean.endsWith('.3gp');
}
