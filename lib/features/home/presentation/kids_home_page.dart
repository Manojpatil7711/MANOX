import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';

class KidsHomePage extends StatefulWidget {
  const KidsHomePage({super.key});
  @override
  State<KidsHomePage> createState() => _KidsHomePageState();
}

class _KidsHomePageState extends State<KidsHomePage> {
  bool _unlocking = false;

  static const _items = <Map<String, dynamic>>[
    {'title': 'Science Experiments', 'icon': Icons.science_outlined},
    {'title': 'History', 'icon': Icons.account_balance_outlined},
    {'title': 'Geography Knowledge', 'icon': Icons.public_outlined},
    {'title': 'GK', 'icon': Icons.menu_book_outlined},
    {'title': 'Cartoon', 'icon': Icons.smart_toy_outlined},
    {'title': 'Beats', 'icon': Icons.music_note_outlined},
  ];

  Future<bool> _parentVerify() async {
    final client = SupabaseService.client;
    final email = client?.auth.currentUser?.email;
    if (client == null || email == null || email.isEmpty) return false;

    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialog) => AlertDialog(
        title: const Text('Parent Lock'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Parent password',
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('CANCEL'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialog, controller.text),
            icon: const Icon(Icons.lock_open_rounded),
            label: const Text('UNLOCK'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (password == null || password.isEmpty) return false;
    try {
      await client.auth.signInWithPassword(email: email, password: password);
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong parent password. Kids mode remains locked.')),
        );
      }
      return false;
    }
  }

  Future<void> _unlockKidsMode() async {
    if (_unlocking) return;
    setState(() => _unlocking = true);
    try {
      final client = SupabaseService.client;
      final user = client?.auth.currentUser;
      if (client == null || user == null) return;
      if (!await _parentVerify()) return;

      await client.from('kids_protection').upsert(
        {
          'user_id': user.id,
          'enabled': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id',
      );
      if (!mounted) return;
      // Parent unlock returns to the regular Home flow, not Settings.
      context.go('/home');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not unlock Main flow. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('MANOX Kids', style: TextStyle(fontWeight: FontWeight.w900)),
          actions: [
            IconButton(
              tooltip: 'Parent unlock',
              onPressed: _unlocking ? null : _unlockKidsMode,
              icon: const Icon(Icons.lock_rounded),
            ),
          ],
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (_, i) {
            final x = _items[i];
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (x['title'] == 'Beats') context.push('/beats');
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(x['icon'] as IconData, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      x['title'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.lock_outline_rounded, size: 16),
                  ],
                ),
              ),
            );
          },
        ),
      );
}
