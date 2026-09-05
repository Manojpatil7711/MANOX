import 'package:flutter/material.dart';

class PayoutPage extends StatefulWidget {
  const PayoutPage({super.key});

  @override
  State<PayoutPage> createState() => _PayoutPageState();
}

class _PayoutPageState extends State<PayoutPage> {
  bool _identityReady = false;
  bool _accountReady = false;

  bool get _canWithdraw => _identityReady && _accountReady;

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
              Text('Production KYC/payout verification must be connected before this requirement can be marked complete.', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheet),
                  child: const Text('CLOSE'),
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

  void _withdraw() {
    if (_canWithdraw) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request flow is ready for the connected payout service.')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal is locked: eligible earnings, KYC and payout account are required.')));
  }

  void _showHistory() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Payout history', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              SizedBox(height: 12),
              Icon(Icons.receipt_long_outlined, size: 42),
              SizedBox(height: 8),
              Text('No payout records yet.'),
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('Withdrawable balance', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text('₹0.00', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                SizedBox(height: 8),
                Text('Withdrawal becomes available after eligible earnings, verification and the applicable minimum threshold.'),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(children: [
              ListTile(
                leading: Icon(_identityReady ? Icons.verified : Icons.verified_user_outlined),
                title: const Text('Identity verification'),
                subtitle: Text(_identityReady ? 'Verified' : 'Required before withdrawals are enabled.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showSetup('Identity verification', 'MANOX KYC/PAN verification belongs in a secure production verification service. Sensitive identity documents should not be stored in this UI.', identity: true),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(_accountReady ? Icons.account_balance : Icons.account_balance_outlined),
                title: const Text('Payout account'),
                subtitle: Text(_accountReady ? 'Connected' : 'Required after identity verification.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showSetup('Payout account', 'Connect the verified bank/UPI payout service here. Account ownership must match the verified identity.', identity: false),
              ),
              const Divider(height: 1),
              ListTile(leading: const Icon(Icons.history), title: const Text('Payout history'), subtitle: const Text('Completed, pending and rejected payout records.'), trailing: const Icon(Icons.chevron_right_rounded), onTap: _showHistory),
            ]),
          ),
          const SizedBox(height: 12),
          Card(child: ListTile(leading: const Icon(Icons.description_outlined), title: const Text('Withdrawal Terms'), subtitle: const Text('Active • View withdrawal rules'), trailing: const Icon(Icons.chevron_right_rounded), onTap: _showTerms)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _withdraw, icon: const Icon(Icons.currency_rupee), label: const Text('WITHDRAW')),
          const SizedBox(height: 8),
          Text(_canWithdraw ? 'Withdrawal service ready.' : 'Locked until eligible earnings, identity verification and payout-account requirements are satisfied.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
