import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import 'home_page.dart';
import 'kids_home_page.dart';

class KidsModeGatePage extends StatefulWidget {
  const KidsModeGatePage({super.key});
  @override State<KidsModeGatePage> createState() => _KidsModeGatePageState();
}
class _KidsModeGatePageState extends State<KidsModeGatePage> {
  SupabaseClient? get _client => SupabaseService.client;
  @override void initState() { super.initState(); _check(); }
  Future<void> _check() async {
    final c = _client; final u = c?.auth.currentUser;
    if (c == null || u == null) { if (mounted) _open(const HomePage()); return; }
    try {
      final row = await c.from('kids_protection').select('enabled').eq('user_id', u.id).maybeSingle();
      if (mounted) _open((row?['enabled'] as bool? ?? false) ? const KidsHomePage() : const HomePage());
    } catch (_) { if (mounted) _open(const HomePage()); }
  }
  void _open(Widget page) => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
  @override Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
