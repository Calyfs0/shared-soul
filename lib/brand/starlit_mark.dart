import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/soul_colors.dart';

/// Crisp crescent + gold spark — Shared Soul logo mark.
class StarlitMark extends StatelessWidget {
  const StarlitMark({
    super.key,
    this.size = 120,
    this.starPulse = 1,
  });

  final double size;

  /// 0–1 soft pulse for splash loading (1 = steady).
  final double starPulse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StarlitMarkPainter(starPulse: starPulse),
      ),
    );
  }
}

class _StarlitMarkPainter extends CustomPainter {
  _StarlitMarkPainter({required this.starPulse});

  final double starPulse;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.48, size.height * 0.5);
    final r = size.shortestSide * 0.34;

    // Crescent: full disc minus offset disc.
    final moon = Path()
      ..addOval(Rect.fromCircle(center: c, radius: r));
    final cut = Path()
      ..addOval(
        Rect.fromCircle(
          center: c.translate(r * 0.42, -r * 0.06),
          radius: r * 0.92,
        ),
      );
    final crescent = Path.combine(PathOperation.difference, moon, cut);

    canvas.drawPath(
      crescent,
      Paint()
        ..color = SoulColors.warmIvory.withValues(alpha: 0.96)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // Gold four-point spark in the hollow.
    final sparkCenter = c.translate(-r * 0.18, r * 0.02);
    final sparkR = r * (0.22 + 0.04 * starPulse);
    final spark = _sparkPath(sparkCenter, sparkR);
    final gold = SoulColors.celestialGold.withValues(
      alpha: 0.75 + 0.25 * starPulse,
    );
    canvas.drawPath(spark, Paint()..color = gold..isAntiAlias = true);
  }

  Path _sparkPath(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + i * math.pi / 2;
      final outer = Offset(
        center.dx + math.cos(a) * radius,
        center.dy + math.sin(a) * radius,
      );
      final midA = a + math.pi / 4;
      final inner = Offset(
        center.dx + math.cos(midA) * radius * 0.28,
        center.dy + math.sin(midA) * radius * 0.28,
      );
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _StarlitMarkPainter oldDelegate) =>
      oldDelegate.starPulse != starPulse;
}
