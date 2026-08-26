import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LivePage extends StatelessWidget {
  const LivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          FilledButton.icon(
            onPressed: () => _showStartLive(context),
            icon: const Icon(Icons.videocam_rounded),
            label: const Text('Start Live'),
          ),
          const SizedBox(height: 18),
          const Text(
            'Live creators',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _creatorTile(context, 'MANOX Creator', '@manox_creator'),
          _creatorTile(context, 'Creator Studio', '@creator_studio'),
          _creatorTile(context, 'MANOX Live', '@manox_live'),
        ],
      ),
    );
  }

  Widget _creatorTile(BuildContext context, String name, String handle) => Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person_outline_rounded)),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(handle),
          trailing: const Icon(Icons.play_circle_outline_rounded),
          onTap: () => context.push('/profile'),
        ),
      );

  void _showStartLive(BuildContext context) {
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
              const Text('Start Live', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              const Text('Camera and live-stream publishing will start after the streaming service is connected.'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheet),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
