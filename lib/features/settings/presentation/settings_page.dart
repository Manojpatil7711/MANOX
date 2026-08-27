import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import 'kids_protection_page.dart';

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
  bool _notifications = true;
  String _whoCanMessage = 'everyone';

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
      final row = await client.from('profile_privacy').select('private_account, who_can_message, allow_contact_sharing, show_online_status, show_last_seen, read_receipts').eq('user_id', user.id).maybeSingle();
      if (!mounted) return;
      if (row != null) {
        setState(() {
          _privateAccount = row['private_account'] as bool? ?? false;
          _whoCanMessage = row['who_can_message'] as String? ?? 'everyone';
          _allowContactSharing = row['allow_contact_sharing'] as bool? ?? false;
          _showOnline = row['show_online_status'] as bool? ?? false;
          _showLastSeen = row['show_last_seen'] as bool? ?? false;
          _readReceipts = row['read_receipts'] as bool? ?? true;
        });
      }
    } catch (_) {
      // Keep safe defaults when privacy data is unavailable.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _savePrivacy() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null || _saving) return;
    setState(() => _saving = true);
    try {
      await client.from('profile_privacy').upsert({'id': user.id, 'user_id': user.id, 'private_account': _privateAccount, 'who_can_message': _whoCanMessage, 'allow_contact_sharing': _allowContactSharing, 'show_online_status': _showOnline, 'show_last_seen': _showLastSeen, 'read_receipts': _readReceipts}, onConflict: 'id');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy settings saved.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save privacy settings.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openKidsSafety() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const KidsProtectionPage()));
  }

  void _openEditProfile() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit Profile is available from your profile page.')));
  }

  Widget _section(String title, IconData icon, List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(4, 20, 4, 8), child: Row(children: [Icon(icon, size: 19), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w700))])),
        Card(child: Column(children: children)),
      ]);

  ListTile _item({required IconData icon, required String title, String? subtitle, VoidCallback? onTap}) => ListTile(leading: Icon(icon), title: Text(title), subtitle: subtitle == null ? null : Text(subtitle), trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded), onTap: onTap);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Privacy'), actions: [TextButton(onPressed: _saving ? null : _savePrivacy, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('SAVE'))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 32), children: [
        _section('Account', Icons.person_outline_rounded, [
          _item(icon: Icons.edit_outlined, title: 'Edit profile', subtitle: 'Name, username, bio and profile photo', onTap: _openEditProfile),
          _item(icon: Icons.mail_outline_rounded, title: 'Email & account', subtitle: 'Private authentication information'),
          _item(icon: Icons.lock_outline_rounded, title: 'Password & security', subtitle: 'Securely managed by MANOX Authentication'),
        ]),
        _section('Privacy', Icons.shield_outlined, [
          SwitchListTile(secondary: const Icon(Icons.lock_person_outlined), title: const Text('Private account'), value: _privateAccount, onChanged: (v) => setState(() => _privateAccount = v)),
          SwitchListTile(secondary: const Icon(Icons.visibility_outlined), title: const Text('Show online status'), value: _showOnline, onChanged: (v) => setState(() => _showOnline = v)),
          SwitchListTile(secondary: const Icon(Icons.access_time_rounded), title: const Text('Show last seen'), value: _showLastSeen, onChanged: (v) => setState(() => _showLastSeen = v)),
          SwitchListTile(secondary: const Icon(Icons.done_all_rounded), title: const Text('Read receipts'), value: _readReceipts, onChanged: (v) => setState(() => _readReceipts = v)),
        ]),
        _section('Messages & Contacts', Icons.chat_bubble_outline_rounded, [
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: DropdownButtonFormField<String>(initialValue: _whoCanMessage, decoration: const InputDecoration(labelText: 'Who can message me', prefixIcon: Icon(Icons.chat_outlined)), items: const [DropdownMenuItem(value: 'everyone', child: Text('Everyone')), DropdownMenuItem(value: 'followers', child: Text('Followers')), DropdownMenuItem(value: 'no_one', child: Text('No one'))], onChanged: (v) { if (v != null) setState(() => _whoCanMessage = v); })),
          SwitchListTile(secondary: const Icon(Icons.contact_page_outlined), title: const Text('Allow contact sharing'), value: _allowContactSharing, onChanged: (v) => setState(() => _allowContactSharing = v)),
        ]),
        _section('Kids & Safety', Icons.child_care_rounded, [_item(icon: Icons.verified_user_outlined, title: 'Kids safety', subtitle: 'Age-appropriate protections', onTap: _openKidsSafety)]),
        _section('Notifications', Icons.notifications_none_rounded, [SwitchListTile(secondary: const Icon(Icons.notifications_active_outlined), title: const Text('Notifications'), value: _notifications, onChanged: (v) => setState(() => _notifications = v))]),
        _section('Content & Activity', Icons.tune_rounded, [
          _item(icon: Icons.bookmark_border_rounded, title: 'Saved content', subtitle: 'Open your saved posts and videos'),
          _item(icon: Icons.history_rounded, title: 'Activity history', subtitle: 'View your recent MANOX activity'),
        ]),
        const SizedBox(height: 16),
        const Center(child: Text('MANOX', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2))),
      ]),
    );
  }
}