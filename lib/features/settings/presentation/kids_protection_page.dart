import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';

class KidsProtectionPage extends StatefulWidget {
  const KidsProtectionPage({super.key});
  @override State<KidsProtectionPage> createState() => _KidsProtectionPageState();
}

class _KidsProtectionPageState extends State<KidsProtectionPage> {
  bool _enabled = false;
  bool _loading = true;
  bool _saving = false;
  SupabaseClient? get _client => SupabaseService.client;
  static const _categories = <Map<String, dynamic>>[
    {'title':'Science Experiments','icon':Icons.science_outlined},
    {'title':'History','icon':Icons.account_balance_outlined},
    {'title':'Geography Knowledge','icon':Icons.public_outlined},
    {'title':'GK','icon':Icons.menu_book_outlined},
    {'title':'Cartoon','icon':Icons.smart_toy_outlined},
    {'title':'Beats','icon':Icons.music_note_outlined},
  ];

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) { if (mounted) setState(() => _loading = false); return; }
    try {
      final row = await client.from('kids_protection').select('enabled').eq('user_id', user.id).maybeSingle();
      if (mounted) setState(() => _enabled = row?['enabled'] == true);
    } catch (_) {
      // Keep the safe default OFF when the preference cannot be loaded.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(bool value) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null || _saving) return;
    if (!value && !await _parentVerify()) return;
    setState(() => _saving = true);
    try {
      await client.from('kids_protection').upsert({
        'user_id': user.id,
        'enabled': value,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
      if (mounted) {
        setState(() => _enabled = value);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value ? 'Kids Protection ON' : 'Kids Protection OFF')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save Kids Protection.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _parentVerify() async {
    final email = _client?.auth.currentUser?.email;
    if (email == null || email.isEmpty) return false;
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Parent verification'),
        content: TextField(controller: controller, obscureText: true, autofocus: true, decoration: const InputDecoration(labelText: 'Account password')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(dialog, controller.text), child: const Text('UNLOCK')),
        ],
      ),
    );
    controller.dispose();
    if (password == null || password.isEmpty) return false;
    try {
      await _client!.auth.signInWithPassword(email: email, password: password);
      return true;
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification failed. Kids Protection remains locked.')));
      return false;
    }
  }

  @override Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Kids Protection', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: SwitchListTile.adaptive(
          secondary: Icon(_enabled ? Icons.lock_rounded : Icons.lock_open_rounded),
          title: const Text('Kids Protection', style: TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(_enabled ? 'ON • Main flow locked to Kids mode' : 'OFF • Adult/main flow available'),
          value: _enabled,
          onChanged: _saving ? null : _toggle,
        )),
        const SizedBox(height: 16),
        const Text('Kids-only categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        ..._categories.map((item) => Card(child: ListTile(
          leading: Icon(item['icon'] as IconData),
          title: Text(item['title'] as String),
          trailing: const Icon(Icons.lock_outline_rounded),
        ))),
        const SizedBox(height: 8),
        const Text('Only Science Experiments, History, Geography Knowledge, GK, Cartoon and Beats are exposed in Kids mode. Adult feed, monetization, withdrawal and messaging stay locked.', style: TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
