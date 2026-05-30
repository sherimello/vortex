import 'dart:math';
import 'package:flutter/material.dart';

class ScreenGlow extends StatefulWidget {
  final bool isActive;
  final Widget child;

  const ScreenGlow({super.key, required this.isActive, required this.child});

  @override
  State<ScreenGlow> createState() => _ScreenGlowState();
}

class _ScreenGlowState extends State<ScreenGlow>
    with TickerProviderStateMixin {
  late AnimationController _ctrl1;
  late AnimationController _ctrl2;

  @override
  void initState() {
    super.initState();
    // Two controllers at different speeds produce an aurora interference pattern
    _ctrl1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _ctrl2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl1.dispose();
    _ctrl2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isActive)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge([_ctrl1, _ctrl2]),
                builder: (_, _) => CustomPaint(
                  painter: _GlowPainter(_ctrl1.value, _ctrl2.value),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double t1; // main layer rotation 0..1
  final double t2; // secondary layer rotation 0..1

  // Cool layer: electric blue → cyan → teal → indigo
  static const _cool = [
    Color(0xFF0A84FF),
    Color(0xFF32D6FF),
    Color(0xFF30D5C8),
    Color(0xFF5E5CE6),
    Color(0xFF0A84FF),
  ];

  // Warm layer: vivid purple → magenta → orange — baked at ~80% opacity
  static const _warm = [
    Color(0xCCBF5AF2),
    Color(0xCCFF2D78),
    Color(0xCCFF9F0A),
    Color(0xCC9B59B6),
    Color(0xCCBF5AF2),
  ];

  const _GlowPainter(this.t1, this.t2);

  @override
  void paint(Canvas canvas, Size size) {
    final shorter = min(size.width, size.height);

    // Glow unit: 6% of shorter dimension, clamped
    final double g = (shorter * 0.06).clamp(14.0, 80.0);

    final isFullScreen = shorter > 500;
    final radius = Radius.circular(isFullScreen ? 0.0 : 14.0);

    // Rect aligned with canvas boundary — stroke center sits on the screen
    // edge so the inward half is fully visible. Outward half is clipped.
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rRect = RRect.fromRectAndRadius(rect, radius);

    final s1 = SweepGradient(
      colors: _cool,
      transform: GradientRotation(2 * pi * t1),
    ).createShader(rect);

    // Warm layer rotates opposite direction
    final s2 = SweepGradient(
      colors: _warm,
      transform: GradientRotation(2 * pi * (1.0 - t2)),
    ).createShader(rect);

    _drawGlow(canvas, rRect, s1, g);
    _drawGlow(canvas, rRect, s2, g);
  }

  void _drawGlow(Canvas canvas, RRect rRect, Shader shader, double g) {
    // Soft halo — stays close to the edge, doesn't bleed far inward
    canvas.drawRRect(
      rRect,
      Paint()
        ..shader = shader
        ..strokeWidth = g * 0.9
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, g * 0.55),
    );

    // Tight focused ring right at the edge
    canvas.drawRRect(
      rRect,
      Paint()
        ..shader = shader
        ..strokeWidth = g * 0.3
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, g * 0.18),
    );

    // Crisp bright edge line
    canvas.drawRRect(
      rRect,
      Paint()
        ..shader = shader
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.t1 != t1 || old.t2 != t2;
}
