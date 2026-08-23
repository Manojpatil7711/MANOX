import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/manox_brand.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) context.go('/auth');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050506),
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: .94, end: 1).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
            ),
            child: const ManoxBrand(),
          ),
        ),
      ),
    );
  }
}
