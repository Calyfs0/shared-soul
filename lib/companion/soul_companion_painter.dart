import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/soul_colors.dart';
import 'cosmetic.dart';
import 'cosmetic_painter.dart';
import 'evolution.dart';

/// Shared Soul companion — one soft geometric figure + a simple face.
class SoulCompanionPainter extends CustomPainter {
  SoulCompanionPainter({
    required this.breath,
    required this.float,
    required this.delight,
    required this.blink,
    required this.lookX,
    required this.lookY,
    required this.earTwitch,
    required this.tailPhase,
    required this.headTilt,
    required this.glow,
    required this.earDroop,
    required this.curl,
    required this.celebrate,
    required this.sparklePhase,
    required this.smile,
    required this.eyeOpenBias,
    required this.tearPhase,
    required this.tearIntensity,
    required this.cosmetic,
    required this.evolution,
    this.lonely = false,
  });

  /// 0–1 body squash / breath.
  final double breath;

  /// 0–1 gentle vertical float.
  final double float;

  /// 0–1 tap delight (soft hop).
  final double delight;

  final double blink;
  final double lookX;
  final double lookY;
  final double earTwitch;
  final double tailPhase;
  final double headTilt;
  final double glow;
  final double earDroop;
  final double curl;
  final double celebrate;
  final double sparklePhase;
  final double smile;
  final double eyeOpenBias;
  final double tearPhase;
  final double tearIntensity;
  final CompanionCosmetic cosmetic;
  final CompanionEvolution evolution;

  /// When true, Starlit’s moon goes cool and dull (no gold keep-light).
  final bool lonely;

  // Soft geometric figure
  static const _body = Color(0xFFE8F4FC);
  static const _bodyDeep = Color(0xFFC5DFF0);
  static const _swirl = Color(0xFF8EC4E8);
  static const _ink = Color(0xFF2C3540);
  static const _blush = Color(0xFFFFC0C8);
  static const _cape = Color(0xFF9EC4F0);
  static const _capeDeep = Color(0xFF6A9AD4);
  static const _gold = Color(0xFFFFD56A);
  static const _goldDeep = Color(0xFFE8B84A);
  static const _dusk = Color(0xFFC8B8F0);
  static const _moon = Color(0xFFFFF4D8);
  static const _moonDull = Color(0xFF9AA6B8);
  static const _moonDullDeep = Color(0xFF6E7A8C);
  static const _cloudWhite = Color(0xFFF8FCFF);

  @override
  void paint(Canvas canvas, Size size) {
    final starlit = evolution == CompanionEvolution.ascendant;
    // Starlit: large moon, same oval companion sitting in its crook.
    final origin = Offset(
      size.width / 2,
      size.height * (starlit ? 0.52 : 0.56),
    );
    final moonS = size.shortestSide * 0.42;
    final s = starlit
        ? size.shortestSide * 0.26
        : size.shortestSide * 0.42 * evolution.bodyScale;

    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    // Soft shadow — wider under the moon seat
    final shadowY = starlit ? moonS * 0.9 : s * 0.72;
    final shadowW = starlit ? 1.2 : 0.85;
    // sin(π·t) → rise and land with no end-state jump when t settles at 1.
    final delightPulse =
        delight > 0 ? math.sin(delight * math.pi) : 0.0;
    final delightHop = delightPulse * s * 0.055;
    final celebrateHop =
        celebrate > 0 ? math.sin(celebrate * math.pi) * s * 0.12 : 0.0;
    final hover = starlit ? s * 0.04 : 0.0;
    final bob = -float * s * 0.042 -
        delightHop -
        celebrateHop +
        curl * s * 0.05 -
        hover;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, shadowY - bob * 0.15),
        width: s * (shadowW - breath * 0.04 + delightPulse * 0.04),
        height: s * 0.1,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: starlit ? 0.09 : 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    canvas.translate(0, bob);
    // Soft settle on tap + quiet idle posture
    final delightSquash = 1 - delightPulse * 0.025;
    final delightStretch = 1 + delightPulse * 0.03;
    canvas.scale(
      (1 - curl * 0.04) * delightSquash,
      (1 + curl * 0.04 - breath * 0.015) * delightStretch,
    );

    // Aura: day-blue → traveler warmth → soft night light
    final auraBoost = switch (evolution) {
      CompanionEvolution.spark => 0.0,
      CompanionEvolution.drift => 0.1,
      CompanionEvolution.ascendant => 0.32,
    };
    final auraCore = switch (evolution) {
      CompanionEvolution.ascendant => Color.lerp(_moon, _dusk, 0.35)!,
      CompanionEvolution.drift => Color.lerp(_body, _gold, 0.12)!,
      CompanionEvolution.spark => _body,
    };
    canvas.drawCircle(
      Offset.zero,
      s * (1.25 + glow * 0.12 + auraBoost),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          s * (1.3 + auraBoost),
          [
            auraCore.withValues(alpha: (0.26 + auraBoost) * glow.clamp(0.4, 1)),
            (starlit ? _dusk : _cape).withValues(alpha: 0.12 * glow),
            Colors.transparent,
          ],
          const [0.0, 0.45, 1.0],
        ),
    );

    final isDrift = evolution == CompanionEvolution.drift;

    if (starlit) {
      _moonSeat(canvas, moonS);
    } else if (isDrift) {
      _driftCape(canvas, s);
    }

    // Starlit: perch the same oval in the moon’s crook
    canvas.save();
    if (starlit) {
      canvas.translate(-moonS * 0.06, moonS * 0.66);
    }

    canvas.save();
    // Subtle breathing squash — cozy, not bouncy
    canvas.scale(1 + breath * 0.028, 1 - breath * 0.018);
    _bodyFigure(canvas, s);
    canvas.restore();

    _tinyFeet(canvas, s);

    final faceOrigin = Offset(lookX * s * 0.03, -s * 0.06 + lookY * s * 0.02);

    final cosmetics = CosmeticPainter(
      cosmetic: cosmetic,
      s: s,
      faceOrigin: faceOrigin,
      headTilt: headTilt,
    );
    cosmetics.paintBehindFace(canvas);

    canvas.save();
    canvas.translate(faceOrigin.dx, faceOrigin.dy);
    canvas.rotate(headTilt * 0.5);
    _face(canvas, s);
    canvas.restore();

    // Desire throughline: hold a star → wear a star → sit with the moon
    if (evolution == CompanionEvolution.drift) {
      _driftStarClasp(canvas, s);
    }

    cosmetics.paintOnHead(canvas);

    if (tearIntensity > 0.05) {
      _floorTearSpirals(canvas, s);
      _fallingTears(canvas, s, faceOrigin);
    }

    if (evolution == CompanionEvolution.spark &&
        (cosmetic == CompanionCosmetic.none ||
            cosmetic == CompanionCosmetic.cozyScarf ||
            cosmetic == CompanionCosmetic.roundGlasses)) {
      _heldStar(canvas, s);
    }

    if (glow > 0.45 ||
        celebrate > 0.05 ||
        evolution != CompanionEvolution.spark) {
      _sparkles(canvas, s);
    }

    canvas.restore(); // starlit perch offset
    canvas.restore(); // origin / bob
  }

  void _driftCape(Canvas canvas, double s) {
    final sway = math.sin(tailPhase * math.pi * 2) * s * 0.04;

    // Outer cape
    final cape = Path()
      ..moveTo(-s * 0.28, -s * 0.12)
      ..lineTo(-s * 0.42, -s * 0.02)
      ..quadraticBezierTo(
        -s * 0.62 + sway,
        s * 0.28,
        -s * 0.52 + sway,
        s * 0.58,
      )
      ..quadraticBezierTo(0, s * 0.48, s * 0.52 - sway, s * 0.58)
      ..quadraticBezierTo(s * 0.62 - sway, s * 0.28, s * 0.42, -s * 0.02)
      ..lineTo(s * 0.28, -s * 0.12)
      ..quadraticBezierTo(0, s * 0.02, -s * 0.28, -s * 0.12)
      ..close();

    canvas.drawPath(
      cape,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, -s * 0.1),
          Offset(0, s * 0.58),
          [const Color(0xFFC5E0FA), _cape, _capeDeep],
          const [0.0, 0.4, 1.0],
        ),
    );

    // Gold trim along edges
    final trim = Paint()
      ..color = _gold.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.02
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(-s * 0.5 + sway * 0.5, s * 0.15)
        ..quadraticBezierTo(
          -s * 0.52 + sway,
          s * 0.4,
          -s * 0.48 + sway,
          s * 0.55,
        ),
      trim,
    );
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.5 - sway * 0.5, s * 0.15)
        ..quadraticBezierTo(
          s * 0.52 - sway,
          s * 0.4,
          s * 0.48 - sway,
          s * 0.55,
        ),
      trim,
    );

    // Tiny star embroidery
    for (final p in [
      Offset(-s * 0.35 + sway * 0.3, s * 0.28),
      Offset(s * 0.35 - sway * 0.3, s * 0.3),
      Offset(0, s * 0.4),
    ]) {
      _tinyStar(
        canvas,
        p,
        s * 0.035,
        Paint()..color = _gold.withValues(alpha: 0.55),
      );
    }

    // Collar
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -s * 0.02),
        width: s * 0.55,
        height: s * 0.16,
      ),
      Paint()
        ..shader = ui.Gradient.linear(Offset(-s * 0.2, 0), Offset(s * 0.2, 0), [
          _cape,
          _capeDeep,
        ]),
    );
  }

  void _driftStarClasp(Canvas canvas, double s) {
    final c = Offset(0, s * 0.0);
    canvas.drawCircle(
      c,
      s * 0.12,
      Paint()
        ..color = _gold.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    _tinyStar(canvas, c, s * 0.11, Paint()..color = _gold);
    _tinyStar(
      canvas,
      c.translate(0, 0),
      s * 0.05,
      Paint()..color = const Color(0xFFFFF6D0),
    );
  }

  /// Large celestial crescent — companion sits in the crook.
  void _moonSeat(Canvas canvas, double s) {
    final bob = math.sin(sparklePhase * math.pi * 2) * s * 0.01;
    final c = Offset(s * 0.04, s * 0.22 + bob);
    final r = s * 1.05;
    final warm = !lonely;
    final glowColor = warm ? _gold : _moonDullDeep;
    final faceLow = warm ? _goldDeep : _moonDullDeep;
    final faceMid = warm ? _moon : _moonDull;
    final faceHigh = warm ? _gold : Color.lerp(_moonDull, _cloudWhite, 0.25)!;
    final edge = warm
        ? Colors.white.withValues(alpha: 0.55)
        : _cloudWhite.withValues(alpha: 0.22);
    final starColor = warm ? _gold : _moonDull;

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-math.pi * 0.38); // ~68° — steeper perch silhouette

    canvas.drawCircle(
      Offset(0, s * 0.08),
      r * 1.05,
      Paint()
        ..color = glowColor.withValues(alpha: warm ? 0.26 : 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.9,
      Paint()
        ..color = faceMid.withValues(alpha: warm ? 0.18 : 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    final cutCenter = Offset(r * 0.16, -r * 0.28);
    final cutR = r * 0.9;
    final moon = Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
    final cut = Path()..addOval(Rect.fromCircle(center: cutCenter, radius: cutR));
    final crescent = Path.combine(PathOperation.difference, moon, cut);

    canvas.drawPath(
      crescent,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(-r, s * 0.15),
          Offset(r * 0.7, -r * 0.35),
          [faceLow, faceMid, faceHigh],
          const [0.0, 0.42, 1.0],
        ),
    );
    canvas.drawPath(
      crescent,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012,
    );

    canvas.drawArc(
      Rect.fromCircle(center: cutCenter, radius: cutR),
      0.55,
      math.pi - 1.1,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: warm ? 0.35 : 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.016
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );

    _tinyStar(
      canvas,
      Offset(-r * 0.78, -r * 0.12),
      s * 0.055,
      Paint()..color = starColor.withValues(alpha: warm ? 0.9 : 0.35),
    );
    _tinyStar(
      canvas,
      Offset(r * 0.82, -r * 0.08),
      s * 0.042,
      Paint()..color = starColor.withValues(alpha: warm ? 0.75 : 0.28),
    );

    canvas.restore();
  }

  /// One soft oval — the whole companion.
  void _bodyFigure(Canvas canvas, double s) {
    final curlSquash = 1 - curl * 0.08;
    final body = Rect.fromCenter(
      center: Offset.zero,
      width: s * 0.95 * curlSquash,
      height: s * 1.1,
    );
    canvas.drawOval(
      body,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(-s * 0.12, -s * 0.2),
          s * 0.75,
          const [_cloudWhite, _body, _bodyDeep],
          const [0.0, 0.45, 1.0],
        ),
    );
    // Very light edge — geometry, not a sticker outline
    canvas.drawOval(
      body,
      Paint()
        ..color = _ink.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02,
    );
  }

  /// Two tiny ovals under the body.
  void _tinyFeet(Canvas canvas, double s) {
    final step = math.sin(tailPhase * math.pi * 2) * s * 0.015;
    final y = s * 0.52 + curl * s * 0.03;
    void foot(double x, double phase) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + phase, y),
          width: s * 0.16,
          height: s * 0.1,
        ),
        Paint()..color = _bodyDeep,
      );
    }

    foot(-s * 0.14, -step);
    foot(s * 0.14, step);
  }

  void _face(Canvas canvas, double s) {
    final open = ((1.0 - blink) * eyeOpenBias).clamp(0.12, 1.0);
    final eyeY = -s * 0.04;
    final spread = s * 0.15;

    // Soft blush
    canvas.drawCircle(
      Offset(-s * 0.22, s * 0.08),
      s * 0.055,
      Paint()..color = _blush.withValues(alpha: 0.45),
    );
    canvas.drawCircle(
      Offset(s * 0.22, s * 0.08),
      s * 0.055,
      Paint()..color = _blush.withValues(alpha: 0.45),
    );

    // Simple round eyes
    void eye(double cx) {
      final c = Offset(cx + lookX * s * 0.03, eyeY + lookY * s * 0.02);
      final h = s * 0.11 * open;
      final w = s * 0.11;
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w, height: h),
        Paint()..color = _ink,
      );
      if (open > 0.4) {
        canvas.drawCircle(
          c.translate(-w * 0.18, -h * 0.22),
          w * 0.22,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
      }
    }

    eye(-spread);
    eye(spread);

    // Mouth — one quiet curve
    final mouthY = s * 0.12;
    if (smile < 0.3) {
      canvas.drawPath(
        Path()
          ..moveTo(-s * 0.05, mouthY + s * 0.02)
          ..quadraticBezierTo(0, mouthY - s * 0.02, s * 0.05, mouthY + s * 0.02),
        Paint()
          ..color = _ink.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.02
          ..strokeCap = StrokeCap.round,
      );
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(-s * 0.06, mouthY)
          ..quadraticBezierTo(0, mouthY + s * 0.08 * smile, s * 0.06, mouthY),
        Paint()
          ..color = _ink.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.02
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _heldStar(Canvas canvas, double s) {
    final bob = math.sin(sparklePhase * math.pi * 2) * s * 0.025;
    final c = Offset(s * 0.42, s * 0.05 + bob);
    canvas.drawCircle(
      c,
      s * 0.09,
      Paint()
        ..color = SoulColors.starYellow.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    _tinyStar(canvas, c, s * 0.08, Paint()..color = SoulColors.starYellow);
  }

  void _tinyStar(Canvas canvas, Offset c, double r, Paint paint) {
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

  void _sparkles(Canvas canvas, double s) {
    for (var i = 0; i < 8; i++) {
      final t = (sparklePhase + i / 8) % 1.0;
      final ang = i * (math.pi * 2 / 8) + sparklePhase * 2;
      final dist = s * (0.8 + 0.18 * math.sin(t * math.pi * 2));
      final p = Offset(
        math.cos(ang) * dist,
        math.sin(ang) * dist * 0.8 - s * 0.05,
      );
      final a = math.sin(t * math.pi) * glow;
      canvas.drawCircle(
        p,
        s * 0.025 * (0.5 + a),
        Paint()..color = Colors.white.withValues(alpha: a * 0.85),
      );
    }
  }

  void _fallingTears(Canvas canvas, double s, Offset faceOrigin) {
    final spread = s * 0.16;
    final eyeY = -s * 0.02;
    final floorY = s * 0.65;
    const drops = 4;
    for (var i = 0; i < drops; i++) {
      final fromLeft = i.isEven;
      final eye =
          faceOrigin +
          Offset(
            (fromLeft ? -spread : spread) + lookX * s * 0.035,
            eyeY + lookY * s * 0.025,
          );
      final t = (tearPhase + i * 0.23) % 1.0;
      final fall = Curves.easeIn.transform(t);
      final y = eye.dy + (floorY - eye.dy) * fall;
      final x = eye.dx + math.sin(t * math.pi * 2 + i) * s * 0.012;
      final pos = Offset(x, y);
      final alpha =
          tearIntensity *
          (t < 0.08
              ? t / 0.08
              : t > 0.88
              ? (1 - t) / 0.12
              : 1.0);
      if (alpha <= 0.02) continue;

      final r = s * 0.028;
      final tear = Path()
        ..moveTo(pos.dx, pos.dy - r * 1.6)
        ..quadraticBezierTo(pos.dx + r * 0.9, pos.dy, pos.dx, pos.dy + r * 1.1)
        ..quadraticBezierTo(pos.dx - r * 0.9, pos.dy, pos.dx, pos.dy - r * 1.6)
        ..close();
      canvas.drawPath(
        tear,
        Paint()..color = _swirl.withValues(alpha: 0.6 * alpha),
      );
      canvas.drawCircle(
        Offset(pos.dx - r * 0.2, pos.dy - r * 0.3),
        r * 0.25,
        Paint()..color = Colors.white.withValues(alpha: 0.5 * alpha),
      );
    }
  }

  void _floorTearSpirals(Canvas canvas, double s) {
    final floorY = s * 0.6;
    const count = 4;
    for (var i = 0; i < count; i++) {
      final t = (tearPhase + i * 0.23) % 1.0;
      double age;
      if (t >= 0.88) {
        age = (t - 0.88) / 0.12;
      } else if (t < 0.55) {
        age = 1.0 - (t / 0.55) * 0.65;
      } else {
        continue;
      }

      final fromLeft = i.isEven;
      final cx = (fromLeft ? -1 : 1) * s * (0.12 + (i % 2) * 0.1);
      final cy = floorY + (i % 3) * s * 0.02;
      final alpha = tearIntensity * age.clamp(0.0, 1.0) * 0.7;
      final radius = s * (0.06 + age * 0.14);
      final spin = tearPhase * math.pi * 2 * 0.35 + i * 0.8;

      final path = Path();
      const turns = 2.4;
      const steps = 56;
      for (var j = 0; j <= steps; j++) {
        final p = j / steps;
        final ang = spin + p * turns * math.pi * 2;
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
          ..color = _swirl.withValues(alpha: 0.45 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.018
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: radius * 2.1,
          height: radius * 0.85,
        ),
        Paint()
          ..color = _swirl.withValues(alpha: 0.12 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SoulCompanionPainter oldDelegate) {
    return breath != oldDelegate.breath ||
        float != oldDelegate.float ||
        delight != oldDelegate.delight ||
        blink != oldDelegate.blink ||
        lookX != oldDelegate.lookX ||
        lookY != oldDelegate.lookY ||
        earTwitch != oldDelegate.earTwitch ||
        tailPhase != oldDelegate.tailPhase ||
        headTilt != oldDelegate.headTilt ||
        glow != oldDelegate.glow ||
        earDroop != oldDelegate.earDroop ||
        curl != oldDelegate.curl ||
        celebrate != oldDelegate.celebrate ||
        sparklePhase != oldDelegate.sparklePhase ||
        smile != oldDelegate.smile ||
        eyeOpenBias != oldDelegate.eyeOpenBias ||
        tearPhase != oldDelegate.tearPhase ||
        tearIntensity != oldDelegate.tearIntensity ||
        cosmetic != oldDelegate.cosmetic ||
        evolution != oldDelegate.evolution ||
        lonely != oldDelegate.lonely;
  }
}
