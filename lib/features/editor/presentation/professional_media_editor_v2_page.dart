import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';

import '../../home/data/supabase_post_repository.dart';

class ProfessionalMediaEditorV2Page extends StatefulWidget {
  final bool isVideo;
  final String? mediaPath;
  const ProfessionalMediaEditorV2Page({super.key, required this.isVideo, this.mediaPath});
  @override State<ProfessionalMediaEditorV2Page> createState() => _ProfessionalMediaEditorV2PageState();
}

class _ProfessionalMediaEditorV2PageState extends State<ProfessionalMediaEditorV2Page> {
  VideoPlayerController? _video;
  bool _ready = false;
  bool _exporting = false;
  double _start = 0;
  double _end = 1;
  double _volume = 1;
  double _speed = 1;
  String _ratio = '9:16';
  String _filter = 'Original';
  String? _text;
  ManoxPost? _selectedBeat;
  static const _filters = ['Original','Natural','Cinema','Warm','Cool','Vintage','B&W','Vivid'];
  static const _ratios = ['Original','9:16','4:5','1:1','16:9','4:3'];

  @override void initState() { super.initState(); _init(); }
  Future<void> _init() async {
    if (widget.isVideo && widget.mediaPath?.isNotEmpty == true) {
      final v = VideoPlayerController.file(File(widget.mediaPath!));
      _video = v;
      try { await v.initialize(); await v.setLooping(true); _end = v.value.duration.inMilliseconds.toDouble(); if (_end <= 0) _end = 1; await v.play(); } catch (_) {}
    }
    if (mounted) setState(() => _ready = true);
  }
  @override void dispose() { _video?.dispose(); super.dispose(); }

  Future<void> _choose(String title, List<String> values, String current, ValueChanged<String> onSelected) async {
    await showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (sheet) => SafeArea(child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 12),
      ...values.map((value) => ListTile(title: Text(value), trailing: value == current ? const Icon(Icons.check_circle_rounded) : null, onTap: () { setState(() => onSelected(value)); Navigator.pop(sheet); })),
    ])));
  }

  Future<void> _addText() async {
    final controller = TextEditingController(text: _text ?? '');
    final value = await showDialog<String>(context: context, builder: (dialog) => AlertDialog(
      title: const Text('Add text'), content: TextField(controller: controller, maxLength: 120, autofocus: true, decoration: const InputDecoration(hintText: 'Write text on your media')),
      actions: [TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('CANCEL')), FilledButton(onPressed: () => Navigator.pop(dialog, controller.text.trim()), child: const Text('DONE'))],
    ));
    controller.dispose();
    if (value != null && mounted) setState(() => _text = value.isEmpty ? null : value);
  }

  Future<void> _addBeat() async {
    try {
      final beats = await SupabasePostRepository().fetchBeats();
      if (!mounted) return;
      if (beats.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No published MANOX beats are available yet.')));
        return;
      }
      await showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (sheet) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ListTile(leading: Icon(Icons.music_note_rounded), title: Text('Add Beats', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('Choose a published MANOX beat')),
        ...beats.map((beat) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.music_note_rounded)),
          title: Text(beat.text.isNotEmpty ? beat.text : '${beat.creatorName} • Beat'),
          subtitle: Text(beat.handle),
          trailing: _selectedBeat?.id == beat.id ? const Icon(Icons.check_circle_rounded) : null,
          onTap: () { setState(() => _selectedBeat = beat); Navigator.pop(sheet); },
        )),
        if (_selectedBeat != null) ListTile(leading: const Icon(Icons.clear_rounded), title: const Text('Remove selected beat'), onTap: () { setState(() => _selectedBeat = null); Navigator.pop(sheet); }),
        ListTile(leading: const Icon(Icons.library_music_outlined), title: const Text('Open Beats library'), onTap: () { Navigator.pop(sheet); context.push('/beats'); }),
      ])));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load beats: ${e.toString().replaceFirst('Bad state: ', '')}')));
    }
  }

  void _changeSpeed() { final next = _speed == 0.5 ? 1.0 : _speed == 1.0 ? 1.5 : _speed == 1.5 ? 2.0 : 0.5; setState(() => _speed = next); _video?.setPlaybackSpeed(next); }

  Future<void> _showVolume() async {
    var value = _volume;
    await showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (sheet) => StatefulBuilder(builder: (context, setSheet) => Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_selectedBeat == null ? 'Original audio' : 'Beat audio', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        Slider(value: value, min: 0, max: 1, divisions: 20, label: '${(value * 100).round()}%', onChanged: (v) { value = v; setSheet(() {}); _video?.setVolume(v); }),
        FilledButton(onPressed: () { setState(() => _volume = value); Navigator.pop(sheet); }, child: const Text('DONE')),
      ]))));
  }

  String _shell(String value) => "'${value.replaceAll("'", "'\\''")}'";
  String? _videoFilter() { switch (_filter) { case 'B&W': return 'hue=s=0'; case 'Warm': return 'colorbalance=rs=.08:gs=.03:bs=-.03'; case 'Cool': return 'colorbalance=rs=-.03:gs=.02:bs=.08'; case 'Vintage': return 'curves=vintage'; case 'Cinema': return 'eq=contrast=1.08:saturation=1.08:brightness=-.02'; case 'Vivid': return 'eq=contrast=1.12:saturation=1.22'; default: return null; } }
  String? _ratioFilter() { switch (_ratio) { case '9:16': return 'scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920'; case '4:5': return 'scale=1080:1350:force_original_aspect_ratio=increase,crop=1080:1350'; case '1:1': return 'scale=1080:1080:force_original_aspect_ratio=increase,crop=1080:1080'; case '16:9': return 'scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080'; case '4:3': return 'scale=1440:1080:force_original_aspect_ratio=increase,crop=1440:1080'; default: return null; } }

  Future<File> _downloadBeat(String url) async {
    final temp = await getTemporaryDirectory();
    final file = File('${temp.path}/manox_beat_${DateTime.now().millisecondsSinceEpoch}.mp4');
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) throw StateError('Beat download failed.');
      await response.pipe(file.openWrite());
      if (!await file.exists() || await file.length() == 0) throw StateError('Beat file is empty.');
      return file;
    } finally {
      client.close(force: true);
    }
  }

  Future<String?> _render() async {
    final input = widget.mediaPath; final video = _video;
    if (input == null || video == null || !video.value.isInitialized) return null;
    final durationMs = video.value.duration.inMilliseconds;
    if (durationMs <= 0) throw StateError('Video duration is unavailable. Please select the video again.');
    final startMs = _start.clamp(0, durationMs).round();
    final safeMinimumDurationMs = durationMs < 500 ? durationMs : 500;
    final maxStartMs = (durationMs - safeMinimumDurationMs).clamp(0, durationMs).round();
    final boundedStartMs = startMs.clamp(0, maxStartMs).round();
    final requestedEndMs = _end.clamp(boundedStartMs, durationMs).round();
    final endMs = requestedEndMs > boundedStartMs ? requestedEndMs : (boundedStartMs + safeMinimumDurationMs).clamp(0, durationMs).round();
    if (endMs <= boundedStartMs) throw StateError('Selected clip is too short to export.');
    final temp = await getTemporaryDirectory(); final output = '${temp.path}/manox_render_${DateTime.now().millisecondsSinceEpoch}.mp4';
    File? beatFile;
    try {
      final filters = <String>[];
      final ratioFilter = _ratioFilter(); if (ratioFilter != null) filters.add(ratioFilter);
      final videoFilter = _videoFilter(); if (videoFilter != null) filters.add(videoFilter);
      if (_text != null && _text!.trim().isNotEmpty) { final safe = _text!.replaceAll('\\', '\\\\').replaceAll(':', '\\:').replaceAll("'", "\\'"); filters.add("drawtext=fontfile=/system/fonts/Roboto-Regular.ttf:text='$safe':fontcolor=white:fontsize=56:borderw=3:bordercolor=black:x=(w-text_w)/2:y=(h-text_h)/2"); }
      if (_speed != 1) filters.add('setpts=${(1 / _speed).toStringAsFixed(4)}*PTS');
      final vf = filters.isEmpty ? '' : ' -vf ${_shell(filters.join(','))}';
      final audioFilter = _speed == 1 ? 'volume=${_volume.toStringAsFixed(2)}' : 'atempo=${_speed.toStringAsFixed(2)},volume=${_volume.toStringAsFixed(2)}';
      String command;
      if (_selectedBeat != null) {
        final beatPath = _selectedBeat!.imageUrl;
        if (beatPath == null || beatPath.isEmpty) throw StateError('Selected beat has no media source.');
        final beatUrl = await SupabasePostRepository().signedMediaUrl(beatPath);
        if (beatUrl == null || beatUrl.isEmpty) throw StateError('Could not access the selected beat.');
        beatFile = await _downloadBeat(beatUrl);
        command = '-y -ss ${(boundedStartMs / 1000).toStringAsFixed(3)} -i ${_shell(input)} -stream_loop -1 -i ${_shell(beatFile.path)} -t ${((endMs - boundedStartMs) / 1000).toStringAsFixed(3)}$vf -map 0:v:0 -map 1:a:0 -af ${_shell(audioFilter)} -c:v mpeg4 -q:v 3 -c:a aac -b:a 128k -movflags +faststart ${_shell(output)}';
      } else {
        command = '-y -ss ${(boundedStartMs / 1000).toStringAsFixed(3)} -i ${_shell(input)} -t ${((endMs - boundedStartMs) / 1000).toStringAsFixed(3)}$vf -af ${_shell(audioFilter)} -c:v mpeg4 -q:v 3 -c:a aac -b:a 128k -movflags +faststart ${_shell(output)}';
      }
      final session = await FFmpegKit.execute(command); final code = await session.getReturnCode();
      if (ReturnCode.isSuccess(code) && await File(output).exists()) return output;
      throw StateError(_selectedBeat == null ? 'Video render failed. Please try a shorter clip or another format.' : 'Beat export failed. The selected beat may not contain an audio track.');
    } finally {
      if (beatFile != null) { try { await beatFile.delete(); } catch (_) {} }
    }
  }

  Future<void> _done() async {
    if (!widget.isVideo) { if (mounted) Navigator.of(context).pop(true); return; }
    if (_exporting) return; setState(() => _exporting = true);
    String? rendered;
    String? backup;
    try {
      rendered = await _render();
      final original = widget.mediaPath;
      if (rendered == null || original == null) throw StateError('No video selected.');
      final originalFile = File(original);
      final renderedFile = File(rendered);
      final temp = await getTemporaryDirectory();
      backup = '${temp.path}/manox_backup_${DateTime.now().millisecondsSinceEpoch}.mp4';
      if (await originalFile.exists()) await originalFile.copy(backup);
      final bytes = await renderedFile.readAsBytes();
      await originalFile.writeAsBytes(bytes, flush: true);
      try { await renderedFile.delete(); } catch (_) {}
      final backupPath = backup;
      try { await File(backupPath).delete(); } catch (_) {}
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      final backupPath = backup;
      if (backupPath != null && widget.mediaPath != null) {
        try {
          final backupFile = File(backupPath);
          if (await backupFile.exists()) await backupFile.copy(widget.mediaPath!);
          await backupFile.delete();
        } catch (_) {}
      }
      final renderedPath = rendered;
      if (renderedPath != null) { try { await File(renderedPath).delete(); } catch (_) {} }
      if (!mounted) return; setState(() => _exporting = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))));
    }
  }

  Future<void> _leave() async { if (_exporting) return; final leave = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(title: const Text('Leave editor?'), content: const Text('Your current editing session will be closed without exporting.'), actions: [TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('STAY')), FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('LEAVE'))])); if (leave == true && mounted) Navigator.of(context).pop(null); }

  @override Widget build(BuildContext context) {
    final durationMs = _video?.value.isInitialized == true ? _video!.value.duration.inMilliseconds.toDouble() : 1.0;
    return PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) { if (!didPop) _leave(); }, child: Scaffold(backgroundColor: Colors.black, body: SafeArea(child: Column(children: [
      Row(children: [IconButton(onPressed: _leave, icon: const Icon(Icons.close_rounded)), const Expanded(child: Center(child: Text('EDIT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)))), TextButton(onPressed: _exporting ? null : _done, child: _exporting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('DONE', style: TextStyle(fontWeight: FontWeight.w900)))]),
      Expanded(child: _preview()), if (widget.isVideo && durationMs > 1) _timeline(durationMs), if (_exporting) const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: LinearProgressIndicator()), _tools(),
    ]))));
  }

  Widget _timeline(double durationMs) => Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 6), child: Column(children: [Row(children: [const Icon(Icons.content_cut_rounded, size: 18), const SizedBox(width: 8), Text('${_fmt(_start)} – ${_fmt(_end)}'), const Spacer(), Text('${((_end - _start) / 1000).toStringAsFixed(1)}s')]), RangeSlider(min: 0, max: durationMs, values: RangeValues(_start.clamp(0, durationMs - 1), _end.clamp(1, durationMs)), onChanged: _exporting ? null : (values) { setState(() { _start = values.start; _end = values.end; }); _video?.seekTo(Duration(milliseconds: values.start.round())); })]));
  String _fmt(double ms) { final seconds = (ms / 1000).floor(); return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'; }

  Widget _tools() {
    final tools = <({String label, IconData icon, VoidCallback action})>[
      if (widget.isVideo) (label: 'Trim', icon: Icons.content_cut_rounded, action: () => _video?.seekTo(Duration(milliseconds: _start.round()))),
      if (widget.isVideo) (label: _selectedBeat == null ? 'Beats' : 'Beat ✓', icon: Icons.music_note_rounded, action: _addBeat),
      if (widget.isVideo) (label: '${_speed}x', icon: Icons.speed_rounded, action: _changeSpeed),
      if (widget.isVideo) (label: 'Volume', icon: Icons.volume_up_rounded, action: _showVolume),
      (label: 'Crop', icon: Icons.crop_rounded, action: () => _choose('Aspect ratio', _ratios, _ratio, (v) => _ratio = v)),
      (label: 'Filter', icon: Icons.auto_awesome_rounded, action: () => _choose('Filters', _filters, _filter, (v) => _filter = v)),
      (label: 'Text', icon: Icons.text_fields_rounded, action: _addText),
    ];
    return SizedBox(height: 94, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), itemCount: tools.length, separatorBuilder: (_, __) => const SizedBox(width: 7), itemBuilder: (_, index) { final tool = tools[index]; return InkWell(onTap: _exporting ? null : tool.action, borderRadius: BorderRadius.circular(14), child: SizedBox(width: 72, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircleAvatar(radius: 22, backgroundColor: const Color(0xFF242424), child: Icon(tool.icon)), const SizedBox(height: 5), Text(tool.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))]))); }));
  }

  Widget _preview() {
    if (!_ready) return const Center(child: CircularProgressIndicator()); Widget media;
    if (widget.isVideo && _video?.value.isInitialized == true) { final size = _video!.value.size; media = FittedBox(fit: BoxFit.contain, child: SizedBox(width: size.width, height: size.height, child: VideoPlayer(_video!))); }
    else if (widget.mediaPath?.isNotEmpty == true) media = Image.file(File(widget.mediaPath!), fit: BoxFit.contain); else media = const Icon(Icons.add_photo_alternate_outlined, size: 70, color: Colors.white38);
    return Stack(fit: StackFit.expand, children: [Center(child: media), if (_text != null) Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_text!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 8, color: Colors.black)])))), Positioned(top: 10, left: 10, child: _pill(_ratio)), Positioned(top: 10, right: 10, child: _pill(_selectedBeat == null ? _filter : 'BEAT • ${_selectedBeat!.creatorName}'))]);
  }
  Widget _pill(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)));
}
