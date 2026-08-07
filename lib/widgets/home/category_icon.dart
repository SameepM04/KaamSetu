import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/job_categories.dart';

/// The reusable visual treatment for every job-category PNG.
///
/// Adds a subtle, category-specific idle "micro-motion" (a gentle roller
/// nudge for painters, a light wrench twist for plumbers, etc.) on top of
/// the existing static artwork/colors/layout. The motion is driven by a
/// single lightweight repeating [AnimationController] per icon instance -
/// no Lottie, no extra packages. Because call sites render these inside
/// `GridView.builder` / `ListView.builder`, off-screen icons are simply not
/// built, so their tickers don't run.
class JobCategoryIcon extends StatefulWidget {
  const JobCategoryIcon(
      {super.key,
      required this.category,
      this.size = 70,
      this.borderRadius = 18,
      this.iconSize,
      this.animate = true});

  final JobCategory category;
  final double size;
  final double borderRadius;
  final double? iconSize;

  /// Set to false for places the icon must stay perfectly static
  /// (e.g. inside an already-animating Hero flight).
  final bool animate;

  @override
  State<JobCategoryIcon> createState() => _JobCategoryIconState();
}

class _JobCategoryIconState extends State<JobCategoryIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant JobCategoryIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.animate && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final size = widget.size;
    final accent = JobCategoryMapper.accentColor(category);
    final resolvedIconSize = widget.iconSize ?? size * .42;

    final artwork = Image.asset(
      JobCategoryMapper.assetPath(category),
      width: size - 6,
      height: size - 6,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.work_outline_rounded, color: accent, size: resolvedIconSize),
    );

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value; // 0..1, loops every 6s
        final glow = widget.animate
            ? _glowAlpha(category, t)
            : .12;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: JobCategoryMapper.backgroundColor(category),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                  color: accent.withValues(alpha: glow),
                  blurRadius: category == JobCategory.electrical ? 18 : 14,
                  offset: const Offset(0, 6))
            ],
          ),
          alignment: Alignment.center,
          child: widget.animate
              ? _motion(category, t, artwork)
              : artwork,
        );
      },
    );
  }

  double _glowAlpha(JobCategory category, double t) {
    if (category != JobCategory.electrical) return .12;
    // Soft pulsing glow, ~2s per breath.
    final wave = (math.sin(t * 2 * math.pi * 3) + 1) / 2; // 0..1
    return .10 + wave * .16;
  }

  /// Returns the animated artwork for [category] at loop-position [t] (0..1).
  Widget _motion(JobCategory category, double t, Widget artwork) {
    switch (category) {
      case JobCategory.painting:
        // Paint roller: gentle left-right nudge, ~5s cycle.
        final dx = math.sin(t * 2 * math.pi * (6000 / 5000)) * 3.2;
        return Transform.translate(offset: Offset(dx, 0), child: artwork);

      case JobCategory.plumbing:
        // Wrench: soft ±10° rotation every few seconds.
        final angle =
            math.sin(t * 2 * math.pi * 2) * (10 * math.pi / 180);
        return Transform.rotate(angle: angle, child: artwork);

      case JobCategory.electrical:
        // Lightning: subtle opacity pulse to sell the "glow" (box glow above).
        final wave = (math.sin(t * 2 * math.pi * 3) + 1) / 2;
        return Opacity(opacity: .88 + wave * .12, child: artwork);

      case JobCategory.cleaning:
        // Broom + sparkles fading in/out around it.
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            artwork,
            ..._sparkles(t),
          ],
        );

      case JobCategory.gardening:
        // Leaf gently swaying from its base.
        final angle = math.sin(t * 2 * math.pi * 1.4) * (6 * math.pi / 180);
        return Transform.rotate(
          angle: angle,
          alignment: Alignment.bottomCenter,
          child: artwork,
        );

      case JobCategory.carpentry:
        // Hammer: a single quick tap once every loop, otherwise still.
        final phase = t % 1.0;
        double angle = 0;
        if (phase < .08) {
          final k = phase / .08; // 0..1
          angle = math.sin(k * math.pi) * (-14 * math.pi / 180);
        }
        return Transform.rotate(
          angle: angle,
          alignment: Alignment.topRight,
          child: artwork,
        );

      case JobCategory.acRepair:
        // Snowflake: slow continuous rotation.
        return Transform.rotate(angle: t * 2 * math.pi * .5, child: artwork);

      case JobCategory.delivery:
        // Vehicle: slight bounce.
        final dy = -(math.sin(t * 2 * math.pi * 3).abs()) * 3.0;
        return Transform.translate(offset: Offset(0, dy), child: artwork);

      case JobCategory.cook:
        // Steam rising slowly above the food.
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            artwork,
            ..._steam(t),
          ],
        );
    }
  }

  List<Widget> _sparkles(double t) {
    const offsets = [Offset(-14, -14), Offset(12, -10), Offset(10, 12)];
    return List.generate(offsets.length, (i) {
      final phase = (t + i * .33) % 1.0;
      final opacity = math.sin(phase * 2 * math.pi).clamp(0.0, 1.0);
      return Positioned(
        left: widget.size / 2 + offsets[i].dx,
        top: widget.size / 2 + offsets[i].dy,
        child: Opacity(
          opacity: opacity,
          child: Icon(Icons.auto_awesome_rounded,
              size: widget.size * .14,
              color: JobCategoryMapper.accentColor(widget.category)),
        ),
      );
    });
  }

  List<Widget> _steam(double t) {
    const dx = [-6.0, 0.0, 6.0];
    return List.generate(dx.length, (i) {
      final phase = (t + i * .3) % 1.0;
      final rise = phase * (widget.size * .32);
      final opacity = (1 - phase) * .55;
      return Positioned(
        top: widget.size * .06 - rise,
        left: widget.size / 2 + dx[i] - 2,
        child: Opacity(
          opacity: opacity.clamp(0, .55),
          child: Container(
            width: 4,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
    });
  }
}
