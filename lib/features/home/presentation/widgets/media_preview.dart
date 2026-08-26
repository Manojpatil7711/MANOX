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
  const ManoxMediaPreview({super.key, required this.url, this.height = 240, this.fit = BoxFit.cover, this.autoPlay = false, this.loop = true, this.fullScreenStyle = false, this.onVideoTap});
  @override State<ManoxMediaPreview> createState() => _ManoxMediaPreviewState();
}
class _ManoxMediaPreviewState extends State<ManoxMediaPreview> {
  VideoPlayerController? _controller; bool _failed=false;
  @override void initState(){super.initState();_init();}
  Future<void> _init() async { final c=VideoPlayerController.networkUrl(Uri.parse(widget.url)); _controller=c; try{await c.initialize();await c.setLooping(widget.loop);if(widget.autoPlay)await c.play();if(mounted)setState((){});}catch(_){if(mounted)setState(()=>_failed=true);await c.dispose();} }
  @override void dispose(){_controller?.dispose();super.dispose();}
  void _togglePlayback() async {final c=_controller;if(c==null||!c.value.isInitialized)return;if(c.value.isPlaying){await c.pause();}else{await c.play();}if(mounted)setState((){});}
  @override Widget build(BuildContext context){final c=_controller;if(_failed)return SizedBox(height:widget.height,child:const Center(child:Text('Video unavailable')));if(c==null||!c.value.isInitialized)return SizedBox(height:widget.height,child:const Center(child:CircularProgressIndicator()));return GestureDetector(onTap:widget.onVideoTap ?? _togglePlayback,child:SizedBox(height:widget.height,width:double.infinity,child:Stack(alignment:Alignment.center,children:[ClipRRect(borderRadius:widget.fullScreenStyle?BorderRadius.zero:BorderRadius.circular(12),child:SizedBox.expand(child:FittedBox(fit:widget.fit,child:SizedBox(width:c.value.size.width,height:c.value.size.height,child:VideoPlayer(c))))),if(!c.value.isPlaying&&!widget.fullScreenStyle)Container(decoration:const BoxDecoration(shape:BoxShape.circle,color:Colors.black54),padding:const EdgeInsets.all(12),child:const Icon(Icons.play_arrow_rounded,color:Colors.white,size:34))])));}
}
class ManoxLocalVideoPreview extends StatefulWidget { final String path; final double height; const ManoxLocalVideoPreview({super.key,required this.path,this.height=150}); @override State<ManoxLocalVideoPreview> createState()=>_ManoxLocalVideoPreviewState(); }
class _ManoxLocalVideoPreviewState extends State<ManoxLocalVideoPreview>{VideoPlayerController? _controller;@override void initState(){super.initState();_init();}Future<void> _init() async{final c=VideoPlayerController.file(File(widget.path));_controller=c;try{await c.initialize();if(mounted)setState((){});}catch(_){if(mounted)setState((){});}}@override void dispose(){_controller?.dispose();super.dispose();}@override Widget build(BuildContext context){final c=_controller;if(c==null||!c.value.isInitialized)return Container(height:widget.height,width:double.infinity,alignment:Alignment.center,decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(12)),child:const Icon(Icons.video_file_outlined,size:42));return ClipRRect(borderRadius:BorderRadius.circular(12),child:GestureDetector(onTap:()=>setState(()=>c.value.isPlaying?c.pause():c.play()),child:SizedBox(height:widget.height,width:double.infinity,child:Stack(alignment:Alignment.center,children:[SizedBox.expand(child:FittedBox(fit:BoxFit.cover,child:SizedBox(width:c.value.size.width,height:c.value.size.height,child:VideoPlayer(c)))),if(!c.value.isPlaying)const CircleAvatar(backgroundColor:Colors.black54,child:Icon(Icons.play_arrow_rounded,color:Colors.white))]))));}}
bool isManoxVideo(String path){final clean=path.toLowerCase().split('?').first;return clean.endsWith('.mp4')||clean.endsWith('.mov')||clean.endsWith('.m4v')||clean.endsWith('.webm')||clean.endsWith('.3gp');}
