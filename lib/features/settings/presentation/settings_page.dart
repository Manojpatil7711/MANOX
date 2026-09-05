import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    } catch (_) {} finally {
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

  Future<void> _openEmailAccount() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account session unavailable. Please sign in again.')));
      return;
    }
    final controller = TextEditingController(text: user.email ?? '');
    final formKey = GlobalKey<FormState>();
    final newEmail = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Email & account'),
        content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Current email: ${user.email ?? 'Not available'}'),
          const SizedBox(height: 8),
          Text(user.emailConfirmedAt == null ? 'Email status: Not verified' : 'Email status: Verified'),
          if (user.emailConfirmedAt == null) ...[
            const SizedBox(height: 4),
            TextButton(onPressed: user.email == null ? null : () async { try { await client.auth.resend(type: OtpType.signup, email: user.email!); if (dialogContext.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email sent.'))); } on AuthException catch (e) { if (dialogContext.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); } }, child: const Text('RESEND VERIFICATION EMAIL')),
          ],
          const SizedBox(height: 8),
          TextFormField(controller: controller, keyboardType: TextInputType.emailAddress, autocorrect: false, decoration: const InputDecoration(labelText: 'New email', hintText: 'name@example.com'), validator: (value) { final email = value?.trim() ?? ''; if (email.isEmpty) return 'Enter an email address'; if (!email.contains('@') || !email.contains('.')) return 'Enter a valid email address'; if (email == user.email) return 'Enter a different email address'; return null; }),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')), FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, controller.text.trim()); }, child: const Text('CHANGE EMAIL'))],
      ),
    );
    controller.dispose();
    if (newEmail == null || newEmail.isEmpty) return;
    try {
      await client.auth.updateUser(UserAttributes(email: newEmail));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confirmation email sent. Confirm the new email to complete the change.')));
    } on AuthException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); }
    catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not change email. Please try again.'))); }
  }

  void _openKidsSafety() => context.push('/kids-protection');
  void _openEditProfile() => context.push('/profile');
  void _openMessages() => context.push('/messages');
  void _openNotifications() => context.push('/notifications');
  void _openMonetization() => context.push('/monetization');
  void _openSafety() => context.push('/community-safety');
  void _openWomenSafety() => context.push('/women-safety');

  Future<void> _openSecurity() async {
    if (!mounted) return;
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Password & security'), content: const Text('Reset your password through the secure MANOX recovery flow.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CLOSE')), FilledButton(onPressed: () { Navigator.pop(dialogContext); context.push('/auth/forgot'); }, child: const Text('RESET PASSWORD'))]));
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Sign out?'), content: const Text('You can sign back in anytime with your MANOX account.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('CANCEL')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('SIGN OUT'))]));
    if (confirmed != true || !mounted) return;
    final client = _client;
    if (client == null) return;
    try { await client.auth.signOut(); if (mounted) context.go('/auth'); }
    catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not sign out. Please try again.'))); }
  }

  Widget _section(String title, IconData icon, List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.fromLTRB(4, 20, 4, 8), child: Row(children: [Icon(icon, size: 19), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w700))])), Card(child: Column(children: children))]);

  ListTile _item({required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) => ListTile(leading: Icon(icon), title: Text(title), subtitle: subtitle == null ? null : Text(subtitle), trailing: const Icon(Icons.chevron_right_rounded), onTap: onTap);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings & Privacy'), actions: [TextButton(onPressed: _saving ? null : _savePrivacy, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('SAVE'))]),
    body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 32), children: [
      _section('Account', Icons.person_outline_rounded, [
        _item(icon: Icons.edit_outlined, title: 'Edit profile', subtitle: 'Name, username, bio and profile photo', onTap: _openEditProfile),
        _item(icon: Icons.mail_outline_rounded, title: 'Email & account', subtitle: 'Email and verification', onTap: _openEmailAccount),
        _item(icon: Icons.lock_outline_rounded, title: 'Password & security', subtitle: 'Password recovery and sign-in security', onTap: _openSecurity),
      ]),
      _section('Privacy', Icons.shield_outlined, [
        SwitchListTile(secondary: const Icon(Icons.lock_person_outlined), title: const Text('Private account'), value: _privateAccount, onChanged: (v) => setState(() => _privateAccount = v)),
        SwitchListTile(secondary: const Icon(Icons.visibility_outlined), title: const Text('Show online status'), value: _showOnline, onChanged: (v) => setState(() => _showOnline = v)),
        SwitchListTile(secondary: const Icon(Icons.access_time_rounded), title: const Text('Show last seen'), value: _showLastSeen, onChanged: (v) => setState(() => _showLastSeen = v)),
        SwitchListTile(secondary: const Icon(Icons.done_all_rounded), title: const Text('Read receipts'), value: _readReceipts, onChanged: (v) => setState(() => _readReceipts = v)),
      ]),
      _section('Messages', Icons.chat_bubble_outline_rounded, [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: DropdownButtonFormField<String>(initialValue: _whoCanMessage, decoration: const InputDecoration(labelText: 'Who can message me', prefixIcon: Icon(Icons.chat_outlined)), items: const [DropdownMenuItem(value: 'everyone', child: Text('Everyone')), DropdownMenuItem(value: 'followers', child: Text('Followers')), DropdownMenuItem(value: 'no_one', child: Text('No one'))], onChanged: (v) { if (v != null) setState(() => _whoCanMessage = v); })),
        SwitchListTile(secondary: const Icon(Icons.contact_page_outlined), title: const Text('Allow contact sharing'), value: _allowContactSharing, onChanged: (v) => setState(() => _allowContactSharing = v)),
        _item(icon: Icons.chat_outlined, title: 'Chat', subtitle: 'Open MANOX messages', onTap: _openMessages),
      ]),
      _section('Safety', Icons.health_and_safety_outlined, [
        _item(icon: Icons.child_care_rounded, title: 'Kids safety', subtitle: 'Age-appropriate protections', onTap: _openKidsSafety),
        _item(icon: Icons.shield_outlined, title: 'Community safety', subtitle: 'Rules, reporting and protection', onTap: _openSafety),
        _item(icon: Icons.emergency_outlined, title: 'Women Safety', subtitle: 'Dedicated safety tools and emergency protection', onTap: _openWomenSafety),
      ]),
      _section('Notifications', Icons.notifications_none_rounded, [
        _item(icon: Icons.notifications_active_outlined, title: 'Notification settings', subtitle: 'Messages, follows, comments and creator alerts', onTap: _openNotifications),
      ]),
      _section('Creator', Icons.monetization_on_outlined, [
        _item(icon: Icons.monetization_on_outlined, title: 'Monetization', subtitle: 'Creator eligibility, earnings and payout controls', onTap: _openMonetization),
      ]),
      const SizedBox(height: 20),
      Card(child: ListTile(leading: const Icon(Icons.logout_rounded), title: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('Sign out securely from this device'), trailing: const Icon(Icons.chevron_right_rounded), onTap: _signOut)),
      const SizedBox(height: 16),
      const Center(child: Text('MANOX', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2))),
    ]),
  );
}
