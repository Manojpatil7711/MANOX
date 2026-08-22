import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;
  bool _privateAccount = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('Private account'),
            value: _privateAccount,
            onChanged: (v) => setState(() => _privateAccount = v),
          ),
          const Divider(),
          const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('Enable notifications'),
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
          ),
          const Divider(),
          const Text('Privacy & Security', style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(
            title: const Text('Password & security'),
            subtitle: const Text('Server-side only'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
