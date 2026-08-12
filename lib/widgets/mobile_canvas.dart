import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Keeps a mobile app composition legible when it is previewed in a wide web window.
///
/// On a wide (desktop-shaped) browser viewport this letterboxes the app to a
/// phone-like aspect ratio and fills the surrounding area. That surrounding
/// fill must use the same light KaamSetu background as every screen's
/// `Scaffold` (`AppColors.mist`) — it previously used a near-black navy
/// (`0xFF10131A`), which is what showed up as an unintended dark/black area
/// around the centered app surface on wide viewports (e.g. around the "My
/// Applications" screen). The letterboxing/centering behavior itself is
/// unchanged.
class MobileCanvas extends StatelessWidget {
  const MobileCanvas({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth / constraints.maxHeight <= .62) return child;
        return ColoredBox(
          color: AppColors.mist,
          child: Center(
            child: AspectRatio(
              aspectRatio: .4625,
              child: ClipRect(child: child),
            ),
          ),
        );
      },
    );
  }
}
