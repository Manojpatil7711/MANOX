import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../services/supabase_service.dart';
import '../../../core/widgets/manox_brand.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _tagline = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController _brand = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _play();
  }

  Future<void> _play() async {
    await _tagline.forward();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    await _brand.forward();
    if (!mounted) return;
    _timer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      final session = SupabaseService.client?.auth.currentSession;
      context.go(session == null ? '/auth' : '/home');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tagline.dispose();
    _brand.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taglineOpacity = CurvedAnimation(parent: _tagline, curve: Curves.easeOut);
    final brandOpacity = CurvedAnimation(parent: _brand, curve: Curves.easeOut);
    final brandScale = Tween<double>(begin: .84, end: 1).animate(CurvedAnimation(parent: _brand, curve: Curves.easeOutBack));
    return Scaffold(
      backgroundColor: const Color(0xFF050506),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            FadeTransition(
              opacity: ReverseAnimation(taglineOpacity),
              child: const Text('WEAR YOUR IDENTITY', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 3.0)),
            ),
            FadeTransition(
              opacity: brandOpacity,
              child: ScaleTransition(
                scale: brandScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ManoxBrand(compact: false),
                    const SizedBox(height: 12),
                    Text(
                      'BEATS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 5.0,
                        shadows: [Shadow(color: Colors.white.withValues(alpha: .28), blurRadius: 8)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
