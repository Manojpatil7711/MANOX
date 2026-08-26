import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';

class KidsProtectionPage extends StatefulWidget {
  const KidsProtectionPage({super.key});
  @override State<KidsProtectionPage> createState() => _KidsProtectionPageState();
}

class _KidsProtectionPageState extends State<KidsProtectionPage> {
  bool _enabled = false, _loading = true, _saving = false;
  SupabaseClient? get _client => SupabaseService.client;
  static const _categories = <Map<String, dynamic>>[
    {'title':'Science Experiments','icon':Icons.science_outlined}, {'title':'History','icon':Icons.account_balance_outlined},
    {'title':'Geography Knowledge','icon':Icons.public_outlined}, {'title':'GK','icon':Icons.menu_book_outlined},
    {'title':'Cartoon','icon':Icons.smart_toy_outlined}, {'title':'Beats','icon':Icons.music_note_outlined},
  ];
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final c=_client, u=c?.auth.currentUser; if(c==null||u==null){if(mounted)setState(()=>_loading=false);return;}
    try { final r=await c.from('kids_protection').select('enabled').eq('user_id',u.id).maybeSingle(); if(mounted)setState(()=>_enabled=r?['enabled'] as bool? ?? false); } catch(_){ } finally {if(mounted)setState(()=>_loading=false);}
  }
  Future<void> _toggle(bool value) async {
    final c=_client,u=c?.auth.currentUser; if(c==null||u==null||_saving)return;
    if(!value && !await _parentVerify()) return;
    setState(()=>_saving=true);
    try { await c.from('kids_protection').upsert({'user_id':u.id,'enabled':value,'updated_at':DateTime.now().toUtc().toIso8601String()},onConflict:'user_id'); if(mounted){setState(()=>_enabled=value);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(value?'Kids Protection ON':'Kids Protection OFF')));}} catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not save Kids Protection.')));} finally {if(mounted)setState(()=>_saving=false);}
  }
  Future<bool> _parentVerify() async {
    final email=_client?.auth.currentUser?.email; if(email==null||email.isEmpty)return false; final c=TextEditingController();
    final p=await showDialog<String>(context:context,builder:(d)=>AlertDialog(title:const Text('Parent verification'),content:TextField(controller:c,obscureText:true,autofocus:true,decoration:const InputDecoration(labelText:'Account password')),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('CANCEL')),FilledButton(onPressed:()=>Navigator.pop(d,c.text),child:const Text('UNLOCK'))])); c.dispose();
    if(p==null||p.isEmpty)return false; try{await _client!.auth.signInWithPassword(email:email,password:p);return true;}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Verification failed. Kids Protection remains locked.')));return false;}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Kids Protection',style:TextStyle(fontWeight:FontWeight.w800))),body:_loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(16),children:[Card(child:SwitchListTile.adaptive(secondary:Icon(_enabled?Icons.lock_rounded:Icons.lock_open_rounded),title:const Text('Kids Protection',style:TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(_enabled?'ON • Main flow locked to Kids mode':'OFF • Adult/main flow available'),value:_enabled,onChanged:_saving?null:_toggle)),const SizedBox(height:16),const Text('Kids-only categories',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:8),..._categories.map((x)=>Card(child:ListTile(leading:Icon(x['icon'] as IconData),title:Text(x['title'] as String),trailing:const Icon(Icons.lock_outline_rounded)))),const SizedBox(height:8),const Text('Only Science Experiments, History, Geography Knowledge, GK, Cartoon and Beats are exposed in Kids mode. Adult feed, monetization, withdrawal and messaging stay locked.',style:TextStyle(fontWeight:FontWeight.w600))]);
}
