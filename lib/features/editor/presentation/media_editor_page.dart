import 'package:flutter/material.dart';

class MediaEditorPage extends StatefulWidget {
  final bool isVideo;
  final String? mediaPath;

  const MediaEditorPage({super.key, required this.isVideo, this.mediaPath});

  @override
  State<MediaEditorPage> createState() => _MediaEditorPageState();
}

class _MediaEditorPageState extends State<MediaEditorPage> {
  String _filter = 'None';
  String _crop = 'Original';
  double _brightness = 0;
  double _contrast = 0;
  double _saturation = 0;
  double _speed = 1;
  bool _changed = false;

  static const _filters = ['None', 'Natural', 'Cinema', 'Warm', 'Cool', 'Vintage', 'B&W', 'Vivid'];
  static const _crops = ['Original', '9:16', '4:5', '1:1', '16:9', '4:3'];

  void _changedNow() => setState(() => _changed = true);

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171717),
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, index) {
                    final name = _filters[index];
                    final selected = name == _filter;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _filter = name;
                          _changed = true;
                        });
                        Navigator.pop(sheetContext);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: selected ? Colors.white : Colors.white24, width: selected ? 2 : 1),
                            ),
                            child: Center(child: Icon(name == 'B&W' ? Icons.filter_b_and_w : Icons.auto_awesome_rounded, size: 28)),
                          ),
                          const SizedBox(height: 6),
                          Text(name, style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdjust() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171717),
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Adjust', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                _slider('Brightness', _brightness, (v) { setSheet(() => _brightness = v); _changedNow(); }),
                _slider('Contrast', _contrast, (v) { setSheet(() => _contrast = v); _changedNow(); }),
                _slider('Saturation', _saturation, (v) { setSheet(() => _saturation = v); _changedNow(); }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _slider(String label, double value, ValueChanged<double> onChanged) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      Slider(min: -1, max: 1, value: value, onChanged: onChanged),
    ],
  );

  void _showCrop() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171717),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _crops.map((name) => ChoiceChip(
              label: Text(name),
              selected: name == _crop,
              onSelected: (_) {
                setState(() { _crop = name; _changed = true; });
                Navigator.pop(sheetContext);
              },
            )).toList(),
          ),
        ),
      ),
    );
  }

  void _showText() {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF171717),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Text', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Type text on your media')), 
            const SizedBox(height: 12),
            FilledButton(
              onPressed: controller.text.trim().isEmpty ? null : () { _changedNow(); Navigator.pop(sheetContext); },
              child: const Text('ADD TEXT'),
            ),
          ],
        ),
      ),
    );
  }

  void _tool(String name) {
    switch (name) {
      case 'Filter': _showFilters(); break;
      case 'Adjust': _showAdjust(); break;
      case 'Crop': _showCrop(); break;
      case 'Text': _showText(); break;
      case 'Trim':
      case 'Speed':
      case 'Sound':
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name controls are ready for the next editor step.')));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tools = <String>[if (widget.isVideo) 'Trim', if (widget.isVideo) 'Speed', 'Crop', 'Adjust', 'Filter', 'Text', if (widget.isVideo) 'Sound'];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.isVideo ? 'Edit Video' : 'Edit Photo'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DONE')),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              color: const Color(0xFF050505),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(child: Icon(widget.isVideo ? Icons.play_circle_outline_rounded : Icons.image_rounded, size: 76, color: Colors.white38)),
                  if (_changed)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Text('Filter: $_filter  •  Crop: $_crop', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ),
                ],
              ),
            ),
          ),
          if (widget.isVideo)
            SizedBox(
              height: 54,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [
                  const Icon(Icons.timeline_rounded, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)))),
                  const SizedBox(width: 8),
                  Text('${_speed}x', style: const TextStyle(fontSize: 12)),
                ]),
              ),
            ),
          SizedBox(
            height: 98,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: tools.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) => GestureDetector(
                onTap: () => _tool(tools[index]),
                child: SizedBox(
                  width: 70,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(radius: 23, backgroundColor: const Color(0xFF242424), child: Icon(_icon(tools[index]), color: Colors.white)),
                      const SizedBox(height: 5),
                      Text(tools[index], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  IconData _icon(String name) {
    switch (name) {
      case 'Trim': return Icons.content_cut_rounded;
      case 'Speed': return Icons.speed_rounded;
      case 'Crop': return Icons.crop_rounded;
      case 'Adjust': return Icons.tune_rounded;
      case 'Filter': return Icons.auto_awesome_rounded;
      case 'Text': return Icons.text_fields_rounded;
      case 'Sound': return Icons.music_note_rounded;
      default: return Icons.edit_rounded;
    }
  }
}
