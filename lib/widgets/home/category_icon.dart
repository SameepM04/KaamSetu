import 'package:flutter/material.dart';

import '../../data/job_categories.dart';

/// The reusable visual treatment for every job-category PNG.
class JobCategoryIcon extends StatelessWidget {
  const JobCategoryIcon(
      {super.key,
      required this.category,
      this.size = 70,
      this.borderRadius = 18,
      this.iconSize});

  final JobCategory category;
  final double size;
  final double borderRadius;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final accent = JobCategoryMapper.accentColor(category);
    final resolvedIconSize = iconSize ?? size * .42;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: JobCategoryMapper.backgroundColor(category),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: .12),
              blurRadius: 14,
              offset: const Offset(0, 6))
        ],
      ),
      alignment: Alignment.center,
      child: Image.asset(
        JobCategoryMapper.assetPath(category),
        width: size - 6,
        height: size - 6,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.work_outline_rounded,
            color: accent, size: resolvedIconSize),
      ),
    );
  }
}
