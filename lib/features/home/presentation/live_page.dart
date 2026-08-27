import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../data/supabase_post_repository.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});
  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  final _picker = ImagePicker();
  final _repository = SupabasePostRepository();
  bool _starting = false;
  bool _loading = true;
  List<ManoxPost> _creators = const [];

  @override
  void initState() {
    super.initState();
    _loadCreators();
  }

  Future<void> _loadCreators() async {
    try {
      final posts = await _repository.fetchFeed();
      final seen = <String>{};
      final unique = posts
          .where((p) => p.ownerUserId != null && seen.add(p.ownerUserId!))
          .take(20)
          .toList();
      if (mounted) setState(() { _creators = unique; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startLive() async {
    setState(() => _starting = true);
    try {
      final clip = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(hours: 1),
      );
      if (!mounted) return;
      if (clip != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera is ready. Connect the MANOX streaming backend for live broadcast.')),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera unavailable: ${e.message ?? 'unknown error'}')),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _openLiveRoom(ManoxPost creator) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LiveRoomSheet(creator: creator),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Live', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.live_tv_rounded, size: 56),
                    const SizedBox(height: 12),
                    const Text('Go Live', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    const Text('Start your creator broadcast from MANOX.', textAlign: TextAlign.center),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _starting ? null : _startLive,
                      icon: const Icon(Icons.videocam_rounded),
                      label: Text(_starting ? 'Opening camera…' : 'Start Live'),
                    ),
                    const SizedBox(height: 8),
                    const Text('Camera access is wired. Connect the streaming backend to broadcast in real time.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Live creators', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_creators.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Text('No creators available yet.'))
            else
              ..._creators.map(
                (creator) => Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(creator.creatorName.isEmpty ? 'M' : creator.creatorName[0].toUpperCase())),
                    title: Text(creator.creatorName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${creator.handle} • Live interaction'),
                    trailing: const Icon(Icons.play_circle_fill_rounded),
                    onTap: () => _openLiveRoom(creator),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _LiveRoomSheet extends StatefulWidget {
  final ManoxPost creator;
  const _LiveRoomSheet({required this.creator});
  @override
  State<_LiveRoomSheet> createState() => _LiveRoomSheetState();
}

class _LiveRoomSheetState extends State<_LiveRoomSheet> {
  final _commentController = TextEditingController();
  bool _liked = false;
  int _likes = 0;
  int _comments = 0;
  double _sessionEarnings = 0;
  String? _selectedGift;

  static const List<double> _giftAmounts = <double>[
    0.05, 0.10, 0.25, 0.50, 1, 2, 5, 10, 25, 50, 100,
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
  }

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments++;
      _commentController.clear();
    });
  }

  Future<void> _openGiftPicker() async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send a gift 🎁', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Choose an amount from ₹0.05 to ₹100.'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _giftAmounts.map((value) => OutlinedButton.icon(
                  onPressed: () => Navigator.of(sheetContext).pop(value),
                  icon: const Text('🎁'),
                  label: Text('₹${value.toStringAsFixed(value < 1 ? 2 : 0)}'),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || amount == null) return;
    setState(() => _selectedGift = '₹${amount.toStringAsFixed(amount < 1 ? 2 : 0)}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gift ${_selectedGift!} selected. Payment backend is required to send real money.')),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * .86,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.red, size: 12),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${widget.creator.creatorName} • LIVE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, color: Colors.white)),
                  ],
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text('LIVE VIDEO\nStreaming backend required', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 18)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _LiveAction(icon: Icons.favorite_rounded, label: '$_likes', onTap: _toggleLike),
                    _LiveAction(icon: Icons.mode_comment_outlined, label: '$_comments', onTap: () => FocusScope.of(context).requestFocus()),
                    _LiveAction(icon: Icons.card_giftcard_rounded, label: _selectedGift ?? 'Gift', onTap: _openGiftPicker),
                    const _LiveAction(icon: Icons.currency_rupee_rounded, label: '₹ 🔒', onTap: null),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(12, 4, 12, MediaQuery.of(context).viewInsets.bottom + 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.white),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendComment(),
                        decoration: InputDecoration(
                          hintText: 'Write a comment…',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(onPressed: _sendComment, icon: const Icon(Icons.send_rounded, color: Colors.white)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text('Creator earnings: ₹ 🔒  •  Monetization locked until payout/KYC is enabled.', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ],
          ),
        ),
      );
}

class _LiveAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _LiveAction({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Column(
        children: [
          IconButton(
            onPressed: onTap,
            icon: Icon(icon, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white12),
          ),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      );
}
