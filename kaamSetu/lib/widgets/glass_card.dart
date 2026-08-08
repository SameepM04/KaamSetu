import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 24});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .62),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: .9), width: 1.4),
            boxShadow: const [BoxShadow(color: Color(0x194775B4), blurRadius: 24, offset: Offset(0, 12))],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class FeaturePill extends StatelessWidget {
  const FeaturePill({super.key, required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 53,
            height: 53,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .88),
              boxShadow: [BoxShadow(color: color.withValues(alpha: .27), blurRadius: 14, offset: const Offset(0, 7))],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 9),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.navy, fontSize: 12, height: 1.14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
