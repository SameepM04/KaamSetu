import 'package:flutter/material.dart';

/// Keeps a mobile app composition legible when it is previewed in a wide web window.
class MobileCanvas extends StatelessWidget {
  const MobileCanvas({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth / constraints.maxHeight <= .62) return child;
        return ColoredBox(
          color: const Color(0xFF10131A),
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
