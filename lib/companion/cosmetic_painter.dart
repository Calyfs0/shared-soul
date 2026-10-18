import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/soul_colors.dart';
import 'cosmetic.dart';

/// Draws equipped cosmetics in creature-local space (same origin as painter).
class CosmeticPainter {
  CosmeticPainter({
    required this.cosmetic,
    required this.s,
    required this.faceOrigin,
    required this.headTilt,
  });

  final CompanionCosmetic cosmetic;
  final double s;
  final Offset faceOrigin;
  final double headTilt;

  void paintBehindFace(Canvas canvas) {
    if (cosmetic == CompanionCosmetic.cozyScarf) {
      _scarf(canvas);
    }
  }

  void paintOnHead(Canvas canvas) {
    canvas.save();
    canvas.translate(faceOrigin.dx, faceOrigin.dy - s * 0.02);
    canvas.rotate(headTilt * 0.6);

    switch (cosmetic) {
      case CompanionCosmetic.starBeret:
        _starBeret(canvas);
        break;
      case CompanionCosmetic.roundGlasses:
        _glasses(canvas);
        break;
      case CompanionCosmetic.flowerClip:
        _flowerClip(canvas);
        break;
      case CompanionCosmetic.moonBow:
        _moonBow(canvas);
        break;
      case CompanionCosmetic.none:
      case CompanionCosmetic.cozyScarf:
        break;
    }

    canvas.restore();
  }

  void _starBeret(Canvas canvas) {
    final cap = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(0, -s * 0.42),
          width: s * 0.72,
          height: s * 0.38,
        ),
      );
    canvas.drawPath(
      cap,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(-s * 0.2, -s * 0.55),
          Offset(s * 0.2, -s * 0.3),
          const [Color(0xFF6B8FD4), Color(0xFF4A6BB0)],
        ),
    );
    canvas.drawPath(
      cap,
      Paint()
        ..color = const Color(0xFF3A4A6A).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.08, -s * 0.32),
        width: s * 0.55,
        height: s * 0.12,
      ),
      Paint()..color = const Color(0xFF5A7EC4),
    );

    _star(
      canvas,
      Offset(-s * 0.05, -s * 0.48),
      s * 0.08,
      Paint()..color = SoulColors.starYellow,
    );
  }

  void _glasses(Canvas canvas) {
    final y = -s * 0.02;
    final spread = s * 0.17;
    final r = s * 0.11;
    final stroke = Paint()
      ..color = const Color(0xFF4A3A32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.028
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(-spread, y), r, stroke);
    canvas.drawCircle(Offset(spread, y), r, stroke);
    canvas.drawLine(
      Offset(-spread + r * 0.85, y),
      Offset(spread - r * 0.85, y),
      stroke,
    );
    final tint = Paint()..color = SoulColors.starBlue.withValues(alpha: 0.12);
    canvas.drawCircle(Offset(-spread, y), r * 0.85, tint);
    canvas.drawCircle(Offset(spread, y), r * 0.85, tint);
  }

  void _scarf(Canvas canvas) {
    final scarf = Path()
      ..moveTo(-s * 0.42, s * 0.05)
      ..quadraticBezierTo(0, s * 0.22, s * 0.42, s * 0.05)
      ..quadraticBezierTo(s * 0.38, s * 0.32, s * 0.15, s * 0.38)
      ..lineTo(s * 0.08, s * 0.55)
      ..lineTo(-s * 0.02, s * 0.4)
      ..quadraticBezierTo(-s * 0.35, s * 0.28, -s * 0.42, s * 0.05)
      ..close();

    canvas.drawPath(
      scarf,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, s * 0.05),
          Offset(0, s * 0.5),
          const [Color(0xFFFF8A9A), Color(0xFFE85A6E)],
        ),
    );
    canvas.drawLine(
      Offset(-s * 0.25, s * 0.18),
      Offset(s * 0.25, s * 0.18),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = s * 0.03
        ..strokeCap = StrokeCap.round,
    );
  }

  void _flowerClip(Canvas canvas) {
    final c = Offset(s * 0.28, -s * 0.35);
    const petal = Color(0xFFFFB0C8);
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * (math.pi * 2 / 5);
      final p = c + Offset(math.cos(a) * s * 0.08, math.sin(a) * s * 0.08);
      canvas.drawCircle(p, s * 0.055, Paint()..color = petal);
    }
    canvas.drawCircle(c, s * 0.04, Paint()..color = SoulColors.starYellow);
  }

  void _moonBow(Canvas canvas) {
    final c = Offset(-s * 0.3, -s * 0.32);
    final bow = Paint()
      ..shader = ui.Gradient.linear(
        c.translate(-s * 0.1, 0),
        c.translate(s * 0.1, 0),
        [SoulColors.starBlue, SoulColors.starBlueDeep],
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(-s * 0.08, 0),
        width: s * 0.16,
        height: s * 0.12,
      ),
      bow,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(s * 0.08, 0),
        width: s * 0.16,
        height: s * 0.12,
      ),
      bow,
    );
    canvas.drawCircle(c, s * 0.04, Paint()..color = SoulColors.starBlueDeep);
    canvas.drawCircle(
      c.translate(0, s * 0.1),
      s * 0.045,
      Paint()..color = SoulColors.starYellow,
    );
    canvas.drawCircle(
      c.translate(s * 0.015, s * 0.09),
      s * 0.03,
      Paint()..color = const Color(0xFF2E3050),
    );
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 4 * math.pi / 5;
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}
