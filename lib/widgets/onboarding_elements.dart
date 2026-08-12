import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glass_card.dart';

/// Approved worker illustration (assets/splash/worker.png) used directly —
/// not redrawn. A subtle idle float + slight nudge while dragging.
class WorkerCard extends StatelessWidget {
  const WorkerCard({super.key, required this.progress, this.ambient = 0});

  final double progress;
  final double ambient;

  @override
  Widget build(BuildContext context) {
    final floatY = math.sin(ambient * math.pi * 2) * 4;
    return Transform.translate(
      offset: Offset(18 * progress, floatY),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Color(0x334B82FB), blurRadius: 18, offset: Offset(0, 10))
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/splash/worker.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

/// Approved house illustration (assets/splash/house.png) used directly —
/// not redrawn. A subtle idle float + slight nudge while dragging.
class HouseCard extends StatelessWidget {
  const HouseCard({super.key, required this.progress, this.ambient = 0});

  final double progress;
  final double ambient;

  @override
  Widget build(BuildContext context) {
    final floatY = math.sin(ambient * math.pi * 2 + math.pi) * 4;
    return Transform.translate(
      offset: Offset(-18 * progress, floatY),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Color(0x33F79B4E), blurRadius: 18, offset: Offset(0, 10))
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/splash/house.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class AnimatedBridge extends StatelessWidget {
  const AnimatedBridge({super.key, required this.time, required this.progress});

  final double time;
  final double progress;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          painter: _BridgePainter(time: time, progress: progress),
          child: const SizedBox.expand(),
        ),
      );
}

class _BridgePainter extends CustomPainter {
  const _BridgePainter({required this.time, required this.progress});
  final double time;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * .56;
    final start = size.width * .39;
    final end = size.width * .61;
    final glowingEnd = start + (end - start) * progress;
    final line = Paint()
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2F70F5).withValues(alpha: .18 + progress * .7);
    canvas.drawLine(Offset(start, y), Offset(glowingEnd, y), line);
    final dotPaint = Paint()..color = AppColors.electricBlue;
    for (var i = 0; i < 6; i++) {
      final direction = i.isEven ? 1.0 : -1.0;
      final phase = (time + i / 6) % 1;
      final x =
          size.width * .5 + direction * (end - start) * (.5 - phase * .45);
      final radius = (i == 0 ? 6 : 3.2) + progress * 1.8;
      canvas.drawCircle(
          Offset(x, y),
          radius,
          dotPaint
            ..color =
                AppColors.electricBlue.withValues(alpha: .45 + progress * .55));
    }
  }

  @override
  bool shouldRepaint(covariant _BridgePainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.progress != progress;
}

/// Onboarding-two "bring hands together" stage. Uses the approved
/// left_hand.png / right_hand.png / center_glow.png assets directly —
/// nothing here is redrawn or AI-generated.
///
/// [progress] drives the hands from their separated resting position
/// (matches the reference image) toward the center as the user drags.
/// [handshakeBounce] is an optional -1..1 signal used only for the brief
/// down/up/down settle once the hands connect (see [OnboardingTwo]).
class HandsStage extends StatelessWidget {
  const HandsStage({
    super.key,
    required this.progress,
    required this.ambient,
    this.handshakeBounce = 0,
  });

  final double progress;
  final double ambient;
  final double handshakeBounce;

  @override
  Widget build(BuildContext context) {
    final glowOpacity =
        ((progress * 1.15) + handshakeBounce.abs() * .15).clamp(0.0, 1.0);
    final glowScale =
        .82 + progress * .34 + handshakeBounce.abs() * .05;
    final floatY = math.sin(ambient * math.pi * 2) * 3;
    final bounceY = handshakeBounce * 7;

    return LayoutBuilder(
      builder: (context, constraints) {
        final handWidth = math.min(constraints.maxWidth * .44, 182.0);
        // Distance each hand still has to travel to meet at the center;
        // shrinks to ~0 as progress approaches 1 so the hands connect
        // (their faded fingertips overlap) rather than snapping together.
        final spread = constraints.maxWidth * .26 * (1 - progress);

        return Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            Align(
              alignment: const Alignment(0, -.16),
              child: Opacity(
                opacity: glowOpacity,
                child: Transform.scale(
                  scale: glowScale,
                  child: Image.asset(
                    'assets/onboarding_two/center_glow.png',
                    width: 320,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, -.04),
              child: Transform.translate(
                offset: Offset(-spread - 4, floatY + bounceY),
                child: Image.asset(
                  'assets/onboarding_two/left_hand.png',
                  width: handWidth,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, -.04),
              child: Transform.translate(
                offset: Offset(spread + 4, -floatY + bounceY),
                child: Image.asset(
                  'assets/onboarding_two/right_hand.png',
                  width: handWidth,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class TrustConnection extends StatelessWidget {
  const TrustConnection(
      {super.key, required this.progress, required this.ambient});
  final double progress;
  final double ambient;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
            painter: _TrustPainter(progress: progress, ambient: ambient),
            child: const SizedBox.expand()),
      );
}

class _TrustPainter extends CustomPainter {
  const _TrustPainter({required this.progress, required this.ambient});
  final double progress;
  final double ambient;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .5, size.height * .56);
    final glow = 50 + math.sin(ambient * math.pi * 2) * 6;
    canvas.drawCircle(
        center,
        glow,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFD16C).withValues(alpha: .45),
            const Color(0x00FFD16C)
          ]).createShader(Rect.fromCircle(center: center, radius: glow)));
    for (var i = 0; i < 3; i++) {
      final radius = 38 + i * 22 + progress * 15;
      canvas.drawCircle(
          center,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = const Color(0xFFFFD98B)
                .withValues(alpha: (1 - progress) * .38));
    }
    final bridge = Paint()
      ..color = AppColors.electricBlue
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * .23, size.height * .78),
        Offset(size.width * (.23 + .54 * progress), size.height * .78), bridge);
    final pinCenter = Offset(center.dx, center.dy - 64 * progress);
    final pin = Path()
      ..addOval(Rect.fromCircle(center: pinCenter, radius: 13 * progress))
      ..moveTo(pinCenter.dx - 11 * progress, pinCenter.dy + 7 * progress)
      ..lineTo(pinCenter.dx, pinCenter.dy + 28 * progress)
      ..lineTo(pinCenter.dx + 11 * progress, pinCenter.dy + 7 * progress)
      ..close();
    canvas.drawPath(
        pin, Paint()..color = Colors.white.withValues(alpha: progress));
    if (progress > .35) {
      final orbit = 38 + (1 - progress) * 36;
      for (var i = 0; i < 4; i++) {
        final angle = ambient * math.pi * 2 + i * math.pi / 2;
        final point = pinCenter +
            Offset(math.cos(angle) * orbit, math.sin(angle) * orbit);
        canvas.drawCircle(
            point,
            6,
            Paint()
              ..color = [
                AppColors.blue,
                AppColors.orange,
                AppColors.green,
                const Color(0xFFFFC75E)
              ][i]
                  .withValues(alpha: (1 - progress) * 1.4));
      }
    }
    final left = RRect.fromRectAndRadius(
        Rect.fromLTWH(
            -8, size.height * .53, size.width * .51, size.height * .18),
        const Radius.circular(30));
    final right = RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .49, size.height * .53, size.width * .51,
            size.height * .18),
        const Radius.circular(30));
    canvas.drawRRect(left, Paint()..color = const Color(0xFF4C85EE));
    canvas.drawRRect(right, Paint()..color = const Color(0xFFFF9A49));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 76, height: 43),
            const Radius.circular(22)),
        Paint()..color = const Color(0xFFF1B28A));
  }

  @override
  bool shouldRepaint(covariant _TrustPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.ambient != ambient;
}

class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.active, this.onDotTap});
  final int active;

  /// Optional: called with the tapped dot's index so the caller can
  /// navigate directly to that onboarding screen. When null, dots are
  /// purely decorative (original behavior is preserved).
  final ValueChanged<int>? onDotTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onDotTap == null ? null : () => onDotTap!(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 7),
              width: index == active ? 25 : 15,
              height: 15,
              decoration: BoxDecoration(
                color: index == active
                    ? AppColors.electricBlue
                    : const Color(0xFFCBD7E9),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TrustFeatureCard extends StatelessWidget {
  const TrustFeatureCard(
      {super.key,
      required this.icon,
      required this.label,
      required this.color,
      required this.visible});
  final IconData icon;
  final String label;
  final Color color;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, .18),
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 380),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 13),
            radius: 21,
            child: Column(
              children: [
                Container(
                  width: 47,
                  height: 47,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: .16)),
                  child: Icon(icon, color: color, size: 29),
                ),
                const SizedBox(height: 10),
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 13,
                        height: 1.15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 9),
                Container(
                    width: 24,
                    height: 4,
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(3))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PressableCta extends StatefulWidget {
  const PressableCta({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  State<PressableCta> createState() => _PressableCtaState();
}

class _PressableCtaState extends State<PressableCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine;
  bool _pressed = false;
  bool _hovering = false;
  @override
  void initState() {
    super.initState();
    _shine =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..repeat();
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shine,
      builder: (_, __) => MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onPressed();
          },
          child: AnimatedScale(
            duration: const Duration(milliseconds: 130),
            scale: _pressed ? .96 : (_hovering ? 1.015 : 1),
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF245DE5), Color(0xFF2375FF)]),
                borderRadius: BorderRadius.circular(39),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF3267E8)
                          .withValues(alpha: _pressed ? .62 : .42),
                      blurRadius: _pressed ? 29 : 20,
                      offset: const Offset(0, 10))
                ],
                border: Border.all(
                    color: Colors.white.withValues(alpha: .65), width: 1.4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(39),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                        left: -120 + _shine.value * 490,
                        child: Transform.rotate(
                            angle: -.28,
                            child: Container(
                                width: 42,
                                height: 112,
                                color: Colors.white.withValues(alpha: .2)))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 44),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Flexible(
                            child: Text(
                              'Get Started',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          SizedBox(width: 14),
                          Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.white, size: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
