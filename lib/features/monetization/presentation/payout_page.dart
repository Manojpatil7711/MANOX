import 'package:flutter/material.dart';

class PayoutPage extends StatelessWidget {
  const PayoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Payout balance', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text('₹0.00', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                  SizedBox(height: 8),
                  Text('Your payout becomes available after eligible earnings, verification and the applicable minimum threshold.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: const [
                ListTile(leading: Icon(Icons.verified_user_outlined), title: Text('Identity verification'), subtitle: Text('Required before payouts are enabled.')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.account_balance_outlined), title: Text('Payout account'), subtitle: Text('Add an eligible bank or supported payout account after verification.')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.history), title: Text('Payout history'), subtitle: Text('Your completed and pending payout records will appear here.')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.currency_rupee),
            label: const Text('Withdraw'),
          ),
          const SizedBox(height: 8),
          const Text('Withdraw is disabled until the account meets MANOX payout requirements.', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
