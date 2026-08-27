import 'package:flutter/material.dart';
import '../data/demo_posts.dart';
import '../data/supabase_post_repository.dart';
import 'widgets/post_card.dart';

class DiscoveryPage extends StatefulWidget {
  final String title;
  final IconData icon;
  const DiscoveryPage({super.key, required this.title, required this.icon});
  @override State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  final _repository = SupabasePostRepository();
  final _trendController = TextEditingController();
  List<HomeDemoData> _posts = [];
  bool _loading = true;
  String _trendWindow = '24h';
  String _category = 'All';
  String _sport = 'All Sports';
  bool get _isTrending => widget.title == 'Trending';
  bool get _isSports => widget.title == 'Sports';

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _trendController.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      var posts = await _repository.fetchFeed();
      if (_isTrending) posts.sort((a,b) => _trendScore(b).compareTo(_trendScore(a)));
      if (_isSports) posts = posts.where(_isSportsPost).toList();
      if (!mounted) return;
      setState(() { _posts = posts.map((p) => HomeDemoData(id:p.id,creatorName:p.creatorName,handle:p.handle,text:p.text,likes:p.likes,comments:p.comments,imagePath:p.imageUrl,mediaType:p.contentType,likedByMe:p.likedByMe,isRemote:true,ownerUserId:p.ownerUserId)).toList(); _loading=false; });
    } catch (_) { if (mounted) setState(() => _loading=false); }
  }

  bool _isSportsPost(dynamic p) {
    final text = '${p.text} ${p.creatorName}'.toLowerCase();
    return RegExp(r'football|cricket|soccer|tennis|kabaddi|hockey|basketball|volleyball|badminton|athletics|sports|fifa|ipl|olympic').hasMatch(text);
  }
  int _trendScore(HomeDemoData p) => p.likes * 3 + p.comments * 2;

  List<HomeDemoData> get _filteredPosts {
    var result = List<HomeDemoData>.from(_posts);
    final q = _trendController.text.trim().toLowerCase();
    if (q.isNotEmpty) result = result.where((p) => '${p.text} ${p.creatorName} ${p.handle}'.toLowerCase().contains(q)).toList();
    if (_isSports && _sport != 'All Sports') result = result.where((p) => p.text.toLowerCase().contains(_sport.toLowerCase())).toList();
    if (_category == 'Videos') result = result.where((p) => p.mediaType == 'video').toList();
    if (_category == 'Images') result = result.where((p) => p.mediaType == 'image').toList();
    if (_isTrending) result.sort((a,b) => _trendScore(b).compareTo(_trendScore(a)));
    return result;
  }

  Widget _sportsHeader() => Container(
    margin: const EdgeInsets.fromLTRB(12,12,12,8), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.sports_soccer_rounded, color: Theme.of(context).colorScheme.primary), const SizedBox(width:8), const Expanded(child: Text('Sports Hub', style: TextStyle(fontSize:21,fontWeight:FontWeight.w900))), const Icon(Icons.emoji_events_rounded)]),
      const SizedBox(height:6),
      const Text('Discover sports content by game, search and format.'),
      const SizedBox(height:14),
      TextField(controller:_trendController,onChanged:(_)=>setState((){}),decoration:InputDecoration(hintText:'Search sports, teams or players…',prefixIcon:const Icon(Icons.search_rounded),suffixIcon:_trendController.text.isEmpty?null:IconButton(onPressed:(){_trendController.clear();setState((){});},icon:const Icon(Icons.clear_rounded)),border:OutlineInputBorder(borderRadius:BorderRadius.circular(16)))),
      const SizedBox(height:12),
      SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[for(final s in ['All Sports','Cricket','Football','Tennis','Kabaddi','Hockey','Basketball','Athletics']) Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text(s),selected:_sport==s,onSelected:(_)=>setState(()=>_sport=s)))])),
      const SizedBox(height:8),
      SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[for(final c in ['All','Videos','Images']) Padding(padding:const EdgeInsets.only(right:8),child:FilterChip(label:Text(c),selected:_category==c,onSelected:(_)=>setState(()=>_category=c)))])),
    ]),
  );

  Widget _trendingHeader() => Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Container(margin:const EdgeInsets.fromLTRB(12,12,12,8),padding:const EdgeInsets.all(16),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),border:Border.all(color:Theme.of(context).colorScheme.outlineVariant)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Icon(Icons.local_fire_department_rounded,color:Theme.of(context).colorScheme.primary),const SizedBox(width:8),const Expanded(child:Text('Trending Now',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900))),const Icon(Icons.insights_rounded)]),const SizedBox(height:6),const Text('Discover rising MANOX topics and content.'),const SizedBox(height:14),
      TextField(controller:_trendController,onChanged:(_)=>setState((){}),decoration:InputDecoration(hintText:'Search a trend or topic…',prefixIcon:const Icon(Icons.search_rounded),suffixIcon:_trendController.text.isEmpty?null:IconButton(onPressed:(){_trendController.clear();setState((){});},icon:const Icon(Icons.clear_rounded)),border:OutlineInputBorder(borderRadius:BorderRadius.circular(16)))),const SizedBox(height:12),
      SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[for(final w in ['24h','7d','30d']) Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text(w),selected:_trendWindow==w,onSelected:(_)=>setState(()=>_trendWindow=w))),const SizedBox(width:4),for(final c in ['All','Videos','Images']) Padding(padding:const EdgeInsets.only(right:8),child:FilterChip(label:Text(c),selected:_category==c,onSelected:(_)=>setState(()=>_category=c)))])),
    ])),Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:6),child:Row(children:[const Icon(Icons.trending_up_rounded,size:19),const SizedBox(width:6),Text('Rising on MANOX • $_trendWindow',style:const TextStyle(fontWeight:FontWeight.w800)),const Spacer(),Text('${_filteredPosts.length} results',style:Theme.of(context).textTheme.bodySmall)]))]);

  Widget _empty() => ListView(physics:const AlwaysScrollableScrollPhysics(),children:[if(_isTrending)_trendingHeader(),if(_isSports)_sportsHeader(),Padding(padding:const EdgeInsets.all(40),child:Column(children:[Icon(widget.icon,size:52),const SizedBox(height:12),Text('No ${widget.title} content yet.',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800),textAlign:TextAlign.center),const SizedBox(height:8),const Text('Create or publish content and it will appear here.',textAlign:TextAlign.center)]))]);

  @override Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar:AppBar(title:Row(children:[Icon(widget.icon),const SizedBox(width:8),Text(widget.title)])),body:const Center(child:CircularProgressIndicator()));
    final posts=_filteredPosts;
    final headerCount=(_isTrending||_isSports)?1:0;
    final content=posts.isEmpty?_empty():ListView.builder(physics:const AlwaysScrollableScrollPhysics(),padding:EdgeInsets.fromLTRB(12,(_isTrending||_isSports)?0:12,12,28),itemCount:posts.length+headerCount,itemBuilder:(_,index){if(_isTrending&&index==0)return _trendingHeader();if(_isSports&&index==0)return _sportsHeader();final post=posts[index-headerCount];return Padding(padding:const EdgeInsets.only(bottom:10),child:PostCard(data:post,repository:_repository,onChanged:_load));});
    return Scaffold(appBar:AppBar(title:Row(children:[Icon(widget.icon),const SizedBox(width:8),Text(widget.title)])),body:RefreshIndicator(onRefresh:_load,child:content));
  }
}
