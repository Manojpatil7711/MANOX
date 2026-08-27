import 'package:flutter/material.dart';

/// Safe, non-dispatching test harness for MANOX Women Safety.
/// This screen never sends SMS/WhatsApp, never contacts police, and never
/// shares a real location. Production dispatch must be implemented only
/// through an authorized emergency provider and explicit user consent.
class WomenSafetyTestMode extends StatefulWidget {
  const WomenSafetyTestMode({super.key});

  @override
  State<WomenSafetyTestMode> createState() => _WomenSafetyTestModeState();
}

class _WomenSafetyTestModeState extends State<WomenSafetyTestMode> {
  bool _femaleProfile = false;
  bool _emergencyConfirmed = false;
  int _falseAlarmReports = 0;
  final List<String> _contacts = [];

  void _activate() => setState(() => _femaleProfile = true);

  void _addContact() {
    if (_contacts.length >= 5) return;
    setState(() => _contacts.add('Emergency contact ${_contacts.length + 1}'));
  }

  Future<void> _testEmergency() async {
    if (!_femaleProfile) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TEST EMERGENCY'),
        content: const Text(
          'Testing only. No SMS, WhatsApp message, police notification, or real location will be sent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CONFIRM TEST'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _emergencyConfirmed = true);
    }
  }

  void _reportFalseAlarm() {
    if (_falseAlarmReports >= 3) return;
    setState(() => _falseAlarmReports++);
  }

  @override
  Widget build(BuildContext context) {
    final active = _femaleProfile;
    return Scaffold(
      appBar: AppBar(title: const Text('Women Safety — Test Mode')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                active ? Icons.verified : Icons.lock_outline,
              ),
              title: const Text('Women Safety'),
              subtitle: Text(
                active
                    ? 'ACTIVE — emergency action requires confirmation'
                    : 'Set Gender = Female to activate for testing',
              ),
              trailing: Switch(
                value: active,
                onChanged: active ? null : (_) => _activate(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.contacts_outlined),
                  title: Text('Trusted emergency contacts'),
                  subtitle: Text('Maximum 5 contacts'),
                ),
                ..._contacts.map(
                  (contact) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.person_outline),
                    title: Text(contact),
                  ),
                ),
                if (_contacts.length < 5)
                  TextButton.icon(
                    onPressed: _addContact,
                    icon: const Icon(Icons.add),
                    label: const Text('Add test contact'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: active ? _testEmergency : null,
            icon: const Icon(Icons.sos),
            label: const Text('TEST SOS'),
          ),
          if (_emergencyConfirmed)
            const Card(
              child: ListTile(
                leading: Icon(Icons.check_circle_outline),
                title: Text('Test emergency confirmed'),
                subtitle: Text(
                  'Simulated only. No external dispatch occurred.',
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _falseAlarmReports < 3 ? _reportFalseAlarm : null,
            icon: const Icon(Icons.report_outlined),
            label: Text('Simulate confirmed false-alarm report ($_falseAlarmReports/3)'),
          ),
          if (_falseAlarmReports >= 3)
            const Card(
              child: ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('Monetization restriction TEST flag'),
                subtitle: Text(
                  'Six-month restriction flag simulated. A real enforcement decision must be server-side and reviewable.',
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.security_outlined),
              title: Text('Safety & privacy'),
              subtitle: Text(
                'Real location sharing must require explicit consent and an authorized emergency integration. Offline mode can queue an alert locally, but cannot deliver internet messages without a network.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
