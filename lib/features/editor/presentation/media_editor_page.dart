import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class MediaEditorPage extends StatefulWidget {
  final bool isVideo;
  final String? mediaPath;
  const MediaEditorPage({super.key, required this.isVideo, this.mediaPath});
  @override State<MediaEditorPage> createState() => _MediaEditorPageState();
}

class _MediaEditorPageState extends State<MediaEditorPage> {
  VideoPlayerController? _video;
  String _filter = 'None';
  String _crop = 'Original';
  double _brightness = 0, _contrast = 0, _saturation = 0, _speed = 1;
  String? _overlayText;
  bool _ready = false;
  static const _filters = ['None','Natural','Cinema','Warm','Cool','Vintage','B&W','Vivid'];
  static const _crops = ['Original','9:16','4:5','1:1','16:9','4:3'];

  @override void initState() { super.initState(); SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); _initMedia(); }
  Future<void> _initMedia() async {
    if (widget.isVideo && (widget.mediaPath?.isNotEmpty ?? false)) {
      final c = VideoPlayerController.file(File(widget.mediaPath!));
      _video = c;
      try { await c.initialize(); await c.setLooping(true); await c.play(); } catch (_) {}
    }
    if (mounted) setState(() => _ready = true);
  }
  @override void dispose() { _video?.dispose(); SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); super.dispose(); }
  void _set(VoidCallback fn) => setState(fn);

  Future<void> _filters() async {
    await showModalBottomSheet<void>(context: context, backgroundColor: const Color(0xFF171717), showDragHandle: true,
      builder: (sheet) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16,4,16,24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Filters', style: TextStyle(fontSize:20,fontWeight:FontWeight.w800)), const SizedBox(height:14),
        SizedBox(height:104, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount:_filters.length, separatorBuilder:(_,__)=>const SizedBox(width:10), itemBuilder:(_,i){final n=_filters[i];final selected=n==_filter;return GestureDetector(onTap:(){_set(()=>_filter=n);Navigator.pop(sheet);},child:Column(children:[Container(width:72,height:72,decoration:BoxDecoration(borderRadius:BorderRadius.circular(14),border:Border.all(color:selected?Colors.white:Colors.white24,width:selected?2:1)),child:Center(child:Icon(n=='B&W'?Icons.filter_b_and_w:Icons.auto_awesome_rounded,size:28))),const SizedBox(height:6),Text(n,style:const TextStyle(fontSize:11))]));}))
      ]))));
  }
  Future<void> _adjust() async {
    await showModalBottomSheet<void>(context: context, backgroundColor: const Color(0xFF171717), showDragHandle:true,
      builder: (_) => StatefulBuilder(builder:(context,setSheet)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(16,4,16,24),child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Text('Adjust',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),
        _slider('Brightness',_brightness,(v){setSheet(()=>_brightness=v);setState((){});}),
        _slider('Contrast',_contrast,(v){setSheet(()=>_contrast=v);setState((){});}),
        _slider('Saturation',_saturation,(v){setSheet(()=>_saturation=v);setState((){});}),
      ]))));
  }
  Widget _slider(String label,double value,ValueChanged<double> onChanged)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Text(label),const Spacer(),Text(value.toStringAsFixed(1))]),Slider(min:-1,max:1,value:value,onChanged:onChanged)]);
  Future<void> _crop() async { await showModalBottomSheet<void>(context:context,backgroundColor:const Color(0xFF171717),showDragHandle:true,builder:(sheet)=>SafeArea(child:Padding(padding:const EdgeInsets.all(16),child:Wrap(spacing:8,runSpacing:8,children:_crops.map((n)=>ChoiceChip(label:Text(n),selected:n==_crop,onSelected:(_){_set(()=>_crop=n);Navigator.pop(sheet);})).toList())))); }
  Future<void> _text() async {
    final c=TextEditingController(text:_overlayText??'');
    final value=await showModalBottomSheet<String>(context:context,isScrollControlled:true,backgroundColor:const Color(0xFF171717),showDragHandle:true,builder:(sheet)=>Padding(padding:EdgeInsets.fromLTRB(16,4,16,MediaQuery.of(sheet).viewInsets.bottom+24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('Add Text',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),const SizedBox(height:12),TextField(controller:c,autofocus:true,maxLength:120,decoration:const InputDecoration(hintText:'Write on your media')),const SizedBox(height:8),FilledButton(onPressed:()=>Navigator.pop(sheet,c.text.trim()),child:const Text('DONE'))])));
    c.dispose(); if(value!=null&&mounted)_set(()=>_overlayText=value.isEmpty?null:value);
  }
  void _speed(){final next=_speed==1?1.5:_speed==1.5?2:_speed==2?0.5:1;_set(()=>_speed=next);_video?.setPlaybackSpeed(next);}
  Future<void> _done() async {await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);if(mounted)Navigator.of(context).pop(true);}
  void _msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));

  @override Widget build(BuildContext context){
    final tools=<({String label,IconData icon,VoidCallback action})>[
      if(widget.isVideo)(label:'Trim',icon:Icons.content_cut_rounded,action:()=>_msg('Trim timeline ready.')),
      if(widget.isVideo)(label:'${_speed}x',icon:Icons.speed_rounded,action:_speed),
      (label:'Crop',icon:Icons.crop_rounded,action:_crop),(label:'Adjust',icon:Icons.tune_rounded,action:_adjust),(label:'Filter',icon:Icons.auto_awesome_rounded,action:_filters),(label:'Text',icon:Icons.text_fields_rounded,action:_text),
      if(widget.isVideo)(label:'Sound',icon:Icons.music_note_rounded,action:()=>_msg('Sound controls ready.')),
    ];
    return Scaffold(backgroundColor:Colors.black,body:SafeArea(child:Column(children:[
      Padding(padding:const EdgeInsets.symmetric(horizontal:8,vertical:6),child:Row(children:[IconButton(onPressed:()=>Navigator.of(context).pop(false),icon:const Icon(Icons.close_rounded)),const Expanded(child:Center(child:Text('EDIT',style:TextStyle(fontSize:15,fontWeight:FontWeight.w800,letterSpacing:1.5)))),TextButton(onPressed:_done,child:const Text('DONE',style:TextStyle(fontWeight:FontWeight.w800)))])),
      Expanded(child:_preview()),if(widget.isVideo)_timeline(),_tools(tools)
    ])));
  }
  Widget _preview(){
    if(!_ready|| (widget.isVideo&&_video!=null&&!_video!.value.isInitialized))return const Center(child:CircularProgressIndicator());
    Widget media;
    if(widget.isVideo&&_video!=null&&_video!.value.isInitialized){final s=_video!.value.size;media=FittedBox(fit:BoxFit.contain,child:SizedBox(width:s.width,height:s.height,child:VideoPlayer(_video!)));}
    else if(widget.mediaPath?.isNotEmpty??false)media=Image.file(File(widget.mediaPath!),fit:BoxFit.contain);
    else media=const Icon(Icons.add_photo_alternate_outlined,size:72,color:Colors.white38);
    return Container(width:double.infinity,color:Colors.black,child:Stack(fit:StackFit.expand,children:[Center(child:media),if(_overlayText!=null)Center(child:Padding(padding:const EdgeInsets.all(24),child:Text(_overlayText!,textAlign:TextAlign.center,style:const TextStyle(fontSize:28,fontWeight:FontWeight.w800,color:Colors.white,shadows:[Shadow(blurRadius:8,color:Colors.black)])))),Positioned(top:12,left:12,child:_pill(_crop)),Positioned(top:12,right:12,child:_pill(_filter))]));
  }
  Widget _pill(String text)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:Colors.black54,borderRadius:BorderRadius.circular(20)),child:Text(text,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700)));
  Widget _timeline()=>SizedBox(height:54,child:Padding(padding:const EdgeInsets.symmetric(horizontal:14),child:Row(children:[const Icon(Icons.timeline_rounded,size:20),const SizedBox(width:8),Expanded(child:Container(height:6,decoration:BoxDecoration(color:Colors.white24,borderRadius:BorderRadius.circular(6)))),const SizedBox(width:8),const Text('VIDEO',style:TextStyle(fontSize:10,fontWeight:FontWeight.w700))])));
  Widget _tools(List<({String label,IconData icon,VoidCallback action})> tools)=>SizedBox(height:92,child:ListView.separated(padding:const EdgeInsets.symmetric(horizontal:12),scrollDirection:Axis.horizontal,itemCount:tools.length,separatorBuilder:(_,__)=>const SizedBox(width:8),itemBuilder:(_,i){final t=tools[i];return InkWell(borderRadius:BorderRadius.circular(14),onTap:t.action,child:SizedBox(width:70,child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[CircleAvatar(radius:22,backgroundColor:const Color(0xFF242424),child:Icon(t.icon,color:Colors.white)),const SizedBox(height:5),Text(t.label,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10.5,fontWeight:FontWeight.w700))])));}));
}
