import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MonetizationPage extends StatelessWidget {
  const MonetizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monetization')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MANOX Monetization', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('Earn from eligible content and engagement. Earnings are subject to MANOX eligibility, verification and payout rules.'),
                  const SizedBox(height: 16),
                  const Row(children: [Icon(Icons.currency_rupee), SizedBox(width: 8), Text('Available earnings', style: TextStyle(fontWeight: FontWeight.w700))]),
                  const SizedBox(height: 8),
                  const Text('₹0.00', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Payout'),
              subtitle: const Text('Manage payout details and withdrawal status.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/payout'),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Payouts require verified identity and eligible payout details. MANOX does not display or expose sensitive KYC data in the public profile.'),
            ),
          ),
        ],
      ),
    );
  }
}
