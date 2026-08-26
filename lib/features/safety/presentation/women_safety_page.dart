import 'package:flutter/material.dart';
import '../safety_alert_service.dart';

class WomenSafetyPage extends StatefulWidget {
  const WomenSafetyPage({super.key});
  @override State<WomenSafetyPage> createState() => _WomenSafetyPageState();
}

class _WomenSafetyPageState extends State<WomenSafetyPage> {
  bool _eligible = false;
  bool _loading = true;
  bool _sending = false;
  int _escalation = 1;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final value = await SafetyAlertService.isFemaleProfile();
      if (mounted) setState(() { _eligible = value; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (!_eligible || _sending) return;
    final title = _escalation == 1 ? 'Send Safety Alert?' : 'Escalate Emergency?';
    final message = _escalation == 1
        ? 'Your exact location will be shared with the MANOX safety response flow.'
        : 'Your exact location will be shared with opted-in nearby MANOX safety users.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(_escalation == 1 ? 'SEND ALERT' : 'ESCALATE')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _sending = true);
    try {
      await SafetyAlertService.sendAlert(escalation: _escalation);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_escalation == 1 ? 'Safety Alert sent.' : 'Emergency alert escalated.')));
      setState(() => _escalation = 2);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is SafetyAlertException ? e.message : 'Could not send the Safety Alert.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
            const Icon(Icons.emergency_rounded, size: 54),
            const SizedBox(height: 12),
            const Text('MANOX Women Safety', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(_eligible ? 'Safety Alert is ready. Location is requested only when you send an alert.' : 'Set Gender to Female in Edit Profile to activate Women Safety.', textAlign: TextAlign.center),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: _eligible && !_sending ? _send : null,
              icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sos_rounded),
              label: Text(_escalation == 1 ? 'SEND SAFETY ALERT' : 'ESCALATE EMERGENCY'),
            )),
          ]))),
          const SizedBox(height: 12),
          const Card(child: ListTile(leading: Icon(Icons.privacy_tip_outlined), title: Text('Privacy-first design'), subtitle: Text('Exact location is not shared until an alert is confirmed. Safety access is controlled by the verified profile gender field.'))),
        ],
      );
    }
    return Scaffold(appBar: AppBar(title: const Text('Women Safety')), body: body);
  }
}
