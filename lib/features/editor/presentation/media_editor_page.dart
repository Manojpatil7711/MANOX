import 'package:flutter/material.dart';

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
  double _brightness = 0;
  double _contrast = 0;
  double _saturation = 0;
  double _rotation = 0;
  double _speed = 1;
  String _filter = 'None';
  String _crop = 'Original';
  final List<String> _history = ['Original'];
  int _historyIndex = 0;

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
    setState(() => _selectedTool = index);
    _showTool(_tools[index].label);
  }

  void _markChanged() {
    setState(() {
      _changed = true;
      final state = 'b:${_brightness.toStringAsFixed(1)}|c:${_contrast.toStringAsFixed(1)}|s:${_saturation.toStringAsFixed(1)}|r:${_rotation.toStringAsFixed(0)}|f:$_filter|crop:$_crop|speed:$_speed';
      if (_historyIndex < _history.length - 1) {
        _history.removeRange(_historyIndex + 1, _history.length);
      }
      _history.add(state);
      _historyIndex = _history.length - 1;
    });
  }

  void _undo() {
    if (_historyIndex == 0) return;
    setState(() => _historyIndex--);
    _restoreHistory(_history[_historyIndex]);
  }

  void _redo() {
    if (_historyIndex >= _history.length - 1) return;
    setState(() => _historyIndex++);
    _restoreHistory(_history[_historyIndex]);
  }

  void _restoreHistory(String value) {
    if (value == 'Original') {
      _brightness = 0;
      _contrast = 0;
      _saturation = 0;
      _rotation = 0;
      _speed = 1;
      _filter = 'None';
      _crop = 'Original';
    }
    setState(() => _changed = _historyIndex > 0);
  }

  void _reset() {
    setState(() {
      _brightness = 0;
      _contrast = 0;
      _saturation = 0;
      _rotation = 0;
      _speed = 1;
      _filter = 'None';
      _crop = 'Original';
      _changed = false;
      _history
        ..clear()
        ..add('Original');
      _historyIndex = 0;
    });
  }

  void _showTool(String label) {
    switch (label) {
      case 'Adjust':
        _showAdjust();
        break;
      case 'Filter':
        _showFilters();
        break;
      case 'Crop':
        _showCrop();
        break;
      case 'Speed':
        _showSpeed();
        break;
      case 'Rotate':
        _showRotate();
        break;
      case 'Text':
        _showText();
        break;
      case 'Sticker':
        _showMessage('Sticker', 'Choose a sticker to place on your media.');
        break;
      case 'Draw':
        _showMessage('Draw', 'Pen, highlighter and eraser are ready for the drawing layer.');
        break;
      case 'Blur':
        _showMessage('Blur', 'Choose an area to blur in the media.');
        break;
      case 'Trim':
        _showMessage('Trim', 'Set the start and end points on the video timeline.');
        break;
      case 'Sound':
        _showMessage('Sound', 'Choose MANOX sound or manage original audio.');
        break;
      case 'Voice':
        _showMessage('Voice', 'Record a voice-over for the video.');
        break;
    }
  }

  void _showAdjust() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => _EditorSheet(
          title: 'Adjust',
          child: Column(
            children: [
              _slider('Brightness', _brightness, (value) {
                setSheet(() => _brightness = value);
                _markChanged();
              }),
              _slider('Contrast', _contrast, (value) {
                setSheet(() => _contrast = value);
                _markChanged();
              }),
              _slider('Saturation', _saturation, (value) {
                setSheet(() => _saturation = value);
                _markChanged();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slider(String title, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        Slider(min: -1, max: 1, value: value, onChanged: onChanged),
      ],
    );
  }

  void _showFilters() {
    const names = ['None', 'Natural', 'Cinema', 'Warm', 'Cool', 'Vintage', 'B&W', 'Vivid'];
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => _EditorSheet(
        title: 'Filter',
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: names.map<Widget>((name) {
            return ChoiceChip(
              label: Text(name),
              selected: _filter == name,
              onSelected: (_) {
                setState(() => _filter = name);
                _markChanged();
                Navigator.pop(sheetContext);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCrop() {
    const names = ['Original', 'Free', '9:16', '4:5', '1:1', '16:9', '4:3'];
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => _EditorSheet(
        title: 'Crop',
        child: Wrap(
          spacing: 8,
          children: names.map<Widget>((name) {
            return ChoiceChip(
              label: Text(name),
              selected: _crop == name,
              onSelected: (_) {
                setState(() => _crop = name);
                _markChanged();
                Navigator.pop(sheetContext);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSpeed() {
    const speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0];
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => _EditorSheet(
        title: 'Speed',
        child: Wrap(
          spacing: 8,
          children: speeds.map<Widget>((value) {
            return ChoiceChip(
              label: Text('${value}x'),
              selected: _speed == value,
              onSelected: (_) {
                setState(() => _speed = value);
                _markChanged();
                Navigator.pop(sheetContext);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showRotate() {
    const degrees = [90, 180, 270];
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => _EditorSheet(
        title: 'Rotate',
        child: Wrap(
          spacing: 8,
          children: degrees.map<Widget>((value) {
            return ElevatedButton(
              onPressed: () {
                setState(() => _rotation = (_rotation + value) % 360);
                _markChanged();
                Navigator.pop(sheetContext);
              },
              child: Text('$value°'),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showText() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _EditorSheet(
        title: 'Text',
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Type your text'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  _markChanged();
                  Navigator.pop(sheetContext);
                }
              },
              child: const Text('ADD TEXT'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String title, String message) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _EditorSheet(
        title: title,
        child: Padding(padding: const EdgeInsets.all(8), child: Text(message)),
      ),
    );
  }

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
            onPressed: _historyIndex > 0 ? _undo : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed: _historyIndex < _history.length - 1 ? _redo : null,
            icon: const Icon(Icons.redo_rounded),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DONE'),
          ),
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
                final isSelected = index == _selectedTool;
                return GestureDetector(
                  onTap: () => _select(index),
                  child: SizedBox(
                    width: 72,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 23,
                          backgroundColor: isSelected
                              ? Colors.white
                              : const Color(0xFF252525),
                          child: Icon(tool.icon,
                              color: isSelected ? Colors.black : Colors.white),
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

class _EditorSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _EditorSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _EditorTool {
  final IconData icon;
  final String label;
  const _EditorTool(this.icon, this.label);
}
