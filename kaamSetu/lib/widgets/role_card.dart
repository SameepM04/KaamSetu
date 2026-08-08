import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A single role-selection card ("I am a Worker" / "I am a Household").
///
/// The whole card is tappable and the circular arrow button underneath is
/// independently tappable too — both call [onTap]. The card has a gentle
/// continuous float, a press scale-down, a soft glow that intensifies on
/// press, and the arrow button ripples + glows on tap.
class RoleCard extends StatefulWidget {
  const RoleCard({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.backgroundGradient,
    required this.onTap,
    required this.floatPhase,
  });

  final String imageAsset;
  final String title;
  final String subtitle;
  final Color accentColor;
  final List<Color> backgroundGradient;
  final VoidCallback onTap;

  /// Offsets this card's floating animation from its sibling so the two
  /// cards don't bob in perfect unison.
  final double floatPhase;

  @override
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard> with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat(reverse: true);

  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    reverseDuration: const Duration(milliseconds: 220),
  );

  @override
  void dispose() {
    _float.dispose();
    _press.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (pressed) {
      _press.forward();
    } else {
      _press.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_float, _press]),
      builder: (context, child) {
        final floatT = (_float.value - .5) * 2; // -1..1
        final bob = (floatT + widget.floatPhase).clamp(-1.0, 1.0) * 5;
        final pressScale = 1 - (_press.value * .045);
        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.scale(scale: pressScale, child: child),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _press,
          builder: (context, child) {
            final glow = .18 + _press.value * .22;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.backgroundGradient,
                ),
                border: Border.all(color: widget.accentColor.withValues(alpha: .55), width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withValues(alpha: glow),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipOval(
                    child: Image.asset(
                      widget.imageAsset,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.accentColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 12.5,
                    height: 1.32,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                _ArrowButton(color: widget.accentColor, onTap: widget.onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatefulWidget {
  const _ArrowButton({required this.color, required this.onTap});
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    reverseDuration: const Duration(milliseconds: 220),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1 - _controller.value * .12;
        return Transform.scale(scale: scale, child: child);
      },
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTapDown: (_) => _controller.forward(),
          onTapCancel: () => _controller.reverse(),
          onTapUp: (_) => _controller.reverse(),
          onTap: widget.onTap,
          splashColor: widget.color.withValues(alpha: .25),
          highlightColor: widget.color.withValues(alpha: .12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: widget.color.withValues(alpha: .38), blurRadius: 14, offset: const Offset(0, 6)),
              ],
            ),
            child: Icon(Icons.arrow_forward_rounded, color: widget.color, size: 22),
          ),
        ),
      ),
    );
  }
}
