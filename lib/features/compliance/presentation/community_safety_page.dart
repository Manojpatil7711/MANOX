import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';

class CommunitySafetyPage extends StatefulWidget {
  const CommunitySafetyPage({super.key});

  @override
  State<CommunitySafetyPage> createState() => _CommunitySafetyPageState();
}

class _CommunitySafetyPageState extends State<CommunitySafetyPage> {
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _guidelinesAccepted = false;
  bool _loading = true;
  bool _saving = false;

  SupabaseClient? get _client => SupabaseService.client;

  @override
  void initState() {
    super.initState();
    _loadConsents();
  }

  Future<void> _loadConsents() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final rows = await client.from('legal_consents').select('policy_type').eq('user_id', user.id);
      final types = (rows as List).map((row) => row['policy_type'] as String).toSet();
      if (mounted) {
        setState(() {
          _termsAccepted = types.contains('terms_of_use');
          _privacyAccepted = types.contains('privacy_policy');
          _guidelinesAccepted = types.contains('community_guidelines');
        });
      }
    } catch (_) {
      // Keep unchecked until the server confirms consent.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveConsents() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null || _saving) return;
    if (!_termsAccepted || !_privacyAccepted || !_guidelinesAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accept Terms, Privacy Policy and Community Guidelines before posting.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await client.from('legal_consents').upsert([
        {'user_id': user.id, 'policy_type': 'terms_of_use', 'policy_version': '2026-08-26'},
        {'user_id': user.id, 'policy_type': 'privacy_policy', 'policy_version': '2026-08-26'},
        {'user_id': user.id, 'policy_type': 'community_guidelines', 'policy_version': '2026-08-26'},
      ], onConflict: 'user_id,policy_type');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Legal consent saved.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save legal consent.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete MANOX account?'),
        content: const Text('This permanently deletes the account and associated user data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('DELETE ACCOUNT')),
        ],
      ),
    );
    if (confirm != true || _client == null) return;
    try {
      await _client!.functions.invoke('delete-account');
      await _client!.auth.signOut();
      if (mounted) context.findAncestorStateOfType<State<CommunitySafetyPage>>();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deletion failed. Please try again.')));
    }
  }

  Widget _consentTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Safety')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                const Text('MANOX UGC SAFETY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                const Text('MANOX is a social platform. Users must not upload illegal, sexually explicit, exploitative, hateful, threatening, harassing, fraudulent or otherwise prohibited content.'),
                const SizedBox(height: 18),
                Card(child: Column(children: [
                  _consentTile('Terms of Use', 'Required before creating or uploading user-generated content.', _termsAccepted, (v) => setState(() => _termsAccepted = v)),
                  _consentTile('Privacy Policy', 'Explains what data MANOX collects, uses and retains.', _privacyAccepted, (v) => setState(() => _privacyAccepted = v)),
                  _consentTile('Community Guidelines', 'Sets the rules for posts, comments, profiles and messages.', _guidelinesAccepted, (v) => setState(() => _guidelinesAccepted = v)),
                ])),
                const SizedBox(height: 12),
                FilledButton.icon(onPressed: _saving ? null : _saveConsents, icon: const Icon(Icons.verified_user_outlined), label: Text(_saving ? 'SAVING…' : 'SAVE LEGAL CONSENT')),
                const SizedBox(height: 24),
                const Text('SAFETY CONTROLS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                const Card(child: Column(children: [
                  ListTile(leading: Icon(Icons.flag_outlined), title: Text('Report content'), subtitle: Text('Report objectionable posts, photos, videos or comments from the content action menu.')),
                  ListTile(leading: Icon(Icons.person_off_outlined), title: Text('Report or block users'), subtitle: Text('Use clearly labelled report and block actions on public profiles and user interactions.')),
                  ListTile(leading: Icon(Icons.shield_outlined), title: Text('Moderation'), subtitle: Text('Reports are routed to server-side moderation queues and enforcement records.')),
                ])),
                const SizedBox(height: 24),
                const Text('ACCOUNT & DATA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Card(child: ListTile(
                  leading: const Icon(Icons.delete_forever_outlined),
                  title: const Text('Delete account', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Permanently delete your MANOX account and associated data.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _deleteAccount,
                )),
              ],
            ),
    );
  }
}
