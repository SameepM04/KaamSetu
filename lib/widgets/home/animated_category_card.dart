import 'package:flutter/material.dart';

/// Shared "premium" interaction shell for every job-category card:
/// - Material ripple
/// - Scale to 0.96 on press, spring back on release
/// - Elevation + shadow animation
/// - Web/desktop hover: scale 1.03 + elevation
/// - Staggered fade + slide-up entrance (50–70ms per index)
///
/// Purely implicit animations (AnimatedScale/AnimatedContainer/
/// TweenAnimationBuilder) - no extra packages required.
class AnimatedCategoryCard extends StatefulWidget {
  const AnimatedCategoryCard({
    super.key,
    required this.child,
    required this.onTap,
    this.index = 0,
    this.borderRadius = 20,
    this.color = Colors.white,
    this.staggerStep = const Duration(milliseconds: 60),
  });

  final Widget child;
  final VoidCallback onTap;

  /// Position within its grid/list, used to stagger the entrance animation.
  final int index;
  final double borderRadius;
  final Color color;
  final Duration staggerStep;

  @override
  State<AnimatedCategoryCard> createState() => _AnimatedCategoryCardState();
}

class _AnimatedCategoryCardState extends State<AnimatedCategoryCard> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    final elevation = _pressed ? 1.0 : (_hovered ? 10.0 : 4.0);
    final scale = _pressed ? 0.96 : (_hovered ? 1.03 : 1.0);

    Widget card = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? .10 : .06),
              blurRadius: elevation * 3,
              offset: Offset(0, elevation * .6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap,
            onHighlightChanged: (down) => setState(() => _pressed = down),
            onHover: (hovering) => setState(() => _hovered = hovering),
            child: widget.child,
          ),
        ),
      ),
    );

    // Entrance: fade in + slide up, staggered by index.
    final delay = widget.staggerStep * widget.index;
    return TweenAnimationBuilder<double>(
      key: ValueKey('cat-card-entrance-${widget.index}'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380) + delay,
      curve: Curves.easeOutCubic,
      builder: (context, v, child) {
        // Hold at 0 for the stagger delay, then ease in.
        final delayFraction =
            delay.inMilliseconds / (380 + delay.inMilliseconds);
        final progress =
            ((v - delayFraction) / (1 - delayFraction)).clamp(0.0, 1.0);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * 14),
            child: child,
          ),
        );
      },
      child: card,
    );
  }
}
