import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared official KaamSetu lockup. The artwork is the approved uploaded logo.
class KaamSetuBrand extends StatelessWidget {
  const KaamSetuBrand({super.key, this.compact = false, this.light = false});

  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final scale = compact ? .74 : 1.0;
    final textColor = light ? Colors.white : AppColors.navy;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Hero(
          tag: 'kaamsetu_logo',
          child: SizedBox(
            width: 148 * scale,
            height: 82 * scale,
            child: RepaintBoundary(
              child: Image.asset(
                'assets/branding/kaamsetu_official_logo.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, -4 * scale),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 42 * scale,
                height: .92,
                letterSpacing: -2.1 * scale,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              children: const [
                TextSpan(text: 'Kaam', style: TextStyle(color: AppColors.blue)),
                TextSpan(
                    text: 'Setu', style: TextStyle(color: AppColors.orange)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Bridging Work. Building Trust.',
          style: TextStyle(
              color: textColor,
              fontSize: 11 * scale,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
