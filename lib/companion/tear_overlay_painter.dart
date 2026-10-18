import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/soul_colors.dart';

/// Tears + floor spirals drawn over the Cloud Friend PNG when lonely.
class TearOverlayPainter extends CustomPainter {
  TearOverlayPainter({required this.phase, required this.intensity});

  final double phase;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity < 0.05) return;

    final cx = size.width * 0.5;
    // Eyes roughly in upper-middle of this mascot art
    final eyeY = size.height * 0.42;
    final eyeSpread = size.width * 0.11;
    final floorY = size.height * 0.88;

    _spirals(canvas, size, floorY);

    for (var i = 0; i < 4; i++) {
      final left = i.isEven;
      final eye = Offset(cx + (left ? -eyeSpread : eyeSpread), eyeY);
      final t = (phase + i * 0.23) % 1.0;
      final fall = Curves.easeIn.transform(t);
      final y = eye.dy + (floorY - eye.dy) * fall;
      final x = eye.dx + math.sin(t * math.pi * 2 + i) * size.width * 0.008;
      final alpha =
          intensity *
          (t < 0.08
              ? t / 0.08
              : t > 0.88
              ? (1 - t) / 0.12
              : 1.0);
      if (alpha <= 0.02) continue;

      final r = size.shortestSide * 0.012;
      final pos = Offset(x, y);
      final tear = Path()
        ..moveTo(pos.dx, pos.dy - r * 1.6)
        ..quadraticBezierTo(pos.dx + r * 0.9, pos.dy, pos.dx, pos.dy + r * 1.1)
        ..quadraticBezierTo(pos.dx - r * 0.9, pos.dy, pos.dx, pos.dy - r * 1.6)
        ..close();
      canvas.drawPath(
        tear,
        Paint()..color = SoulColors.starBlue.withValues(alpha: 0.65 * alpha),
      );
      canvas.drawCircle(
        Offset(pos.dx - r * 0.2, pos.dy - r * 0.25),
        r * 0.25,
        Paint()..color = Colors.white.withValues(alpha: 0.55 * alpha),
      );
    }
  }

  void _spirals(Canvas canvas, Size size, double floorY) {
    for (var i = 0; i < 4; i++) {
      final t = (phase + i * 0.23) % 1.0;
      late final double age;
      if (t >= 0.88) {
        age = (t - 0.88) / 0.12;
      } else if (t < 0.55) {
        age = 1.0 - (t / 0.55) * 0.65;
      } else {
        continue;
      }

      final left = i.isEven;
      final cx =
          size.width * 0.5 +
          (left ? -1 : 1) * size.width * (0.08 + (i % 2) * 0.05);
      final cy = floorY + (i % 3) * size.height * 0.01;
      final alpha = intensity * age.clamp(0.0, 1.0) * 0.75;
      final radius = size.shortestSide * (0.035 + age * 0.07);
      final spin = phase * math.pi * 2 * 0.35 + i * 0.8;

      final path = Path();
      for (var j = 0; j <= 56; j++) {
        final p = j / 56;
        final ang = spin + p * 2.4 * math.pi * 2;
        final r = radius * p;
        final point = Offset(
          cx + math.cos(ang) * r,
          cy + math.sin(ang) * r * 0.38,
        );
        if (j == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = SoulColors.starBlue.withValues(alpha: 0.5 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.shortestSide * 0.008
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TearOverlayPainter oldDelegate) {
    return phase != oldDelegate.phase || intensity != oldDelegate.intensity;
  }
}
