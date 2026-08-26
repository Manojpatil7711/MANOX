import 'package:flutter/material.dart';
import '../safety_alert_service.dart';

class SafetyAlertOverlay extends StatefulWidget {
  final Widget child;
  const SafetyAlertOverlay({super.key, required this.child});

  @override
  State<SafetyAlertOverlay> createState() => _SafetyAlertOverlayState();
}

class _SafetyAlertOverlayState extends State<SafetyAlertOverlay> {
  bool _eligible = false;
  bool _sending = false;
  int _escalation = 1;

  @override
  void initState() {
    super.initState();
    _loadEligibility();
  }

  Future<void> _loadEligibility() async {
    try {
      final eligible = await SafetyAlertService.isFemaleProfile();
      if (mounted) setState(() => _eligible = eligible);
    } catch (_) {}
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final id = await SafetyAlertService.sendAlert(escalation: _escalation);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_escalation == 1
            ? 'Safety Alert sent to verified responders.'
            : 'Emergency alert escalated to nearby opted-in users.')),
      );
      setState(() => _escalation = 2);
      debugPrint('MANOX safety alert: $id');
    } on SafetyAlertException catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) _showError('Could not send the Safety Alert. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirm() async {
    if (_escalation == 1) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Send Safety Alert?'),
          content: const Text('Your current exact location will be shared with verified nearby police or social workers.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('SEND ALERT')),
          ],
        ),
      );
      if (confirmed != true) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Escalate Emergency?'),
          content: const Text('This sends a danger alert with your exact location to nearby MANOX users who opted into safety alerts.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ESCALATE')),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await _send();
  }

  @override
  Widget build(BuildContext context) {
    if (!_eligible) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          right: 14,
          bottom: 86,
          child: SafeArea(
            child: Semantics(
              button: true,
              label: _escalation == 1 ? 'Emergency Safety Alert' : 'Escalate Emergency Safety Alert',
              child: Material(
                elevation: 7,
                shape: const CircleBorder(),
                color: Theme.of(context).colorScheme.error,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _confirm,
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: Center(
                      child: _sending
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.emergency, color: Colors.white, size: 25),
                                Text('SOS ${_escalation}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
