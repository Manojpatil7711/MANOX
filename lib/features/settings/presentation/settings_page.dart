import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _loading = true;
  bool _saving = false;
  bool _privateAccount = false;
  bool _allowContactSharing = false;
  bool _showOnline = false;
  bool _showLastSeen = false;
  bool _readReceipts = true;
  String _allowMessages = 'everyone';

  SupabaseClient? get _client => SupabaseService.client;

  @override
  void initState() {
    super.initState();
    _loadPrivacy();
  }

  Future<void> _loadPrivacy() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final row = await client.from('profile_privacy').select('allow_messages, allow_contact_sharing, show_online_status, show_last_seen, read_receipts').eq('user_id', user.id).maybeSingle();
      if (!mounted) return;
      if (row != null) {
        setState(() {
          _allowMessages = row['allow_messages'] as String? ?? 'everyone';
          _allowContactSharing = row['allow_contact_sharing'] as bool? ?? false;
          _showOnline = row['show_online_status'] as bool? ?? false;
          _showLastSeen = row['show_last_seen'] as bool? ?? false;
          _readReceipts = row['read_receipts'] as bool? ?? true;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Privacy settings unavailable: $e')));
    }
  }

  Future<void> _savePrivacy() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null || _saving) return;
    setState(() => _saving = true);
    try {
      await client.from('profile_privacy').upsert({
        'user_id': user.id,
        'allow_messages': _allowMessages,
        'allow_contact_sharing': _allowContactSharing,
        'show_online_status': _showOnline,
        'show_last_seen': _showLastSeen,
        'read_receipts': _readReceipts,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy settings saved.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save privacy settings: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _savePrivacy,
            child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('SAVE'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
                SwitchListTile(
                  title: const Text('Private account'),
                  subtitle: const Text('Your contact details are never public by default.'),
                  value: _privateAccount,
                  onChanged: (v) => setState(() => _privateAccount = v),
                ),
                const Divider(),
                const Text('Messages & Contact', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _allowMessages,
                  decoration: const InputDecoration(labelText: 'Who can message me'),
                  items: const [
                    DropdownMenuItem(value: 'everyone', child: Text('Everyone')),
                    DropdownMenuItem(value: 'followers', child: Text('Followers')),
                    DropdownMenuItem(value: 'no_one', child: Text('No one')),
                  ],
                  onChanged: (v) { if (v != null) setState(() => _allowMessages = v); },
                ),
                SwitchListTile(
                  title: const Text('Allow contact sharing'),
                  subtitle: const Text('Only share contact information when you explicitly choose to share it.'),
                  value: _allowContactSharing,
                  onChanged: (v) => setState(() => _allowContactSharing = v),
                ),
                const Divider(),
                const Text('Privacy', style: TextStyle(fontWeight: FontWeight.bold)),
                SwitchListTile(title: const Text('Show online status'), value: _showOnline, onChanged: (v) => setState(() => _showOnline = v)),
                SwitchListTile(title: const Text('Show last seen'), value: _showLastSeen, onChanged: (v) => setState(() => _showLastSeen = v)),
                SwitchListTile(title: const Text('Read receipts'), value: _readReceipts, onChanged: (v) => setState(() => _readReceipts = v)),
                const Divider(),
                const Text('Security', style: TextStyle(fontWeight: FontWeight.bold)),
                ListTile(
                  title: const Text('Password & security'),
                  subtitle: const Text('Managed securely by MANOX Authentication'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                const Text('Email address and mobile number are account information. They are not displayed on your public profile. Contact sharing will be implemented as an explicit per-person action.', style: TextStyle(fontSize: 12)),
              ],
            ),
    );
  }
}
