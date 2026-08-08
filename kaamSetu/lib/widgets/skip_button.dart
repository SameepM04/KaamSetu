import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Top-right "Skip" control used on every onboarding page.
/// Feels tactile: scales down on press, gives haptic feedback,
/// and only fires on an actual tap release (not on a stray drag).
class SkipButton extends StatefulWidget {
  const SkipButton({super.key, required this.onSkip});

  final VoidCallback onSkip;

  @override
  State<SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<SkipButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onSkip();
      },
      child: AnimatedScale(
        scale: _pressed ? .92 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? .6 : 1,
          duration: const Duration(milliseconds: 110),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Skip',
                  style: TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 3),
                Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
