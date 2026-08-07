// ============================================================================
// KaamSetu — Splash screen building blocks
// ----------------------------------------------------------------------------
// Consumed by lib/screens/splash_screen.dart, which owns layout, timing and
// navigation. This file only supplies the six pieces it asks for:
//   SplashBackdrop, SplashDecorations, SplashBrand, SplashConnectionScene,
//   SplashFeaturePanel, SplashLoadingIndicator.
//
// Assets used (declared in pubspec.yaml under assets/splash/):
//   logo.png, worker.png, house.png, bridge_dots.png, safe_hiring.png,
//   fair_opportunities.png, stronger_communities.png
// All backgrounds were flood-filled to transparent in place — still the
// original artwork, just without the white square around it.
// ============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const String _kLogo = 'assets/splash/logo.png';
const String _kWorker = 'assets/splash/worker.png';
const String _kHouse = 'assets/splash/house.png';
const String _kBridgeDots = 'assets/splash/bridge_dots.png';
const String _kSafeHiring = 'assets/splash/safe_hiring.png';
const String _kFairOpportunities = 'assets/splash/fair_opportunities.png';
const String _kStrongerCommunities = 'assets/splash/stronger_communities.png';

// ---------------------------------------------------------------------------
// SplashBackdrop — sky wash, breathing sunrise glow, ground line, skyline.
// Self-contained looping animation; disposes normally when popped.
// ---------------------------------------------------------------------------
class SplashBackdrop extends StatefulWidget {
  const SplashBackdrop({super.key});

  @override
  State<SplashBackdrop> createState() => _SplashBackdropState();
}

class _SplashBackdropState extends State<SplashBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return CustomPaint(
          painter: _BackdropPainter(glowT: _pulse.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({required this.glowT});
  final double glowT;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.paleBlue, Colors.white],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    final glowOpacity = 0.5 + 0.3 * math.sin(glowT * math.pi);
    final glowRadius = w * (0.62 + 0.04 * math.sin(glowT * math.pi));
    final glowCenter = Offset(w * 0.5, h * 0.30);
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(colors: [
          AppColors.warmGold.withValues(alpha: glowOpacity * 0.5),
          AppColors.warmGold.withValues(alpha: 0.0),
        ]).createShader(
            Rect.fromCircle(center: glowCenter, radius: glowRadius)),
    );

    final hillPath = Path()
      ..moveTo(0, h * 0.66)
      ..quadraticBezierTo(w * 0.5, h * 0.60, w, h * 0.66)
      ..lineTo(w, h * 0.74)
      ..lineTo(0, h * 0.74)
      ..close();
    canvas.drawPath(
      hillPath,
      Paint()
        ..shader = LinearGradient(colors: [
          AppColors.blue.withValues(alpha: 0.09),
          AppColors.orange.withValues(alpha: 0.07),
        ]).createShader(Rect.fromLTWH(0, h * 0.55, w, h * 0.19)),
    );

    _skyline(canvas, Rect.fromLTWH(w * 0.20, h * 0.55, w * 0.60, h * 0.10));
  }

  void _skyline(Canvas canvas, Rect bounds) {
    final paint = Paint()..color = AppColors.blue.withValues(alpha: 0.12);
    const buildingCount = 9;
    final bw = bounds.width / buildingCount;
    const heights = [0.5, 0.8, 0.35, 0.95, 0.6, 0.75, 0.4, 0.9, 0.55];
    for (var i = 0; i < buildingCount; i++) {
      final bh = bounds.height * heights[i % heights.length];
      canvas.drawRect(
        Rect.fromLTWH(bounds.left + i * bw, bounds.bottom - bh, bw * 0.8, bh),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) =>
      oldDelegate.glowT != glowT;
}

// ---------------------------------------------------------------------------
// SplashDecorations — dot grids, birds, soft corner curves, drifting dots.
// A lighter layer on top of the backdrop, its own gentle drift loop.
// ---------------------------------------------------------------------------
class SplashDecorations extends StatefulWidget {
  const SplashDecorations({super.key});

  @override
  State<SplashDecorations> createState() => _SplashDecorationsState();
}

class _SplashDecorationsState extends State<SplashDecorations>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) {
        return CustomPaint(
          painter: _DecorationsPainter(t: _drift.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _DecorationsPainter extends CustomPainter {
  _DecorationsPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _softCurve(canvas, Offset(-w * 0.12, -h * 0.04), w * 0.55);
    _softCurve(canvas, Offset(w * 1.08, h * 0.02), w * 0.5);

    _circle(canvas, Offset(w * 0.14, h * 0.20), 5,
        AppColors.blue.withValues(alpha: 0.22));
    _circle(canvas, Offset(w * 0.78, h * 0.16), 7,
        Colors.white.withValues(alpha: 0.8));
    _circle(canvas, Offset(w * 0.72, h * 0.09), 4,
        Colors.white.withValues(alpha: 0.7));
    _circle(canvas, Offset(w * 0.20, h * 0.42), 4,
        AppColors.orange.withValues(alpha: 0.28));
    _circle(canvas, Offset(w * 0.86, h * 0.36), 5,
        AppColors.orange.withValues(alpha: 0.22));
    _circle(canvas, Offset(w * 0.44, h * 0.50), 4,
        AppColors.blue.withValues(alpha: 0.18));

    _dotGrid(canvas, Offset(w * 0.08, h * 0.10));
    _dotGrid(canvas, Offset(w * 0.80, h * 0.06));

    _bird(canvas, Offset(w * 0.60, h * 0.06));
    _bird(canvas, Offset(w * 0.67, h * 0.045));

    for (var i = 0; i < 6; i++) {
      final baseX = w * (0.12 + i * 0.15);
      final baseY = h * (0.58 + (i.isEven ? 0.02 : -0.02));
      final dx = math.sin(t * 2 * math.pi + i) * 6;
      final dy = math.cos(t * 2 * math.pi + i * 1.3) * 5;
      _circle(canvas, Offset(baseX + dx, baseY + dy), 2.5,
          AppColors.blue.withValues(alpha: 0.14));
    }
  }

  void _softCurve(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _circle(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(center, radius, Paint()..color = color);
  }

  void _dotGrid(Canvas canvas, Offset origin, {int rows = 3, int cols = 3}) {
    final paint = Paint()..color = AppColors.blue.withValues(alpha: 0.22);
    const spacing = 12.0;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        canvas.drawCircle(
            Offset(origin.dx + c * spacing, origin.dy + r * spacing),
            1.6,
            paint);
      }
    }
  }

  void _bird(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = AppColors.navy.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const r = 6.0;
    final path = Path()
      ..moveTo(center.dx - r, center.dy)
      ..quadraticBezierTo(
          center.dx - r / 2, center.dy - r / 2, center.dx, center.dy)
      ..quadraticBezierTo(
          center.dx + r / 2, center.dy - r / 2, center.dx + r, center.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DecorationsPainter oldDelegate) =>
      oldDelegate.t != t;
}

// ---------------------------------------------------------------------------
// SplashBrand — the logo mark only (KaamSetu wordmark is drawn separately by
// splash_screen.dart's own _BrandWords, right below this). No container, no
// white square — logo.png renders as-is with a soft breathing glow behind it.
// ---------------------------------------------------------------------------
class SplashBrand extends StatefulWidget {
  const SplashBrand({super.key, required this.logoWidth});
  final double logoWidth;

  @override
  State<SplashBrand> createState() => _SplashBrandState();
}

class _SplashBrandState extends State<SplashBrand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boxSize = widget.logoWidth * 1.18;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = 0.55 + 0.35 * math.sin(_pulse.value * math.pi);
        return SizedBox(
          width: boxSize,
          height: boxSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: boxSize,
                height: boxSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withValues(alpha: 0.22 * glow),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Image.asset(
                _kLogo,
                width: widget.logoWidth,
                fit: BoxFit.contain,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// SplashConnectionScene — worker (left) · bridge_dots (center) · house
// (right), each on its own platform. Worker/house float gently; a small
// glow pulse travels along bridge_dots.png to keep it feeling "sequential"
// without redrawing that asset.
// ---------------------------------------------------------------------------
class SplashConnectionScene extends StatefulWidget {
  const SplashConnectionScene({super.key});

  @override
  State<SplashConnectionScene> createState() => _SplashConnectionSceneState();
}

class _SplashConnectionSceneState extends State<SplashConnectionScene>
    with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _bridge;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _bridge = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
  }

  @override
  void dispose() {
    _float.dispose();
    _bridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        final bridgeWidth = w - w * 0.42;

        return AnimatedBuilder(
          animation: Listenable.merge([_float, _bridge]),
          builder: (context, _) {
            final workerBob = math.sin(_float.value * 2 * math.pi) * 5;
            final houseBob = math.sin(_float.value * 2 * math.pi + math.pi) * 5;

            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: h * 0.58,
                  child: _AnimatedBridge(
                      progress: _bridge.value, width: bridgeWidth),
                ),
                Positioned(
                  left: w * 0.02,
                  bottom: 0,
                  child: _Platform(
                    color: AppColors.blue,
                    bob: workerBob,
                    child: Image.asset(_kWorker,
                        width: w * 0.24, fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  right: w * 0.00,
                  bottom: h * 0.02,
                  child: _Platform(
                    color: AppColors.orange,
                    bob: houseBob,
                    child: Image.asset(_kHouse,
                        width: w * 0.30, fit: BoxFit.contain),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Platform extends StatelessWidget {
  const _Platform(
      {required this.color, required this.bob, required this.child});
  final Color color;
  final double bob;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.translate(offset: Offset(0, bob), child: child),
        const SizedBox(height: 4),
        Container(
          width: 68,
          height: 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.35),
                color.withValues(alpha: 0.05)
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedBridge extends StatelessWidget {
  const _AnimatedBridge({required this.progress, required this.width});
  final double progress; // 0..1, loops
  final double width;

  @override
  Widget build(BuildContext context) {
    // bridge_dots.png is a wide strip (~2.5:1) — height derives from width
    // only, so the source aspect ratio holds and the asset is never redrawn.
    final height = width / 2.5;
    final travel = width - 12;
    final dx = -travel / 2 + travel * progress;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(_kBridgeDots,
              width: width, height: height, fit: BoxFit.fitWidth),
          Transform.translate(
            offset: Offset(dx, 0),
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [AppColors.blue, AppColors.orange]),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SplashFeaturePanel — Safe Hiring / Fair Opportunities / Stronger
// Communities. `entry` is the screen's shared one-shot AnimationController;
// cards stagger their own reveal against it. Each icon is the real
// illustration provided, zoomed into its centered glyph inside a circular
// clip so the baked-in labels/decoration on some of the source art stay
// out of frame.
// ---------------------------------------------------------------------------
class SplashFeaturePanel extends StatelessWidget {
  const SplashFeaturePanel({super.key, required this.entry});
  final Animation<double> entry;

  double _stagger(double start, double end) =>
      Interval(start, end, curve: Curves.easeOut)
          .transform(entry.value)
          .clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: entry,
      builder: (context, _) {
        final e1 = _stagger(0.60, 0.85);
        final e2 = _stagger(0.68, 0.92);
        final e3 = _stagger(0.76, 1.0);
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _FeatureCard(
                  entrance: e1,
                  asset: _kSafeHiring,
                  iconBg: AppColors.blue.withValues(alpha: 0.12),
                  accent: AppColors.blue,
                  title: 'Safe Hiring',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FeatureCard(
                  entrance: e2,
                  asset: _kFairOpportunities,
                  iconBg: AppColors.green.withValues(alpha: 0.14),
                  accent: AppColors.green,
                  title: 'Fair Opportunities',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FeatureCard(
                  entrance: e3,
                  asset: _kStrongerCommunities,
                  iconBg: AppColors.orange.withValues(alpha: 0.14),
                  accent: AppColors.orange,
                  title: 'Stronger Communities',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.entrance,
    required this.asset,
    required this.iconBg,
    required this.accent,
    required this.title,
  });

  final double entrance;
  final String asset;
  final Color iconBg;
  final Color accent;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: entrance,
      child: Transform.translate(
        offset: Offset(0, (1 - entrance) * 18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: ClipOval(
                  child: Transform.scale(
                    scale:
                        1.7, // zoom past baked-in labels/decoration, center on the glyph
                    child: Image.asset(asset, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 22,
                height: 3,
                decoration: BoxDecoration(
                    color: accent, borderRadius: BorderRadius.circular(2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SplashLoadingIndicator — progress bar + "Starting KaamSetu..." label.
// `progress` is the screen's shared one-shot AnimationController; the bar
// fills across the same tail interval the parent already fades it in over.
// ---------------------------------------------------------------------------
class SplashLoadingIndicator extends StatelessWidget {
  const SplashLoadingIndicator({super.key, required this.progress});
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final fill = CurvedAnimation(
      parent: progress,
      curve: const Interval(0.73, 1.0, curve: Curves.easeInOut),
    );
    return AnimatedBuilder(
      animation: fill,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 5,
                color: AppColors.line,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: fill.value.clamp(0.0, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            colors: [AppColors.navy, AppColors.blue]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w500),
                children: [
                  TextSpan(text: 'Starting '),
                  TextSpan(
                      text: 'Kaam',
                      style: TextStyle(
                          color: AppColors.blue, fontWeight: FontWeight.w700)),
                  TextSpan(
                      text: 'Setu',
                      style: TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.w700)),
                  TextSpan(text: '...'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
