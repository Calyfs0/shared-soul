import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Draws live eyes + mouth over the Cloud Friend PNG.
/// Covers the baked-in face features, then animates blink / look / smile.
class FaceLiveOverlayPainter extends CustomPainter {
  FaceLiveOverlayPainter({
    required this.blink,
    required this.lookX,
    required this.lookY,
    required this.smile,
    required this.mouthPhase,
    required this.sad,
  });

  final double blink; // 0 open → 1 closed
  final double lookX; // -1..1
  final double lookY;
  final double smile; // 0 sad → 1 happy
  final double mouthPhase; // idle mouth bob
  final bool sad;

  // Match Cloud Friend cream fur so covers blend in
  static const _fur = Color(0xFFF4E8D8);
  static const _furShadow = Color(0xFFE5D2C0);
  static const _ink = Color(0xFF3B2A22);
  static const _blush = Color(0x66FFB0B8);
  static const _tongue = Color(0xFFFF9AAA);
  static const _star = Color(0xFFFFE08A);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    // Tuned to this specific mascot PNG
    final eyeCY = size.height * 0.455;
    final eyeSpread = size.width * 0.105;
    final eyeR = size.shortestSide * 0.072;
    final mouthC = Offset(cx, size.height * 0.545);

    _coverBakedFace(canvas, size, cx, eyeCY, eyeSpread, eyeR, mouthC);

    _eyes(canvas, cx, eyeCY, eyeSpread, eyeR);
    _mouth(canvas, mouthC, size.shortestSide);
  }

  void _coverBakedFace(
    Canvas canvas,
    Size size,
    double cx,
    double eyeCY,
    double eyeSpread,
    double eyeR,
    Offset mouthC,
  ) {
    final cover = Paint()..color = _fur;
    // Soft patches over baked eyes + mouth so live face replaces them
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - eyeSpread, eyeCY),
        width: eyeR * 2.35,
        height: eyeR * 2.35,
      ),
      cover,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + eyeSpread, eyeCY),
        width: eyeR * 2.35,
        height: eyeR * 2.35,
      ),
      cover,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: mouthC,
        width: size.shortestSide * 0.2,
        height: size.shortestSide * 0.14,
      ),
      cover,
    );

    // Soft blush (replaces baked cheek marks a bit)
    canvas.drawCircle(
      Offset(cx - eyeSpread - eyeR * 0.55, eyeCY + eyeR * 0.85),
      eyeR * 0.55,
      Paint()..color = _blush,
    );
    canvas.drawCircle(
      Offset(cx + eyeSpread + eyeR * 0.55, eyeCY + eyeR * 0.85),
      eyeR * 0.55,
      Paint()..color = _blush,
    );
  }

  void _eyes(
    Canvas canvas,
    double cx,
    double eyeCY,
    double eyeSpread,
    double eyeR,
  ) {
    final open = (1.0 - Curves.easeInOut.transform(blink)).clamp(0.06, 1.0);

    void eye(double x) {
      final c = Offset(x + lookX * eyeR * 0.35, eyeCY + lookY * eyeR * 0.25);

      if (open < 0.18) {
        // Closed eye line (blink / sleepy)
        final lid = Paint()
          ..color = _ink
          ..strokeWidth = eyeR * 0.22
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(c.dx - eyeR * 0.75, c.dy),
          Offset(c.dx + eyeR * 0.75, c.dy),
          lid,
        );
        return;
      }

      final h = eyeR * 2 * open;
      final w = eyeR * 2;

      // White
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w, height: h),
        Paint()..color = Colors.white,
      );

      // Iris / pupil
      final irisC = c + Offset(lookX * eyeR * 0.28, lookY * eyeR * 0.2);
      final irisR = eyeR * 0.72 * open.clamp(0.5, 1.0);
      canvas.drawCircle(
        irisC,
        irisR,
        Paint()
          ..shader = ui.Gradient.radial(
            irisC.translate(-irisR * 0.2, -irisR * 0.25),
            irisR,
            const [Color(0xFF5A3A2A), _ink],
          ),
      );

      // Star sparkle in pupil (from the art)
      _tinyStar(
        canvas,
        irisC.translate(-irisR * 0.15, irisR * 0.2),
        irisR * 0.28,
        Paint()..color = _star.withValues(alpha: 0.95),
      );

      // Catchlights
      canvas.drawCircle(
        irisC.translate(-irisR * 0.35, -irisR * 0.4),
        irisR * 0.28,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        irisC.translate(irisR * 0.3, irisR * 0.15),
        irisR * 0.12,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );

      // Top lid when partially blinking
      if (open < 0.95) {
        final lidH = eyeR * (1.15 - open);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(c.dx, c.dy - h * 0.5),
            width: w * 1.05,
            height: lidH,
          ),
          Paint()..color = _furShadow,
        );
      }
    }

    eye(cx - eyeSpread);
    eye(cx + eyeSpread);

    if (sad) {
      final brow = Paint()
        ..color = _ink.withValues(alpha: 0.45)
        ..strokeWidth = eyeR * 0.18
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      // Inner raised = sad
      canvas.drawPath(
        Path()
          ..moveTo(cx - eyeSpread - eyeR * 0.7, eyeCY - eyeR * 1.05)
          ..quadraticBezierTo(
            cx - eyeSpread,
            eyeCY - eyeR * 1.25,
            cx - eyeSpread + eyeR * 0.75,
            eyeCY - eyeR * 1.55,
          ),
        brow,
      );
      canvas.drawPath(
        Path()
          ..moveTo(cx + eyeSpread + eyeR * 0.7, eyeCY - eyeR * 1.05)
          ..quadraticBezierTo(
            cx + eyeSpread,
            eyeCY - eyeR * 1.25,
            cx + eyeSpread - eyeR * 0.75,
            eyeCY - eyeR * 1.55,
          ),
        brow,
      );
    }
  }

  void _mouth(Canvas canvas, Offset c, double s) {
    final bob = math.sin(mouthPhase * math.pi * 2) * s * 0.004;
    final center = c.translate(0, bob);
    final paint = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.012
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (smile > 0.7) {
      // Open happy "w" mouth with tongue (matches art)
      final open =
          0.55 + smile * 0.45 + math.sin(mouthPhase * math.pi * 2) * 0.08;
      final w = s * 0.055 * open;
      final h = s * 0.04 * open;
      final mouth = Path()
        ..moveTo(center.dx - w, center.dy - h * 0.2)
        ..quadraticBezierTo(
          center.dx - w * 0.35,
          center.dy + h,
          center.dx,
          center.dy + h * 0.35,
        )
        ..quadraticBezierTo(
          center.dx + w * 0.35,
          center.dy + h,
          center.dx + w,
          center.dy - h * 0.2,
        );
      canvas.drawPath(mouth, paint);
      // Tongue fill
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(0, h * 0.35),
          width: w * 0.7,
          height: h * 0.7,
        ),
        Paint()..color = _tongue.withValues(alpha: 0.85),
      );
    } else if (smile < 0.35) {
      // Soft sad curve
      final m = Path()
        ..moveTo(center.dx - s * 0.03, center.dy + s * 0.01)
        ..quadraticBezierTo(
          center.dx,
          center.dy - s * 0.01,
          center.dx + s * 0.03,
          center.dy + s * 0.01,
        );
      canvas.drawPath(m, paint);
    } else {
      // Neutral cat mouth, gently animating
      final lift = s * 0.008 * (0.5 + 0.5 * math.sin(mouthPhase * math.pi * 2));
      final m = Path()
        ..moveTo(center.dx - s * 0.035, center.dy)
        ..quadraticBezierTo(
          center.dx - s * 0.015,
          center.dy + s * 0.02 + lift,
          center.dx,
          center.dy,
        )
        ..quadraticBezierTo(
          center.dx + s * 0.015,
          center.dy + s * 0.02 + lift,
          center.dx + s * 0.035,
          center.dy,
        );
      canvas.drawPath(m, paint);
    }
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

  @override
  bool shouldRepaint(covariant FaceLiveOverlayPainter oldDelegate) {
    return blink != oldDelegate.blink ||
        lookX != oldDelegate.lookX ||
        lookY != oldDelegate.lookY ||
        smile != oldDelegate.smile ||
        mouthPhase != oldDelegate.mouthPhase ||
        sad != oldDelegate.sad;
  }
}
