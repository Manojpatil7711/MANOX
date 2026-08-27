import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';

class KidsProtectionPage extends StatefulWidget {
  const KidsProtectionPage({super.key});
  @override
  State<KidsProtectionPage> createState() => _KidsProtectionPageState();
}

class _KidsProtectionPageState extends State<KidsProtectionPage> {
  bool _enabled = false;
  bool _loading = true;
  bool _saving = false;
  bool _parentPasswordSet = false;
  SupabaseClient? get _client => SupabaseService.client;

  static const List<Map<String, dynamic>> _categories = [
    {'title': 'Science Experiments', 'icon': Icons.science_outlined},
    {'title': 'History', 'icon': Icons.account_balance_outlined},
    {'title': 'Geography Knowledge', 'icon': Icons.public_outlined},
    {'title': 'GK', 'icon': Icons.menu_book_outlined},
    {'title': 'Cartoon', 'icon': Icons.smart_toy_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final row = await client.from('kids_protection').select('enabled').eq('user_id', user.id).maybeSingle();
      if (mounted) {
        setState(() {
          _enabled = row?['enabled'] == true;
          _parentPasswordSet = user.userMetadata?['kids_parent_password_set'] == true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _enabled = false;
          _parentPasswordSet = user.userMetadata?['kids_parent_password_set'] == true;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(bool value) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null || _saving) return;

    // A child-safe lock must be configured before Kids Protection can be
    // activated. First-time setup does not ask for an already-existing
    // password; later changes require parent verification.
    if (value && !_parentPasswordSet) {
      final created = await _setParentPassword(firstSetup: true);
      if (!created || !mounted) return;
    }
    if (!value && !await _parentVerify()) return;
    if (mounted) setState(() => _saving = true);

    try {
      await client.from('kids_protection').upsert(
        {
          'user_id': user.id,
          'enabled': value,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id',
      );
      if (!mounted) return;
      setState(() => _enabled = value);

      if (value) {
        // This page is a GoRouter page now, so replacing the route stays in
        // one navigation tree and avoids the Flutter dependents assertion.
        context.go('/kids-home');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kids Protection OFF • Main flow unlocked')));
      context.go('/home');
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save Kids Protection.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _parentVerify() async {
    final client = _client;
    final email = client?.auth.currentUser?.email;
    if (client == null || email == null || email.isEmpty) return false;

    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialog) => AlertDialog(
        title: const Text('Parent verification'),
        content: TextField(controller: controller, obscureText: true, autofocus: true, decoration: const InputDecoration(labelText: 'Parent/account password')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(dialog, controller.text), child: const Text('UNLOCK')),
        ],
      ),
    );
    controller.dispose();

    if (password == null || password.isEmpty) return false;
    try {
      await client.auth.signInWithPassword(email: email, password: password);
      return true;
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification failed. Kids Protection remains locked.')));
      return false;
    }
  }

  Future<bool> _setParentPassword({bool firstSetup = false}) async {
    if (!firstSetup && !await _parentVerify()) return false;
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    final result = await showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialog) => AlertDialog(
        title: Text(firstSetup ? 'Set Parent Password' : 'Change Parent Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller, obscureText: true, autofocus: true, decoration: const InputDecoration(labelText: 'New parent password')),
            const SizedBox(height: 10),
            TextField(controller: confirmController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password')),
            const SizedBox(height: 8),
            const Align(alignment: Alignment.centerLeft, child: Text('Use at least 8 characters. This becomes the MANOX account password.')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(dialog, [controller.text, confirmController.text]), child: const Text('SAVE')),
        ],
      ),
    );
    controller.dispose();
    confirmController.dispose();

    if (result == null) return false;
    final newPassword = result[0];
    final confirmation = result[1];
    if (newPassword.length < 8 || newPassword != confirmation) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 8 characters and both entries must match.')));
      return false;
    }
    try {
      final client = _client;
      if (client == null) return false;
      await client.auth.updateUser(UserAttributes(password: newPassword, data: {'kids_parent_password_set': true}));
      if (!mounted) return true;
      setState(() => _parentPasswordSet = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parent Password configured securely.')));
      return true;
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update Parent Password.')));
      return false;
    }
  }

  Future<void> _changeParentPassword() async {
    await _setParentPassword(firstSetup: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Kids Protection', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: SwitchListTile.adaptive(
            secondary: Icon(_enabled ? Icons.lock_rounded : Icons.lock_open_rounded),
            title: const Text('Kids Protection', style: TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(_enabled ? 'ON • Kids flow active and Main flow locked' : 'OFF • Set Parent Password before enabling'),
            value: _enabled,
            onChanged: _saving ? null : _toggle,
          )),
          const SizedBox(height: 10),
          Card(child: ListTile(
            leading: Icon(_parentPasswordSet ? Icons.password_rounded : Icons.add_moderator_rounded),
            title: Text(_parentPasswordSet ? 'Change Parent Password' : 'Set Parent Password', style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(_parentPasswordSet ? 'Required to unlock Kids Protection and return to the main flow' : 'Required before Kids Protection can be turned ON'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _saving ? null : _changeParentPassword,
          )),
          const SizedBox(height: 16),
          const Text('Kids-only categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ..._categories.map((item) => Card(child: ListTile(leading: Icon(item['icon'] as IconData), title: Text(item['title'] as String), trailing: const Icon(Icons.lock_outline_rounded)))),
          const SizedBox(height: 8),
          const Text('Only Science Experiments, History, Geography Knowledge, GK and Cartoon are exposed in Kids mode. Adult feed, BEATS, monetization, withdrawal and messaging stay locked.', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
