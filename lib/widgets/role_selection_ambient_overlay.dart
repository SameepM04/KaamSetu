import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A very light, purely decorative animation layer painted on top of the
/// approved static background artwork. It never changes the artwork's
/// pixels — it only adds a handful of soft drifting light particles so the
/// screen feels alive without altering the approved visual.
class RoleSelectionAmbientOverlay extends StatefulWidget {
  const RoleSelectionAmbientOverlay({super.key});

  @override
  State<RoleSelectionAmbientOverlay> createState() =>
      _RoleSelectionAmbientOverlayState();
}

class _RoleSelectionAmbientOverlayState
    extends State<RoleSelectionAmbientOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => CustomPaint(
            painter: _AmbientPainter(_controller.value),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter(this.time);
  final double time;

  static const _particles = <_DriftParticle>[
    _DriftParticle(.14, .22, 2.4, Color(0x556CB7FF)),
    _DriftParticle(.82, .16, 2.8, Color(0x55FFB65A)),
    _DriftParticle(.28, .34, 2.0, Color(0x55FFFFFF)),
    _DriftParticle(.68, .30, 2.2, Color(0x556CB7FF)),
    _DriftParticle(.9, .40, 1.8, Color(0x55FFD883)),
    _DriftParticle(.08, .40, 1.8, Color(0x55FFFFFF)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _particles.length; i++) {
      final particle = _particles[i];
      final drift = math.sin(time * math.pi * 2 + i * 1.3) * 8;
      final riseT = ((time + i * .17) % 1.0);
      final rise = riseT * 26;
      final fade = (1 - riseT).clamp(0.0, 1.0);
      final center = Offset(
        size.width * particle.x + drift,
        size.height * particle.y - rise,
      );
      canvas.drawCircle(
        center,
        particle.radius,
        Paint()
          ..color = particle.color.withValues(alpha: particle.color.a * fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) =>
      oldDelegate.time != time;
}

class _DriftParticle {
  const _DriftParticle(this.x, this.y, this.radius, this.color);
  final double x;
  final double y;
  final double radius;
  final Color color;
}
