import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreatorPage extends StatelessWidget {
  const CreatorPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Creator', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('Creator Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        SizedBox(height: 8), Text('Overview of your content, analytics and monetization settings.'),
      ]))),
      const SizedBox(height: 12),
      Card(child: ListTile(leading: const Icon(Icons.video_library_outlined), title: const Text('Content'), subtitle: const Text('Your posts and drafts'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => context.push('/profile'))),
      const SizedBox(height: 10),
      Card(child: ListTile(leading: const Icon(Icons.currency_rupee_rounded), title: const Text('Monetization', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Eligibility, earnings and monetization terms'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => context.push('/monetization'))),
      const SizedBox(height: 10),
      Card(child: ListTile(leading: const Icon(Icons.account_balance_wallet_outlined), title: const Text('Payout / Withdrawal', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Payout account, verification and withdrawal'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => context.push('/payout'))),
    ]),
  );
}
