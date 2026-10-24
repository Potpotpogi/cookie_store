import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A hand-drawn chocolate chip cookie with a bite taken out.
/// No image file needed.
class CookieArt extends StatelessWidget {
  const CookieArt({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _CookieArtPainter(),
    );
  }
}

class _ChipSpec {
  const _ChipSpec(this.x, this.y, this.size, this.rot);
  final double x; // relative to cookie radius
  final double y;
  final double size;
  final double rot;
}

class _CookieArtPainter extends CustomPainter {
  const _CookieArtPainter();

  static const _chips = [
    _ChipSpec(-0.45, -0.35, 0.34, 0.5),
    _ChipSpec(-0.08, -0.58, 0.28, -0.4),
    _ChipSpec(0.22, 0.02, 0.32, 0.9),
    _ChipSpec(-0.52, 0.22, 0.30, -0.8),
    _ChipSpec(0.08, 0.50, 0.34, 0.3),
    _ChipSpec(0.52, 0.42, 0.28, -0.6),
    _ChipSpec(-0.15, -0.08, 0.26, 1.2),
    _ChipSpec(0.58, -0.05, 0.26, 0.2),
    _ChipSpec(-0.38, 0.58, 0.24, 0.7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.40;

    // Slightly wobbly outline
    final body = Path();
    const steps = 180;
    for (var i = 0; i <= steps; i++) {
      final a = i / steps * 2 * math.pi;
      final rr = r * (1 + 0.018 * math.sin(a * 7) + 0.012 * math.cos(a * 11));
      final p = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
      if (i == 0) {
        body.moveTo(p.dx, p.dy);
      } else {
        body.lineTo(p.dx, p.dy);
      }
    }
    body.close();

    // Scalloped bite at the top right
    const biteAngle = -math.pi / 4;
    final dir = Offset(math.cos(biteAngle), math.sin(biteAngle));
    final tangent = Offset(-dir.dy, dir.dx);
    final bc = c + dir * r;
    final bite = Path()
      ..addOval(Rect.fromCircle(
          center: bc - tangent * r * 0.30 - dir * r * 0.02, radius: r * 0.22))
      ..addOval(Rect.fromCircle(center: bc - dir * r * 0.06, radius: r * 0.24))
      ..addOval(Rect.fromCircle(
          center: bc + tangent * r * 0.30 - dir * r * 0.02, radius: r * 0.22));

    final cookie = Path.combine(PathOperation.difference, body, bite);

    canvas.drawPath(
      cookie,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFEDBB78), Color(0xFFCB8C46), Color(0xFFA8692B)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawPath(
      cookie,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF8A5222).withValues(alpha: 0.6),
    );

    // Chocolate chips
    for (final d in _chips) {
      final w = r * d.size;
      canvas.save();
      canvas.translate(c.dx + d.x * r, c.dy + d.y * r);
      canvas.rotate(d.rot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w * 1.5, height: w),
          Radius.circular(w * 0.35),
        ),
        Paint()..color = const Color(0xFF3E2216),
      );
      canvas.drawCircle(
        Offset(-w * 0.28, -w * 0.15),
        w * 0.12,
        Paint()..color = Colors.white.withValues(alpha: 0.25),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CookieArtPainter oldDelegate) => false;
}