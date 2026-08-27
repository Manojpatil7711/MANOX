import 'package:flutter/material.dart';
import '../safety_alert_service.dart';

class WomenSafetyPage extends StatefulWidget {
  const WomenSafetyPage({super.key});
  @override
  State<WomenSafetyPage> createState() => _WomenSafetyPageState();
}

class _WomenSafetyPageState extends State<WomenSafetyPage> {
  bool _eligible = false;
  bool _loading = true;
  bool _sending = false;
  int _escalation = 1;
  final List<_SafetyContact> _contacts = <_SafetyContact>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await SafetyAlertService.isFemaleProfile();
      if (!mounted) return;
      setState(() {
        _eligible = value;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addContact() async {
    if (_contacts.length >= 5) {
      _message('You can add up to 5 safety contacts.');
      return;
    }
    final name = TextEditingController();
    final phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) {
        return AlertDialog(
          title: const Text('Add safety contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('ADD'),
            ),
          ],
        );
      },
    );
    if (ok == true && name.text.trim().isNotEmpty && phone.text.trim().isNotEmpty && mounted) {
      setState(() {
        _contacts.add(_SafetyContact(name.text.trim(), phone.text.trim()));
      });
    }
    name.dispose();
    phone.dispose();
  }

  Future<void> _send() async {
    if (!_eligible || _sending) return;
    final firstAlert = _escalation == 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(firstAlert ? 'Send Safety Alert?' : 'Escalate Emergency?'),
          content: Text(
            firstAlert
                ? 'Your exact location will be shared with the MANOX safety response flow.'
                : 'Your exact location will be shared with opted-in nearby MANOX safety users.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(firstAlert ? 'SEND ALERT' : 'ESCALATE'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    setState(() => _sending = true);
    try {
      await SafetyAlertService.sendAlert(escalation: _escalation);
      if (!mounted) return;
      _message(firstAlert ? 'Safety Alert sent.' : 'Emergency alert escalated.');
      setState(() => _escalation = 2);
    } catch (e) {
      if (mounted) {
        _message(e is SafetyAlertException ? e.message : 'Could not send the Safety Alert.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final canSend = _eligible && !_sending;
    final contactTiles = _contacts.map((contact) {
      return ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(contact.name),
        subtitle: Text(contact.phone),
        trailing: IconButton(
          tooltip: 'Remove contact',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => setState(() => _contacts.remove(contact)),
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Women Safety')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.emergency_rounded, size: 54),
                  const SizedBox(height: 12),
                  const Text(
                    'MANOX Women Safety',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _eligible
                        ? 'Safety Alert is ready. Location is requested only when you send an alert.'
                        : 'Set Gender to Female in Edit Profile to activate Women Safety.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: canSend ? _send : null,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sos_rounded),
                      label: Text(_escalation == 1 ? 'SEND SAFETY ALERT' : 'ESCALATE EMERGENCY'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.contact_emergency_outlined),
                  title: const Text('Emergency contacts'),
                  subtitle: Text('${_contacts.length}/5 contacts added'),
                  trailing: IconButton(
                    tooltip: 'Add contact',
                    onPressed: _addContact,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                  ),
                ),
                ...contactTiles,
                if (_contacts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 18),
                    child: Text(
                      'Add trusted contacts who can be notified during a safety emergency.',
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text('Privacy-first design'),
              subtitle: Text(
                'Exact location is not shared until an alert is confirmed. Safety access is controlled by the verified profile gender field.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyContact {
  final String name;
  final String phone;
  const _SafetyContact(this.name, this.phone);
}
