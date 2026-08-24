import 'package:flutter/material.dart';

class ManoxMark extends StatelessWidget {
  final double size;
  const ManoxMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _ManoxMarkPainter()));
  }
}

class ManoxBrand extends StatelessWidget {
  final bool compact;
  const ManoxBrand({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ManoxMark(size: compact ? 34 : 42),
        const SizedBox(width: 10),
        Text(
          'MANOX',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: compact ? 18 : 22,
            fontWeight: FontWeight.w800,
            letterSpacing: compact ? 2.4 : 3.2,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _ManoxMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .105
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;
    final w = size.width;
    final h = size.height;
    final p = Path()
      ..moveTo(w * .18, h * .78)
      ..lineTo(w * .18, h * .22)
      ..lineTo(w * .50, h * .58)
      ..lineTo(w * .82, h * .22)
      ..lineTo(w * .82, h * .78);
    canvas.drawPath(p, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
