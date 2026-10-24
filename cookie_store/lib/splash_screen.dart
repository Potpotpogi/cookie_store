import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'auth_gate.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..forward().whenComplete(_goNext);
  }

  void _goNext() {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const AuthGate(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Maps the global timeline [t] to a 0..1 value inside window [a]..[b].
  double _iv(double t, double a, double b, [Curve curve = Curves.linear]) {
    final x = ((t - a) / (b - a)).clamp(0.0, 1.0);
    return curve.transform(x);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goNext, // tap to skip
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF3E0), Color(0xFFFFD9A8)],
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;

              final drop = _iv(t, 0.0, 0.38, Curves.bounceOut);
              final roll = _iv(t, 0.0, 0.38, Curves.easeOutCubic);
              final grow = _iv(t, 0.0, 0.15, Curves.easeOut);
              final chips = _iv(t, 0.36, 0.72);
              final crumbs = _iv(t, 0.55, 0.85, Curves.easeOut);
              final title = _iv(t, 0.62, 0.80, Curves.easeOutCubic);
              final tagline = _iv(t, 0.76, 0.90, Curves.easeOut);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.translate(
                    offset: Offset(0, (1 - drop) * -460),
                    child: Transform.rotate(
                      angle: (1 - roll) * -math.pi * 3,
                      child: Transform.scale(
                        scale: 0.6 + 0.4 * grow,
                        child: CustomPaint(
                          size: const Size(240, 240),
                          painter: _CookiePainter(chips: chips, crumbs: crumbs),
                        ),
                      ),
                    ),
                  ),
                  // Ground shadow that appears as the cookie lands
                  Container(
                    width: 60 + 100 * drop,
                    height: 16,
                    margin: const EdgeInsets.only(top: 4, bottom: 24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6D4C41)
                          .withValues(alpha: 0.18 * drop),
                    ),
                  ),
                  Opacity(
                    opacity: title,
                    child: Transform.translate(
                      offset: Offset(0, (1 - title) * 24),
                      child: const Text(
                        'Cookie Store',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Color(0xFF4E2A14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: tagline,
                    child: const Text(
                      'Freshly baked, just for you',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8D5A2B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Chip {
  const _Chip(this.x, this.y, this.size, this.rot);
  final double x; // relative to cookie radius
  final double y;
  final double size;
  final double rot;
}

class _CookiePainter extends CustomPainter {
  _CookiePainter({required this.chips, required this.crumbs});

  final double chips; // 0..1 chip pop progress
  final double crumbs; // 0..1 crumb burst progress

  static const _chipData = [
    _Chip(-0.45, -0.35, 0.34, 0.5),
    _Chip(-0.08, -0.58, 0.28, -0.4),
    _Chip(0.22, 0.02, 0.32, 0.9),
    _Chip(-0.52, 0.22, 0.30, -0.8),
    _Chip(0.08, 0.50, 0.34, 0.3),
    _Chip(0.52, 0.42, 0.28, -0.6),
    _Chip(-0.15, -0.08, 0.26, 1.2),
    _Chip(0.58, -0.05, 0.26, 0.2),
    _Chip(-0.38, 0.58, 0.24, 0.7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.40;

    // Slightly wobbly cookie outline
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
    final bc = c + dir * r * 1.0;
    final bite = Path()
      ..addOval(Rect.fromCircle(
          center: bc - tangent * r * 0.30 - dir * r * 0.02, radius: r * 0.22))
      ..addOval(Rect.fromCircle(
          center: bc - dir * r * 0.06, radius: r * 0.24))
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

    // Chocolate chips popping in one by one
    for (var i = 0; i < _chipData.length; i++) {
      final d = _chipData[i];
      final local = ((chips - i * 0.07) / 0.4).clamp(0.0, 1.0);
      final s = Curves.elasticOut.transform(local);
      if (s <= 0) continue;

      final w = r * d.size;
      canvas.save();
      canvas.translate(c.dx + d.x * r, c.dy + d.y * r);
      canvas.rotate(d.rot);
      canvas.scale(s);
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

    // Crumbs flying out of the bite
    if (crumbs > 0 && crumbs < 1) {
      for (var i = 0; i < 9; i++) {
        final ang = biteAngle + (i - 4) * 0.28;
        final speed = 40.0 + (i % 3) * 22.0;
        final p = bc +
            Offset(math.cos(ang), math.sin(ang)) * speed * crumbs +
            Offset(0, 90 * crumbs * crumbs);
        canvas.drawCircle(
          p,
          3.4 - (i % 3) * 0.8,
          Paint()
            ..color = const Color(0xFFB9722F).withValues(alpha: 1 - crumbs),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CookiePainter old) =>
      old.chips != chips || old.crumbs != crumbs;
}