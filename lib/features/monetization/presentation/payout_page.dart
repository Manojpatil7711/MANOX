import 'package:flutter/material.dart';

class PayoutPage extends StatefulWidget {
  const PayoutPage({super.key});

  @override
  State<PayoutPage> createState() => _PayoutPageState();
}

class _PayoutPageState extends State<PayoutPage> {
  bool _identityReady = false;
  bool _accountReady = false;

  void _showSetup(String title, String message, {required bool identity}) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(message),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheet);
                    setState(() {
                      if (identity) {
                        _identityReady = true;
                      } else {
                        _accountReady = true;
                      }
                    });
                  },
                  child: const Text('Mark setup complete'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTerms() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MANOX Payout Terms', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              SizedBox(height: 12),
              Text('Withdrawals require eligible earnings, required verification and the applicable minimum threshold. Payout details must belong to the verified account holder.'),
              SizedBox(height: 12),
              Text('KYC, PAN and bank payout identity must match before payout is enabled.', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payout / Withdrawal', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Withdrawable balance', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text('₹0.00', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                  SizedBox(height: 8),
                  Text('Withdrawal becomes available after eligible earnings, verification and the applicable minimum threshold.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(_identityReady ? Icons.verified : Icons.verified_user_outlined),
                  title: const Text('Identity verification'),
                  subtitle: Text(_identityReady ? 'Setup marked complete.' : 'Required before withdrawals are enabled.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showSetup(
                    'Identity verification',
                    'Connect MANOX KYC/PAN verification here. This screen does not collect or expose sensitive identity data.',
                    identity: true,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(_accountReady ? Icons.account_balance : Icons.account_balance_outlined),
                  title: const Text('Payout account'),
                  subtitle: Text(_accountReady ? 'Setup marked complete.' : 'Add an eligible bank or supported payout account after verification.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showSetup(
                    'Payout account',
                    'Connect the verified payout account flow here. Bank details must match the verified payout identity.',
                    identity: false,
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Payout history'),
                  subtitle: Text('Completed, pending and rejected payout records appear here.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Withdrawal Terms'),
              subtitle: const Text('Active • View withdrawal rules'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _showTerms,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.currency_rupee),
            label: const Text('Withdraw'),
          ),
          const SizedBox(height: 8),
          Text(
            'Withdraw is disabled until eligible earnings, identity verification and payout-account requirements are met.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
