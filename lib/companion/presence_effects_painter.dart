import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/soul_colors.dart';

/// Floating embers / dust that make the companion feel present in the space.
class PresenceEffectsPainter extends CustomPainter {
  PresenceEffectsPainter({
    required this.phase,
    required this.glow,
    required this.energy,
  });

  final double phase;
  final double glow;
  final double energy;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.52);
    final rng = math.Random(7);

    for (var i = 0; i < 14; i++) {
      final seed = rng.nextDouble();
      final orbit = 0.22 + seed * 0.38;
      final speed = 0.4 + seed * 0.9;
      final t = (phase * speed + seed) % 1.0;
      final ang = seed * math.pi * 2 + t * math.pi * 2 * (i.isEven ? 1 : -1);
      final pulse = (math.sin((t + seed) * math.pi * 2) + 1) / 2;
      final dist = size.shortestSide * orbit * (0.85 + pulse * 0.15);
      final p =
          center + Offset(math.cos(ang) * dist, math.sin(ang) * dist * 0.75);
      final alpha = (0.15 + glow * 0.55) * pulse * (0.4 + energy * 0.6);
      final r = (1.4 + seed * 2.4) * (0.7 + glow * 0.5);

      canvas.drawCircle(
        p,
        r * 2.2,
        Paint()
          ..color = SoulColors.ember.withValues(alpha: alpha * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        p,
        r,
        Paint()..color = SoulColors.emberCore.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant PresenceEffectsPainter oldDelegate) {
    return phase != oldDelegate.phase ||
        glow != oldDelegate.glow ||
        energy != oldDelegate.energy;
  }
}
