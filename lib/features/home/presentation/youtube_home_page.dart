import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/demo_posts.dart';
import '../data/supabase_post_repository.dart';
import 'widgets/post_card.dart';

class YoutubeHomePage extends StatefulWidget {
  const YoutubeHomePage({super.key});
  @override State<YoutubeHomePage> createState() => _YoutubeHomePageState();
}

class _YoutubeHomePageState extends State<YoutubeHomePage> {
  final _repository = SupabasePostRepository();
  List<HomeDemoData> _posts = List<HomeDemoData>.from(demoPosts);
  bool _loading = true;
  int _category = 0;
  int _bottom = 0;
  static const categories = ['MANOX', 'BEATS', 'Learn', 'Live'];

  @override void initState() { super.initState(); _loadFeed(); }

  Future<void> _loadFeed() async {
    try {
      final remote = await _repository.fetchFeed();
      if (!mounted) return;
      setState(() {
        _posts = remote.map((p) => HomeDemoData(
          id: p.id, creatorName: p.creatorName, handle: p.handle, text: p.text,
          likes: p.likes, comments: p.comments, imagePath: p.imageUrl,
          mediaType: p.contentType, likedByMe: p.likedByMe, isRemote: true,
          ownerUserId: p.ownerUserId,
        )).toList();
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  void _openCreate() => context.push('/editor');

  Widget _topBar() => Material(
    color: Theme.of(context).colorScheme.surface,
    child: SafeArea(bottom: false, child: Padding(
      padding: const EdgeInsets.fromLTRB(12,6,8,6),
      child: Row(children: [
        Container(
          width:36,
          height:36,
          decoration:BoxDecoration(
            color:Theme.of(context).colorScheme.onSurface,
            borderRadius:BorderRadius.circular(10),
          ),
          alignment:Alignment.center,
          child:Text(
            'M',
            style:TextStyle(
              color:Theme.of(context).colorScheme.surface,
              fontSize:22,
              fontWeight:FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width:9), const Text('MANOX',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900,letterSpacing:.7)), const Spacer(),
        IconButton(tooltip:'Search',onPressed:()=>context.push('/search'),icon:const Icon(Icons.search_rounded)),
        IconButton(tooltip:'Create',onPressed:_openCreate,icon:const Icon(Icons.add_box_outlined)),
        IconButton(tooltip:'Notifications',onPressed:()=>context.push('/notifications'),icon:const Icon(Icons.notifications_none_rounded)),
        IconButton(tooltip:'Profile',onPressed:()=>context.push('/profile'),icon:const Icon(Icons.person_outline_rounded)),
      ]),
    )),
  );

  Widget _categories() => SizedBox(height:48,child:ListView.separated(
    padding:const EdgeInsets.symmetric(horizontal:12),scrollDirection:Axis.horizontal,itemCount:categories.length,
    separatorBuilder:(_,__)=>const SizedBox(width:8),itemBuilder:(_,i)=>ChoiceChip(label:Text(categories[i]),selected:i==_category,showCheckmark:false,onSelected:(_)=>setState(()=>_category=i)),
  ));

  Widget _sectionHeader()=>Padding(padding:const EdgeInsets.fromLTRB(12,10,8,4),child:Row(children:[Text(categories[_category],style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const Spacer(),IconButton(onPressed:_loadFeed,tooltip:'Refresh',icon:const Icon(Icons.refresh_rounded))]));

  Widget _bottomNavigation()=>NavigationBar(selectedIndex:_bottom,onDestinationSelected:(i){if(i==0)setState(()=>_bottom=0);if(i==1){setState(()=>_bottom=1);context.push('/search');}if(i==2){setState(()=>_bottom=0);_openCreate();}if(i==3){setState(()=>_bottom=3);context.push('/notifications');}if(i==4){setState(()=>_bottom=4);context.push('/profile');}},destinations:const[
    NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home_rounded),label:'Home'),
    NavigationDestination(icon:Icon(Icons.explore_outlined),selectedIcon:Icon(Icons.explore_rounded),label:'Explore'),
    NavigationDestination(icon:Icon(Icons.add_circle_outline_rounded),selectedIcon:Icon(Icons.add_circle_rounded),label:'Create'),
    NavigationDestination(icon:Icon(Icons.notifications_none_rounded),selectedIcon:Icon(Icons.notifications_rounded),label:'Alerts'),
    NavigationDestination(icon:Icon(Icons.person_outline_rounded),selectedIcon:Icon(Icons.person_rounded),label:'Profile'),
  ]);

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:PreferredSize(preferredSize:const Size.fromHeight(54),child:_topBar()),
    body:RefreshIndicator(onRefresh:_loadFeed,child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.only(bottom:16),children:[
      _categories(),_sectionHeader(),
      if(_loading)const Padding(padding:EdgeInsets.all(48),child:Center(child:CircularProgressIndicator()))
      else if(_posts.isEmpty)const Padding(padding:EdgeInsets.all(48),child:Center(child:Text('No content yet. Be the first creator.')))
      else ..._posts.map((post)=>Padding(padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),child:PostCard(data:post,repository:_repository,onChanged:_loadFeed))),
    ])),
    bottomNavigationBar:_bottomNavigation(),
  );
}
