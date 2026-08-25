import 'package:flutter/material.dart';

/// Unified MANOX media editor foundation.
/// The editor is intentionally content-aware: image and video tools are exposed
/// separately so unsupported controls never clutter the creator experience.
class MediaEditorPage extends StatefulWidget {
  final bool isVideo;
  final String? mediaPath;

  const MediaEditorPage({super.key, required this.isVideo, this.mediaPath});

  @override
  State<MediaEditorPage> createState() => _MediaEditorPageState();
}

class _MediaEditorPageState extends State<MediaEditorPage> {
  int _selectedTool = 0;
  bool _changed = false;

  List<_EditorTool> get _tools => [
        if (widget.isVideo) const _EditorTool(Icons.content_cut_rounded, 'Trim'),
        if (widget.isVideo) const _EditorTool(Icons.speed_rounded, 'Speed'),
        const _EditorTool(Icons.crop_rounded, 'Crop'),
        const _EditorTool(Icons.tune_rounded, 'Adjust'),
        const _EditorTool(Icons.auto_awesome_rounded, 'Filter'),
        const _EditorTool(Icons.text_fields_rounded, 'Text'),
        const _EditorTool(Icons.emoji_emotions_outlined, 'Sticker'),
        const _EditorTool(Icons.brush_rounded, 'Draw'),
        const _EditorTool(Icons.blur_on_rounded, 'Blur'),
        const _EditorTool(Icons.rotate_right_rounded, 'Rotate'),
        if (widget.isVideo) const _EditorTool(Icons.music_note_rounded, 'Sound'),
        if (widget.isVideo) const _EditorTool(Icons.mic_rounded, 'Voice'),
      ];

  void _select(int index) {
    setState(() {
      _selectedTool = index;
      _changed = true;
    });
  }

  void _reset() => setState(() => _changed = false);

  @override
  Widget build(BuildContext context) {
    final tools = _tools;
    final selected = tools[_selectedTool.clamp(0, tools.length - 1)];
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        title: Text(widget.isVideo ? 'Edit Video' : 'Edit Image'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: _changed ? () => setState(() => _changed = false) : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed: _changed ? () {} : null,
            icon: const Icon(Icons.redo_rounded),
          ),
          TextButton(onPressed: () {}, child: const Text('DONE')),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: widget.mediaPath == null
                    ? Icon(
                        widget.isVideo
                            ? Icons.video_library_rounded
                            : Icons.image_rounded,
                        size: 72,
                        color: Colors.white38,
                      )
                    : const Icon(Icons.preview_rounded,
                        size: 72, color: Colors.white38),
              ),
            ),
          ),
          if (_changed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(selected.label,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(onPressed: _reset, child: const Text('RESET')),
                ],
              ),
            ),
          SizedBox(
            height: 92,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: tools.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final tool = tools[index];
                final selected = index == _selectedTool;
                return GestureDetector(
                  onTap: () => _select(index),
                  child: Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 23,
                          backgroundColor:
                              selected ? Colors.white : const Color(0xFF252525),
                          child: Icon(tool.icon,
                              color: selected ? Colors.black : Colors.white),
                        ),
                        const SizedBox(height: 5),
                        Text(tool.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _EditorTool {
  final IconData icon;
  final String label;
  const _EditorTool(this.icon, this.label);
}
