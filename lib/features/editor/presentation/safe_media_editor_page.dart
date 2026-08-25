import 'package:flutter/material.dart';
import 'media_editor_page.dart';

/// Safety wrapper for the editor route. Prevents accidental root-pop/app exit
/// and gives the user an explicit exit action.
class SafeMediaEditorPage extends StatefulWidget {
  final bool isVideo;
  final String? mediaPath;

  const SafeMediaEditorPage({super.key, required this.isVideo, this.mediaPath});

  @override
  State<SafeMediaEditorPage> createState() => _SafeMediaEditorPageState();
}

class _SafeMediaEditorPageState extends State<SafeMediaEditorPage> {
  bool _dialogOpen = false;

  Future<void> _handleBack() async {
    if (_dialogOpen || !mounted) return;
    _dialogOpen = true;
    try {
      final leave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Leave editor?'),
          content: const Text('Your current editing session will be closed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('STAY'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('LEAVE'),
            ),
          ],
        ),
      );
      if (leave == true && mounted) {
        Navigator.of(context).pop(false);
      }
    } finally {
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: MediaEditorPage(
        isVideo: widget.isVideo,
        mediaPath: widget.mediaPath,
      ),
    );
  }
}
