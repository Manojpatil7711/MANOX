import 'package:flutter/material.dart';

class PayoutPage extends StatelessWidget {
  const PayoutPage({super.key});

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
              Text('MANOX Payout Terms', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              SizedBox(height: 12),
              Text('Withdrawals are available only after eligible earnings, required verification and the applicable minimum threshold. Payout details must belong to the verified account holder.'),
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
      appBar: AppBar(title: const Text('Payout / Withdrawal')),
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
              children: const [
                ListTile(leading: Icon(Icons.verified_user_outlined), title: Text('Identity verification'), subtitle: Text('Required before withdrawals are enabled.')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.account_balance_outlined), title: Text('Payout account'), subtitle: Text('Add an eligible bank or supported payout account after verification.')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.history), title: Text('Payout history'), subtitle: Text('Completed, pending and rejected payout records appear here.')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Withdrawal Terms'),
              subtitle: const Text('Active • View withdrawal rules'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showTerms(context),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.currency_rupee),
            label: const Text('Withdraw'),
          ),
          const SizedBox(height: 8),
          const Text('Withdraw is disabled until MANOX payout requirements are met.', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
