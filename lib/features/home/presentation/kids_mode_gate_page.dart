import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';

/// Resolves the initial home destination without nesting Navigator routes
/// inside GoRouter. This avoids framework dependency assertions during
/// Kids Protection ON/OFF transitions.
class KidsModeGatePage extends StatefulWidget {
  const KidsModeGatePage({super.key});
  @override
  State<KidsModeGatePage> createState() => _KidsModeGatePageState();
}

class _KidsModeGatePageState extends State<KidsModeGatePage> {
  SupabaseClient? get _client => SupabaseService.client;
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    if (_redirecting) return;
    final c = _client;
    final u = c?.auth.currentUser;
    if (c == null || u == null) {
      _go('/auth');
      return;
    }

    try {
      final row = await c
          .from('kids_protection')
          .select('enabled')
          .eq('user_id', u.id)
          .maybeSingle();
      if (!mounted) return;
      _go(row?['enabled'] == true ? '/kids-home' : '/main-home');
    } catch (_) {
      if (!mounted) return;
      _go('/main-home');
    }
  }

  void _go(String location) {
    if (!mounted || _redirecting) return;
    _redirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(location);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}
