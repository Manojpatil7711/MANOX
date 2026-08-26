import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';

class ProfessionalMediaEditorPage extends StatefulWidget {
  final bool isVideo;
  final String? mediaPath;
  const ProfessionalMediaEditorPage({super.key, required this.isVideo, this.mediaPath});
  @override State<ProfessionalMediaEditorPage> createState() => _ProfessionalMediaEditorPageState();
}

class _ProfessionalMediaEditorPageState extends State<ProfessionalMediaEditorPage> {
  VideoPlayerController? _video;
  bool _ready = false;
  double _volumeLevel = 1;
  double _speed = 1;
  String _ratio = '9:16';
  String _filter = 'Original';
  String? _text;
  String? _beat;
  static const _filters = ['Original','Natural','Cinema','Warm','Cool','Vintage','B&W','Vivid'];
  static const _ratios = ['Original','9:16','4:5','1:1','16:9','4:3'];
  static const _beats = ['Beat 01 • Energy','Beat 02 • Chill','Beat 03 • Travel','Beat 04 • Creator','Beat 05 • Kids'];

  @override void initState() { super.initState(); _init(); }
  Future<void> _init() async {
    if (widget.isVideo && widget.mediaPath?.isNotEmpty == true) {
      final v = VideoPlayerController.file(File(widget.mediaPath!));
      _video = v;
      try { await v.initialize(); await v.setLooping(true); await v.play(); } catch (_) {}
    }
    if (mounted) setState(() => _ready = true);
  }
  @override void dispose() { _video?.dispose(); super.dispose(); }
  void _msg(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _choose(String title, List<String> values, String current, ValueChanged<String> onSelected) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        ...values.map((value) => ListTile(
          title: Text(value),
          trailing: value == current ? const Icon(Icons.check_circle_rounded) : null,
          onTap: () { setState(() => onSelected(value)); Navigator.pop(sheet); },
        )),
      ])),
    );
  }

  Future<void> _addText() async {
    final controller = TextEditingController(text: _text ?? '');
    final value = await showDialog<String>(context: context, builder: (dialog) => AlertDialog(
      title: const Text('Add text'),
      content: TextField(controller: controller, maxLength: 120, autofocus: true, decoration: const InputDecoration(hintText: 'Write text on media')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('CANCEL')),
        FilledButton(onPressed: () => Navigator.pop(dialog, controller.text.trim()), child: const Text('DONE')),
      ],
    ));
    controller.dispose();
    if (value != null && mounted) setState(() => _text = value.isEmpty ? null : value);
  }

  Future<void> _addBeat() async {
    final beat = await showModalBottomSheet<String>(context: context, showDragHandle: true, builder: (sheet) => SafeArea(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ListTile(leading: Icon(Icons.music_note_rounded), title: Text('Add Beats', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('Choose a MANOX beat')),
        ..._beats.map((item) => ListTile(title: Text(item), onTap: () => Navigator.pop(sheet, item))),
        ListTile(leading: const Icon(Icons.library_music_outlined), title: const Text('Open Beats library'), onTap: () { Navigator.pop(sheet); context.push('/beats'); }),
      ],
    )));
    if (beat != null && mounted) setState(() => _beat = beat);
  }

  void _changeSpeed() {
    final next = _speed == 0.5 ? 1.0 : _speed == 1.0 ? 1.5 : _speed == 1.5 ? 2.0 : 0.5;
    setState(() => _speed = next);
    _video?.setPlaybackSpeed(next);
  }

  Future<void> _showVolume() async {
    var value = _volumeLevel;
    await showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (sheet) => StatefulBuilder(builder: (context, setSheet) => Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Volume', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        Slider(value: value, min: 0, max: 2, onChanged: (v) { value = v; setSheet(() {}); _video?.setVolume(v); }),
        FilledButton(onPressed: () { setState(() => _volumeLevel = value); Navigator.pop(sheet); }, child: const Text('DONE')),
      ]),
    )));
  }

  @override Widget build(BuildContext context) {
    final tools = <Map<String, dynamic>>[
      if (widget.isVideo) {'label':'Trim','icon':Icons.content_cut_rounded,'action':() => _msg('Trim timeline ready.')},
      if (widget.isVideo) {'label':'Beats','icon':Icons.music_note_rounded,'action':_addBeat},
      if (widget.isVideo) {'label':'Speed','icon':Icons.speed_rounded,'action':_changeSpeed},
      if (widget.isVideo) {'label':'Volume','icon':Icons.volume_up_rounded,'action':_showVolume},
      {'label':'Crop','icon':Icons.crop_rounded,'action':() => _choose('Aspect ratio', _ratios, _ratio, (v) => _ratio = v)},
      {'label':'Filter','icon':Icons.auto_awesome_rounded,'action':() => _choose('Filters', _filters, _filter, (v) => _filter = v)},
      {'label':'Text','icon':Icons.text_fields_rounded,'action':_addText},
      {'label':'Effects','icon':Icons.bubble_chart_rounded,'action':() => _msg('Effects ready.')},
      {'label':'Stickers','icon':Icons.emoji_emotions_outlined,'action':() => _msg('Sticker picker ready.')},
      {'label':'Draw','icon':Icons.brush_rounded,'action':() => _msg('Drawing canvas ready.')},
      {'label':'Captions','icon':Icons.closed_caption_outlined,'action':() => _msg('Caption controls ready.')},
      {'label':'Timer','icon':Icons.timer_outlined,'action':() => _msg('Timer ready.')},
      {'label':'Enhance','icon':Icons.auto_fix_high_rounded,'action':() => _msg('Enhance ready.')},
    ];
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) { if (!didPop && mounted) _leave(); },
      child: Scaffold(backgroundColor: Colors.black, body: SafeArea(child: Column(children: [
        Row(children: [
          IconButton(onPressed: _leave, icon: const Icon(Icons.close_rounded)),
          const Expanded(child: Center(child: Text('EDIT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w900))),
        ]),
        Expanded(child: _preview()),
        if (widget.isVideo) Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5), child: Row(children: [
          const Icon(Icons.timeline_rounded, size: 18), const SizedBox(width: 8), Expanded(child: LinearProgressIndicator(value: 0.35, minHeight: 5)), const SizedBox(width: 8), Text('${_speed}x'),
        ])),
        if (_beat != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), child: Align(alignment: Alignment.centerLeft, child: Chip(avatar: const Icon(Icons.music_note, size: 17), label: Text(_beat!)))),
        SizedBox(height: 92, child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: tools.length,
          separatorBuilder: (_, __) => const SizedBox(width: 7),
          itemBuilder: (_, index) { final tool = tools[index]; return InkWell(
            onTap: tool['action'] as VoidCallback,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(width: 68, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircleAvatar(radius: 21, backgroundColor: const Color(0xFF242424), child: Icon(tool['icon'] as IconData)),
              const SizedBox(height: 5), Text(tool['label'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            ])),
          ); },
        )),
      ]))),
    );
  }

  Widget _preview() {
    if (!_ready) return const Center(child: CircularProgressIndicator());
    Widget media;
    if (widget.isVideo && _video?.value.isInitialized == true) {
      final size = _video!.value.size;
      media = FittedBox(fit: BoxFit.contain, child: SizedBox(width: size.width, height: size.height, child: VideoPlayer(_video!)));
    } else if (widget.mediaPath?.isNotEmpty == true) {
      media = Image.file(File(widget.mediaPath!), fit: BoxFit.contain);
    } else {
      media = const Icon(Icons.add_photo_alternate_outlined, size: 70, color: Colors.white38);
    }
    return Stack(fit: StackFit.expand, children: [
      Center(child: media),
      if (_text != null) Center(child: Text(_text!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 8, color: Colors.black)]))),
      Positioned(top: 10, left: 10, child: _pill(_ratio)),
      Positioned(top: 10, right: 10, child: _pill(_filter)),
    ]);
  }
  Widget _pill(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)));
  Future<void> _leave() async {
    final leave = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
      title: const Text('Leave editor?'),
      content: const Text('Your current editing session will be closed.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('STAY')), FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('LEAVE'))],
    ));
    if (leave == true && mounted) Navigator.of(context).pop(false);
  }
}
