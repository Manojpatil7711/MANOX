import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MonetizationPage extends StatelessWidget {
  const MonetizationPage({super.key});

  void _showTerms(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MANOX Monetization Terms', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              SizedBox(height: 12),
              Text('Monetization is subject to eligible content, genuine engagement, identity verification, applicable payout rules and MANOX review. Earnings are not guaranteed and may be adjusted for invalid activity.'),
              SizedBox(height: 12),
              Text('Payout identity must match the verified KYC, PAN and bank payout records.', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

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
                  const Text('Earn from eligible content and genuine engagement. Earnings follow MANOX eligibility, verification and payout rules.'),
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
              title: const Text('Payout / Withdrawal'),
              subtitle: const Text('Open payout balance, withdrawal and payout history.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/payout'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Monetization Terms'),
              subtitle: const Text('Active • View terms and payout rules'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showTerms(context),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sensitive KYC data is never shown on the public profile. Payout identity must match verified payout records.'),
            ),
          ),
        ],
      ),
    );
  }
}
