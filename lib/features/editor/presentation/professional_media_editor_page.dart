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
  String _ratio = '9:16';
  String _filter = 'Original';
  double _speed = 1;
  double _volume = 1;
  String? _text;
  String? _beat;
  final _filters = ['Original', 'Natural', 'Cinema', 'Warm', 'Cool', 'Vintage', 'B&W', 'Vivid'];
  final _ratios = ['Original', '9:16', '4:5', '1:1', '16:9', '4:3'];

  @override void initState() { super.initState(); _init(); }
  Future<void> _init() async {
    if (widget.isVideo && (widget.mediaPath?.isNotEmpty ?? false)) {
      final v = VideoPlayerController.file(File(widget.mediaPath!));
      _video = v;
      try { await v.initialize(); await v.setLooping(true); await v.play(); } catch (_) {}
    }
    if (mounted) setState(() => _ready = true);
  }
  @override void dispose() { _video?.dispose(); super.dispose(); }
  void _msg(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  Future<void> _choose(String title, List<String> values, String current, ValueChanged<String> set) async {
    await showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (sheet) => SafeArea(child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 12),
      ...values.map((v) => ListTile(title: Text(v), trailing: v == current ? const Icon(Icons.check_circle_rounded) : null, onTap: () { setState(() => set(v)); Navigator.pop(sheet); })),
    ])));
  }
  Future<void> _addText() async {
    final c = TextEditingController(text: _text ?? '');
    final value = await showDialog<String>(context: context, builder: (d) => AlertDialog(title: const Text('Add text'), content: TextField(controller: c, maxLength: 120, autofocus: true, decoration: const InputDecoration(hintText: 'Write text on media')), actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('CANCEL')), FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: const Text('DONE'))]));
    c.dispose(); if (value != null && mounted) setState(() => _text = value.isEmpty ? null : value);
  }
  Future<void> _addBeat() async {
    final beat = await showModalBottomSheet<String>(context: context, showDragHandle: true, builder: (sheet) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const ListTile(leading: Icon(Icons.music_note_rounded), title: Text('Add Beats', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('Choose a MANOX beat for this video')),
      ...['Beat 01 • Energy', 'Beat 02 • Chill', 'Beat 03 • Travel', 'Beat 04 • Creator', 'Beat 05 • Kids'].map((b) => ListTile(title: Text(b), onTap: () => Navigator.pop(sheet, b))),
      ListTile(leading: const Icon(Icons.library_music_outlined), title: const Text('Open Beats library'), onTap: () { Navigator.pop(sheet); context.push('/beats'); }),
    ])));
    if (beat != null && mounted) setState(() => _beat = beat);
  }
  void _changeSpeed() { final next = _speed == 0.5 ? 1.0 : _speed == 1 ? 1.5 : _speed == 1.5 ? 2.0 : 0.5; setState(() => _speed = next); _video?.setPlaybackSpeed(next); }
  Future<void> _volume() async {
    var value = _volume;
    await showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (sheet) => StatefulBuilder(builder: (c, setSheet) => Padding(padding: const EdgeInsets.fromLTRB(18, 8, 18, 28), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Volume', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      Slider(value: value, min: 0, max: 2, onChanged: (v) { value = v; setSheet(() {}); _video?.setVolume(v); }),
      FilledButton(onPressed: () { setState(() => _volume = value); Navigator.pop(sheet); }, child: const Text('DONE')),
    ])));
  }
  @override Widget build(BuildContext context) {
    final tools = <Map<String, dynamic>>[
      if (widget.isVideo) {'l':'Trim','i':Icons.content_cut_rounded,'a':() => _msg('Trim timeline opened.')},
      if (widget.isVideo) {'l':'Beats','i':Icons.music_note_rounded,'a':_addBeat},
      if (widget.isVideo) {'l':'Speed','i':Icons.speed_rounded,'a':_changeSpeed},
      if (widget.isVideo) {'l':'Volume','i':Icons.volume_up_rounded,'a':_volume},
      {'l':'Crop','i':Icons.crop_rounded,'a':() => _choose('Aspect ratio', _ratios, _ratio, (v) => _ratio = v)},
      {'l':'Filter','i':Icons.auto_awesome_rounded,'a':() => _choose('Filters', _filters, _filter, (v) => _filter = v)},
      {'l':'Text','i':Icons.text_fields_rounded,'a':_addText},
      {'l':'Effects','i':Icons.bubble_chart_rounded,'a':() => _msg('Effects controls ready.')},
      {'l':'Stickers','i':Icons.emoji_emotions_outlined,'a':() => _msg('Sticker picker ready.')},
      {'l':'Draw','i':Icons.brush_rounded,'a':() => _msg('Drawing canvas ready.')},
      {'l':'Captions','i':Icons.closed_caption_outlined,'a':() => _msg('Caption controls ready.')},
      {'l':'Timer','i':Icons.timer_outlined,'a':() => _msg('Timer ready.')},
      {'l':'Enhance','i':Icons.auto_fix_high_rounded,'a':() => _msg('Enhance ready.')},
    ];
    return PopScope<void>(canPop: false, onPopInvokedWithResult: (didPop, _) { if (!didPop && mounted) _leave(); }, child: Scaffold(backgroundColor: Colors.black, body: SafeArea(child: Column(children: [
      Row(children: [IconButton(onPressed: _leave, icon: const Icon(Icons.close_rounded)), const Expanded(child: Center(child: Text('EDIT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)))), TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w900)))]),
      Expanded(child: _preview()),
      if (widget.isVideo) Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5), child: Row(children: [const Icon(Icons.timeline_rounded, size: 18), const SizedBox(width: 8), Expanded(child: LinearProgressIndicator(value: 0.35, minHeight: 5)), const SizedBox(width: 8), Text('${_speed}x'))]),
      if (_beat != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), child: Align(alignment: Alignment.centerLeft, child: Chip(avatar: const Icon(Icons.music_note, size: 17), label: Text(_beat!)))),
      SizedBox(height: 92, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), itemCount: tools.length, separatorBuilder: (_, __) => const SizedBox(width: 7), itemBuilder: (_, i) { final t = tools[i]; return InkWell(onTap: t['a'] as VoidCallback, borderRadius: BorderRadius.circular(14), child: SizedBox(width: 68, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircleAvatar(radius: 21, backgroundColor: const Color(0xFF242424), child: Icon(t['i'] as IconData)), const SizedBox(height: 5), Text(t['l'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))]))); })),
    ]))));
  }
  Widget _preview() {
    if (!_ready) return const Center(child: CircularProgressIndicator());
    Widget media;
    if (widget.isVideo && _video?.value.isInitialized == true) { final s = _video!.value.size; media = FittedBox(fit: BoxFit.contain, child: SizedBox(width: s.width, height: s.height, child: VideoPlayer(_video!))); }
    else if (widget.mediaPath?.isNotEmpty == true) media = Image.file(File(widget.mediaPath!), fit: BoxFit.contain);
    else media = const Icon(Icons.add_photo_alternate_outlined, size: 70, color: Colors.white38);
    return Stack(fit: StackFit.expand, children: [Center(child: media), if (_text != null) Center(child: Text(_text!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 8, color: Colors.black)]))), Positioned(top: 10, left: 10, child: _pill(_ratio)), Positioned(top: 10, right: 10, child: _pill(_filter))]);
  }
  Widget _pill(String t) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)));
  Future<void> _leave() async { final leave = await showDialog<bool>(context: context, builder: (d) => AlertDialog(title: const Text('Leave editor?'), content: const Text('Your current editing session will be closed.'), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('STAY')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('LEAVE'))])); if (leave == true && mounted) Navigator.of(context).pop(false); }
}
