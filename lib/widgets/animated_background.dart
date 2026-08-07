import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedBackdrop extends StatefulWidget {
  const AnimatedBackdrop({
    super.key,
    this.sunrise = false,
    this.warmCenter = false,
    this.showPins = true,
    this.showAccentParticle = true,
  });

  final bool sunrise;
  final bool warmCenter;

  /// Whether to draw the small location-pin markers scattered in the
  /// background.
  final bool showPins;

  /// Whether to draw the single top-right accent particle (the orange
  /// dot). Screens with less content above the fold can hide it here
  /// and place their own dot inline next to the headline instead.
  final bool showAccentParticle;

  @override
  State<AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<AnimatedBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 13))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _BackdropPainter(
            time: _controller.value,
            sunrise: widget.sunrise,
            warmCenter: widget.warmCenter,
            showPins: widget.showPins,
            showAccentParticle: widget.showAccentParticle,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({
    required this.time,
    required this.sunrise,
    required this.warmCenter,
    this.showPins = true,
    this.showAccentParticle = true,
  });

  final double time;
  final bool sunrise;
  final bool warmCenter;
  final bool showPins;
  final bool showAccentParticle;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFDFEFF), Color(0xFFF5FAFF), Color(0xFFE6F3FF)],
      ).createShader(rect);
    canvas.drawRect(rect, base);

    void glow(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(
            Rect.fromCircle(center: center, radius: radius),
          ),
      );
    }

    glow(Offset(size.width * .78, size.height * .08), size.width * .68,
        const Color(0x336CB7FF));
    glow(Offset(size.width * .16, size.height * .71), size.width * .55,
        const Color(0x1B66B6FF));
    if (sunrise || warmCenter) {
      glow(
        Offset(size.width * .5, size.height * (sunrise ? .68 : .53)),
        size.width * .52,
        const Color(0x75FFD883),
      );
    }

    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .66);
    for (var line = 0; line < 12; line++) {
      final y = size.height * (.43 + line * .035);
      final path = Path()..moveTo(-20, y);
      for (double x = -20; x <= size.width + 20; x += 14) {
        final curve = math.sin(
            (x / size.width * math.pi * 2) + time * math.pi * 2 + line * .16);
        path.lineTo(x, y + curve * (13 + line * .25));
      }
      canvas.drawPath(path,
          wave..color = Colors.white.withValues(alpha: .26 - line * .012));
    }

    final nodePaint = Paint()
      ..color = const Color(0xFFB7D5FC).withValues(alpha: .3);
    final linkPaint = Paint()
      ..color = const Color(0xFFB7D5FC).withValues(alpha: .24)
      ..strokeWidth = .8;
    final nodes = <Offset>[
      Offset(size.width * .05, size.height * .38),
      Offset(size.width * .16, size.height * .42),
      Offset(size.width * .31, size.height * .36),
      Offset(size.width * .45, size.height * .44),
      Offset(size.width * .62, size.height * .39),
      Offset(size.width * .79, size.height * .45),
      Offset(size.width * .93, size.height * .38),
    ];
    for (var i = 0; i < nodes.length - 1; i++) {
      canvas.drawLine(nodes[i], nodes[i + 1], linkPaint);
      canvas.drawCircle(nodes[i], 4.2, nodePaint);
    }
    canvas.drawCircle(nodes.last, 4.2, nodePaint);

    const particles = <_Particle>[
      _Particle(.11, .17, 4, Color(0x5587BCFF)),
      _Particle(.86, .25, 5, Color(0x66FFB65A)),
      _Particle(.08, .62, 4, Color(0x55FFFFFF)),
      _Particle(.88, .58, 4, Color(0x55FBA94D)),
      _Particle(.23, .70, 5, Color(0x66FFFFFF)),
      _Particle(.75, .73, 3, Color(0x66FFFFFF)),
      _Particle(.93, .82, 6, Color(0x4471ABFF)),
    ];
    for (var i = 0; i < particles.length; i++) {
      if (i == 1 && !showAccentParticle) continue;
      final particle = particles[i];
      final drift = math.sin(time * math.pi * 2 + i) * 10;
      final center = Offset(
          size.width * particle.x + drift, size.height * particle.y - drift);
      canvas.drawCircle(center, particle.radius * 3,
          Paint()..color = particle.color.withValues(alpha: .08));
      canvas.drawCircle(
          center, particle.radius, Paint()..color = particle.color);
    }

    if (showPins) {
      final pin = Paint()
        ..color = const Color(0xFF86B4F5).withValues(alpha: .18);
      for (final position in [
        Offset(size.width * .09, size.height * .26),
        Offset(size.width * .86, size.height * .13),
        Offset(size.width * .96, size.height * .33)
      ]) {
        final path = Path()
          ..addOval(Rect.fromCircle(center: position, radius: 9))
          ..moveTo(position.dx - 7, position.dy + 5)
          ..lineTo(position.dx, position.dy + 21)
          ..lineTo(position.dx + 7, position.dy + 5)
          ..close();
        canvas.drawPath(path, pin);
        canvas.drawCircle(
            position, 3.2, Paint()..color = const Color(0xFFF8FBFF));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.sunrise != sunrise ||
      oldDelegate.warmCenter != warmCenter ||
      oldDelegate.showPins != showPins ||
      oldDelegate.showAccentParticle != showAccentParticle;
}

class _Particle {
  const _Particle(this.x, this.y, this.radius, this.color);
  final double x;
  final double y;
  final double radius;
  final Color color;
}
