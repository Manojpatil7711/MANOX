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
  String? _videoError;
  double _start = 0;
  double _end = 1;
  double _volume = 1;
  double _speed = 1;
  String _ratio = '9:16';
  String _filter = 'Original';
  String? _text;
  String _textPreset = 'Bold';
  String _textColor = 'white';
  String _textPosition = 'Center';
  double _textSize = 56;
  String _mask = 'None';
  bool _keyframes = false;
  final List<String> _stickers = <String>[];
  ManoxPost? _selectedBeat;
  static const _filters = ['Original','Natural','Cinema','Warm','Cool','Vintage','B&W','Vivid','Golden Hour','Moody','Fade','Matte','Dream','Noir','Sepia','Arctic','Sunset','Rose','Emerald','Cyberpunk','Film Grain','Soft Glow','High Contrast','Pastel','Dramatic','Retro'];
  static const _textPresets = ['Bold','Classic','Outline','Neon','Shadow','Typewriter','Elegant','Impact','Bubble','Minimal','Glitch','Caption'];
  static const _textColors = ['white','yellow','black','red','lime','cyan','magenta','orange','deepskyblue','hotpink'];
  static const _stickerPacks = ['🔥','✨','❤️','💯','😂','😍','🥹','😎','👑','⚡','💥','🌈','⭐','🎯','🚀','💫','🫶','👏','💖','🤍','🖤','🎉','🌟','💀','👀','📍','🎵','💬','☁️','🌸','🍀','🦋','🐼','🐸','🍓','☀️','🌙','🎮','🏆','💎'];
  static const _ratios = ['Original','9:16','4:5','1:1','16:9','4:3'];

  @override void initState() { super.initState(); _init(); }
  Future<void> _init() async {
    if (widget.isVideo && widget.mediaPath?.isNotEmpty == true) {
      final v = VideoPlayerController.file(File(widget.mediaPath!));
      _video = v;
      try {
        await v.initialize();
        await v.setLooping(true);
        _end = v.value.duration.inMilliseconds.toDouble();
        if (_end <= 0) _end = 1;
        await v.play();
      } catch (error) {
        _videoError = 'This video could not be previewed. Try another MP4/MOV file or post the original video.';
      }
    }
    if (mounted) setState(() => _ready = true);
  }
  @override void dispose() { _video?.dispose(); super.dispose(); }

  Future<void> _addText() async {
    final controller = TextEditingController(text: _text ?? '');
    final value = await showDialog<String>(context: context, builder: (dialog) => AlertDialog(
      title: const Text('Add text overlay'),
      content: TextField(controller: controller, maxLength: 120, autofocus: true, decoration: const InputDecoration(hintText: 'Type a title, caption or hook')),
      actions: [TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('CANCEL')), FilledButton(onPressed: () => Navigator.pop(dialog, controller.text.trim()), child: const Text('STYLE TEXT'))],
    ));
    controller.dispose();
    if (value == null || !mounted) return;
    setState(() => _text = value.isEmpty ? null : value);
    if (value.isNotEmpty) await _showTextStyles();
  }

  Future<void> _showTextStyles() async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: const Color(0xFF171717), builder: (sheet) => StatefulBuilder(builder: (context, setSheet) => SafeArea(child: Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(sheet).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text('Text studio', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4), const Text('12 presets • 10 colours • size • placement'),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: _textPresets.map((preset) => ChoiceChip(label: Text(preset), selected: _textPreset == preset, onSelected: (_) { setState(() => _textPreset = preset); setSheet(() {}); })).toList()),
        const SizedBox(height: 16), const Text('Text colour', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8), Wrap(spacing: 10, runSpacing: 10, children: _textColors.map((color) => InkWell(onTap: () { setState(() => _textColor = color); setSheet(() {}); }, child: Container(width: 32, height: 32, decoration: BoxDecoration(color: _previewTextColor(color), shape: BoxShape.circle, border: Border.all(color: _textColor == color ? Colors.white : Colors.white24, width: _textColor == color ? 3 : 1))))).toList()),
        const SizedBox(height: 16), Row(children: [const Text('Text size', style: TextStyle(fontWeight: FontWeight.w800)), const Spacer(), Text('${_textSize.round()} px')]),
        Slider(min: 24, max: 96, divisions: 18, value: _textSize, onChanged: (v) { setState(() => _textSize = v); setSheet(() {}); }),
        const SizedBox(height: 8), const Text('Placement', style: TextStyle(fontWeight: FontWeight.w800)),
        Wrap(spacing: 8, children: ['Top','Center','Bottom'].map((pos) => ChoiceChip(label: Text(pos), selected: _textPosition == pos, onSelected: (_) { setState(() => _textPosition = pos); setSheet(() {}); })).toList()),
        const SizedBox(height: 14), Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: () => Navigator.pop(sheet), child: const Text('APPLY TEXT STYLE'))),
      ])),
    ))));
  }

  Color _previewTextColor(String name) { switch (name) { case 'yellow': return Colors.yellow; case 'black': return Colors.black; case 'red': return Colors.red; case 'lime': return Colors.lime; case 'cyan': return Colors.cyan; case 'magenta': return Colors.purpleAccent; case 'orange': return Colors.orange; case 'deepskyblue': return Colors.lightBlueAccent; case 'hotpink': return Colors.pinkAccent; default: return Colors.white; } }
  FontWeight _previewTextWeight() => {'Classic','Elegant','Minimal'}.contains(_textPreset) ? FontWeight.w500 : FontWeight.w900;
  
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

  Future<void> _addSticker() async {
    await showModalBottomSheet<void>(
      context: context, showDragHandle: true, isScrollControlled: true,
      backgroundColor: const Color(0xFF171717),
      builder: (sheet) => SafeArea(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Free sticker & elements pack', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('40 built-in emoji stickers • no paid pack or API required'),
          const SizedBox(height: 14),
          SizedBox(height: 230, child: GridView.count(crossAxisCount: 6, children: _stickerPacks.map((emoji) => IconButton(
            tooltip: 'Add $emoji',
            onPressed: () { setState(() => _stickers.add(emoji)); Navigator.pop(sheet); },
            icon: Text(emoji, style: const TextStyle(fontSize: 27)),
          )).toList())),
          if (_stickers.isNotEmpty) TextButton.icon(
            onPressed: () { setState(() => _stickers.clear()); Navigator.pop(sheet); },
            icon: const Icon(Icons.delete_outline_rounded), label: const Text('Clear all stickers'),
          ),
        ]),
      )),
    );
  }

  Future<void> _showOverlayControls() async {
    await showModalBottomSheet<void>(
      context: context, showDragHandle: true, backgroundColor: const Color(0xFF171717),
      builder: (sheet) => SafeArea(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Overlay & keyframe studio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Layer your title and stickers; keyframe motion is free.'),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Animate text (keyframe-style motion)'), subtitle: const Text('Adds a smooth vertical motion curve during export'), value: _keyframes, onChanged: (value) { setState(() => _keyframes = value); Navigator.pop(sheet); }),
          const SizedBox(height: 8),
          const Text('Mask / cinematic treatment', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: ['None','Cinematic bars','Vignette','Letterbox'].map((value) => ChoiceChip(
            label: Text(value), selected: _mask == value,
            onSelected: (_) { setState(() => _mask = value); Navigator.pop(sheet); },
          )).toList()),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: () { Navigator.pop(sheet); _addSticker(); }, icon: const Icon(Icons.emoji_emotions_outlined), label: const Text('Add free sticker')),
        ]),
      )),
    );
  }

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
  String? _videoFilter() { switch (_filter) {
    case 'Natural': return 'eq=contrast=1.02:saturation=1.04:brightness=.01';
    case 'B&W': case 'Noir': return 'hue=s=0,eq=contrast=1.18';
    case 'Warm': case 'Golden Hour': return 'colorbalance=rs=.10:gs=.04:bs=-.05,eq=saturation=1.08';
    case 'Cool': case 'Arctic': return 'colorbalance=rs=-.04:gs=.02:bs=.10';
    case 'Vintage': case 'Retro': return 'curves=vintage,eq=saturation=.82';
    case 'Cinema': case 'Dramatic': return 'eq=contrast=1.12:saturation=1.08:brightness=-.025';
    case 'Vivid': return 'eq=contrast=1.12:saturation=1.22';
    case 'Moody': return 'eq=contrast=1.16:saturation=.82:brightness=-.04';
    case 'Fade': return 'eq=contrast=.86:brightness=.04:saturation=.88';
    case 'Matte': return 'curves=all=0/0.08 0.25/0.28 0.75/0.78 1/0.94';
    case 'Dream': case 'Soft Glow': return 'gblur=sigma=0.35,eq=brightness=.025:saturation=1.08';
    case 'Sepia': return 'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131';
    case 'Sunset': return 'colorbalance=rs=.12:gs=.015:bs=-.06';
    case 'Rose': return 'colorbalance=rs=.09:gs=-.02:bs=.025';
    case 'Emerald': return 'colorbalance=rs=-.025:gs=.08:bs=-.015';
    case 'Cyberpunk': return 'colorbalance=rs=.08:gs=-.04:bs=.12,eq=saturation=1.3';
    case 'Film Grain': return 'noise=alls=12:allf=t+u';
    case 'High Contrast': return 'eq=contrast=1.35:saturation=1.1';
    case 'Pastel': return 'eq=contrast=.88:saturation=.78:brightness=.04';
    case 'Original': return null;
    default: return 'eq=contrast=1.08:saturation=1.08:brightness=-.02';
  } }
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
      if (_text != null && _text!.trim().isNotEmpty) {
        final safe = _text!.replaceAll('\\\\', '\\\\\\\\').replaceAll(':', '\\:').replaceAll("'", "\\'");
        final baseY = _textPosition == 'Top' ? 'h*0.12' : (_textPosition == 'Bottom' ? 'h-text_h-h*0.12' : '(h-text_h)/2');
        final y = _keyframes ? '$baseY+abs(sin(t*2))*h*0.18' : baseY;
        final border = _textPreset == 'Outline' || _textPreset == 'Neon' ? 5 : 3;
        final shadow = _textPreset == 'Shadow' || _textPreset == 'Glitch' ? ':shadowcolor=black:shadowx=4:shadowy=4' : '';
        filters.add("drawtext=fontfile=/system/fonts/Roboto-Regular.ttf:text='$safe':fontcolor=$_textColor:fontsize=${_textSize.round()}:borderw=$border:bordercolor=${_textPreset == 'Neon' ? _textColor : 'black'}$shadow:x=(w-text_w)/2:y=$y");
      }
      for (var i = 0; i < _stickers.length; i++) {
        final sticker = _stickers[i].replaceAll("'", '');
        final x = i.isEven ? 'w*0.12' : 'w-text_w-w*0.12';
        final y = 'h*${0.18 + (i % 4) * 0.14}';
        filters.add("drawtext=fontfile=/system/fonts/Roboto-Regular.ttf:text='$sticker':fontsize=72:fontcolor=white:borderw=2:bordercolor=black:x=$x:y=$y");
      }
      if (_mask == 'Vignette') filters.add('vignette=PI/4');
      if (_mask == 'Cinematic bars' || _mask == 'Letterbox') {
        filters.add('drawbox=x=0:y=0:w=iw:h=ih*0.10:color=black@1:t=fill');
        filters.add('drawbox=x=0:y=ih*0.90:w=iw:h=ih*0.10:color=black@1:t=fill');
      }
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

  Future<String?> _renderPhoto() async {
    final input = widget.mediaPath;
    if (input == null || input.isEmpty || !await File(input).exists()) return null;
    final temp = await getTemporaryDirectory();
    final extension = input.split('.').last.toLowerCase();
    final safeExtension = <String>{'jpg','jpeg','png','webp'}.contains(extension) ? extension : 'jpg';
    final output = '${temp.path}/manox_photo_render_${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
    final filters = <String>[];
    final ratioFilter = _ratioFilter();
    if (ratioFilter != null) filters.add(ratioFilter);
    final photoFilter = _videoFilter();
    if (photoFilter != null) filters.add(photoFilter);
    if (_text != null && _text!.trim().isNotEmpty) {
      final safe = _text!.replaceAll('\\\\', '\\\\\\\\').replaceAll(':', '\\\\:').replaceAll("'", "\\\\'");
      final baseY = _textPosition == 'Top' ? 'h*0.12' : (_textPosition == 'Bottom' ? 'h-text_h-h*0.12' : '(h-text_h)/2');
      final y = _keyframes ? '$baseY+abs(sin(t*2))*h*0.18' : baseY;
      filters.add("drawtext=fontfile=/system/fonts/Roboto-Regular.ttf:text='$safe':fontcolor=$_textColor:fontsize=${_textSize.round()}:borderw=3:bordercolor=black:x=(w-text_w)/2:y=$y");
    }
    for (var i = 0; i < _stickers.length; i++) {
      final sticker = _stickers[i].replaceAll("'", '');
      filters.add("drawtext=fontfile=/system/fonts/Roboto-Regular.ttf:text='$sticker':fontsize=72:fontcolor=white:borderw=2:bordercolor=black:x=w*0.12:y=h*${0.18 + (i % 4) * 0.14}");
    }
    if (_mask == 'Vignette') filters.add('vignette=PI/4');
    if (_mask == 'Cinematic bars' || _mask == 'Letterbox') {
      filters.add('drawbox=x=0:y=0:w=iw:h=ih*0.10:color=black@1:t=fill');
      filters.add('drawbox=x=0:y=ih*0.90:w=iw:h=ih*0.10:color=black@1:t=fill');
    }
    final vf = filters.isEmpty ? '' : ' -vf ${_shell(filters.join(','))}';
    final command = '-y -i ${_shell(input)}$vf -frames:v 1 -q:v 2 ${_shell(output)}';
    final session = await FFmpegKit.execute(command);
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code) || !await File(output).exists()) throw StateError('Photo export failed. Please try another image.');
    return output;
  }

  Future<void> _done() async {
    if (_exporting) return;
    if (!widget.isVideo) {
      setState(() => _exporting = true);
      String? rendered;
      try {
        rendered = await _renderPhoto();
        if (rendered == null || widget.mediaPath == null) throw StateError('No photo selected.');
        await File(widget.mediaPath!).writeAsBytes(await File(rendered).readAsBytes(), flush: true);
        try { await File(rendered).delete(); } catch (_) {}
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        if (rendered != null) { try { await File(rendered).delete(); } catch (_) {} }
        if (!mounted) return;
        setState(() => _exporting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))));
      }
      return;
    }
    setState(() => _exporting = true);
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

  Future<void> _openToolSheet(String label, VoidCallback action) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF171717),
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              if (label == 'Trim' && widget.isVideo)
                Column(children: [
                  Row(children: [const Icon(Icons.content_cut_rounded, size: 18), const SizedBox(width: 8), Text('${_fmt(_start)} – ${_fmt(_end)}'), const Spacer(), Text('${((_end - _start) / 1000).toStringAsFixed(1)}s')]),
                  RangeSlider(
                    min: 0,
                    max: _video?.value.duration.inMilliseconds.toDouble() ?? 1,
                    values: RangeValues(
                      _start.clamp(0, (_video?.value.duration.inMilliseconds.toDouble() ?? 1) - 1),
                      _end.clamp(1, _video?.value.duration.inMilliseconds.toDouble() ?? 1),
                    ),
                    onChanged: _exporting ? null : (values) {
                      setState(() { _start = values.start; _end = values.end; });
                      _video?.seekTo(Duration(milliseconds: values.start.round()));
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: () => Navigator.pop(sheet), child: const Text('DONE'))),
                ])
              else if (label == 'Filter')
                SizedBox(height: 320, child: SingleChildScrollView(child: Wrap(spacing: 8, runSpacing: 8, children: _filters.map((value) => ChoiceChip(
                  label: Text(value), selected: _filter == value,
                  onSelected: (_) { setState(() => _filter = value); Navigator.pop(sheet); },
                )).toList())))
              else if (label == 'Crop')
                Wrap(spacing: 8, runSpacing: 8, children: _ratios.map((value) => ChoiceChip(
                  label: Text(value),
                  selected: _ratio == value,
                  onSelected: (_) { setState(() => _ratio = value); Navigator.pop(sheet); },
                )).toList())
              else if (label == 'Speed')
                Wrap(spacing: 8, children: [0.5, 1.0, 1.5, 2.0].map((value) => ChoiceChip(
                  label: Text('${value}x'),
                  selected: _speed == value,
                  onSelected: (_) { setState(() => _speed = value); _video?.setPlaybackSpeed(value); Navigator.pop(sheet); },
                )).toList())
              else
                FilledButton.icon(onPressed: () { Navigator.pop(sheet); action(); }, icon: const Icon(Icons.check_rounded), label: const Text('APPLY')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tools() {
    final tools = <({String label, IconData icon, VoidCallback action})>[
      if (widget.isVideo) (label: 'Trim', icon: Icons.content_cut_rounded, action: () => _video?.seekTo(Duration(milliseconds: _start.round()))),
      if (widget.isVideo) (label: _selectedBeat == null ? 'Beats' : 'Beat ✓', icon: Icons.music_note_rounded, action: _addBeat),
      if (widget.isVideo) (label: 'Speed', icon: Icons.speed_rounded, action: () {}),
      if (widget.isVideo) (label: 'Volume', icon: Icons.volume_up_rounded, action: _showVolume),
      (label: 'Crop', icon: Icons.crop_rounded, action: () {}),
      (label: 'Filter', icon: Icons.auto_awesome_rounded, action: () {}),
      (label: 'Text', icon: Icons.text_fields_rounded, action: _addText),
      (label: 'Overlay', icon: Icons.layers_rounded, action: _showOverlayControls),
      (label: 'Mask', icon: Icons.crop_free_rounded, action: _showOverlayControls),
      (label: 'Stickers', icon: Icons.emoji_emotions_rounded, action: _addSticker),
    ];
    return Material(
      color: const Color(0xFF111111),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            itemCount: tools.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final tool = tools[index];
              return InkWell(
                onTap: _exporting ? null : () { if (['Overlay','Mask','Stickers'].contains(tool.label)) { tool.action(); } else { _openToolSheet(tool.label, tool.action); } },
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 76,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    CircleAvatar(radius: 23, backgroundColor: const Color(0xFF242424), child: Icon(tool.icon)),
                    const SizedBox(height: 5),
                    Text(tool.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  ]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  double _previewAspectRatio() { switch (_ratio) { case '9:16': return 9 / 16; case '4:5': return 4 / 5; case '1:1': return 1; case '16:9': return 16 / 9; case '4:3': return 4 / 3; default: return 9 / 16; } }

  ColorFilter? _previewColorFilter() { switch (_filter) {
    case 'Natural': return const ColorFilter.matrix(<double>[1.02,0,0,0,2, 0,1.02,0,0,2, 0,0,1.02,0,2, 0,0,0,1,0]);
    case 'B&W': case 'Noir': return const ColorFilter.matrix(<double>[.2126,.7152,.0722,0,0, .2126,.7152,.0722,0,0, .2126,.7152,.0722,0,0, 0,0,0,1,0]);
    case 'Warm': case 'Golden Hour': case 'Sunset': return const ColorFilter.matrix(<double>[1.05,0,0,0,4, 0,1.02,0,0,2, 0,0,.96,0,-2, 0,0,0,1,0]);
    case 'Cool': case 'Arctic': return const ColorFilter.matrix(<double>[.96,0,0,0,-2, 0,1.02,0,0,2, 0,0,1.06,0,4, 0,0,0,1,0]);
    case 'Vivid': case 'Cyberpunk': case 'High Contrast': return const ColorFilter.matrix(<double>[1.12,-.06,-.06,0,0, -.06,1.12,-.06,0,0, -.06,-.06,1.12,0,0, 0,0,0,1,0]);
    case 'Sepia': case 'Vintage': case 'Retro': return const ColorFilter.matrix(<double>[.393,.769,.189,0,0, .349,.686,.168,0,0, .272,.534,.131,0,0, 0,0,0,1,0]);
    default: return null;
  } }

  Widget _preview() {
    if (!_ready) return const Center(child: CircularProgressIndicator());
    Widget media;
    if (widget.isVideo && _videoError != null) { return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.video_file_outlined, size: 56, color: Colors.white70), const SizedBox(height: 12), Text(_videoError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)), const SizedBox(height: 8), const Text('Your original file is kept unchanged until export succeeds.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12))]))); }
    if (widget.isVideo && _video?.value.isInitialized == true) { final size = _video!.value.size; media = FittedBox(fit: BoxFit.contain, child: SizedBox(width: size.width, height: size.height, child: VideoPlayer(_video!))); }
    else if (widget.isVideo) { media = const Center(child: CircularProgressIndicator()); }
    else if (widget.mediaPath?.isNotEmpty == true) media = Image.file(File(widget.mediaPath!), fit: BoxFit.contain); else media = const Icon(Icons.add_photo_alternate_outlined, size: 70, color: Colors.white38);
    final filter = _previewColorFilter();
    if (filter != null) media = ColorFiltered(colorFilter: filter, child: media);
    media = ClipRect(child: AspectRatio(aspectRatio: _previewAspectRatio(), child: media));
    return Stack(fit: StackFit.expand, children: [Center(child: media), if (_text != null) Align(alignment: _textPosition == 'Top' ? Alignment.topCenter : (_textPosition == 'Bottom' ? Alignment.bottomCenter : Alignment.center), child: Padding(padding: const EdgeInsets.all(24), child: Text(_text!, textAlign: TextAlign.center, style: TextStyle(fontSize: (_textSize / 2).clamp(12, 48), fontWeight: _previewTextWeight(), color: _previewTextColor(_textColor), shadows: [Shadow(blurRadius: _textPreset == 'Neon' ? 18 : 8, color: Colors.black), if (_textPreset == 'Shadow') const Shadow(blurRadius: 3, offset: Offset(3, 3), color: Colors.black)])))), ..._stickers.asMap().entries.map((entry) => Positioned(left: entry.key.isEven ? 18 : null, right: entry.key.isOdd ? 18 : null, top: 52.0 + (entry.key % 4) * 48, child: Text(entry.value, style: const TextStyle(fontSize: 36, shadows: [Shadow(blurRadius: 6, color: Colors.black)])))), if (_mask == 'Cinematic bars' || _mask == 'Letterbox') ...[const Positioned(top: 0, left: 0, right: 0, height: 22, child: ColoredBox(color: Colors.black)), const Positioned(bottom: 0, left: 0, right: 0, height: 22, child: ColoredBox(color: Colors.black))], if (_mask == 'Vignette') const Positioned.fill(child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(colors: [Colors.transparent, Colors.black54], stops: [0.55, 1.0]))))), Positioned(top: 10, left: 10, child: _pill(_ratio)), Positioned(top: 10, right: 10, child: _pill(_selectedBeat == null ? _filter : 'BEAT • ${_selectedBeat!.creatorName}'))]);
  }
  Widget _pill(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)));
}
