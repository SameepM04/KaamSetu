import 'package:flutter/material.dart';

import '../../repositories/jobs_repository.dart';
import '../../theme/app_colors.dart';

/// Shared Material 3 status treatment for all application surfaces.
class ApplicationStatusChip extends StatelessWidget {
  const ApplicationStatusChip({super.key, required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, background, icon) = switch (status) {
      ApplicationStatus.pending => (
          const Color(0xFFD38A00),
          const Color(0xFFFFF3D6),
          Icons.hourglass_top_rounded
        ),
      ApplicationStatus.reviewed => (
          AppColors.blue,
          AppColors.blue.withValues(alpha: .12),
          Icons.visibility_rounded
        ),
      ApplicationStatus.accepted => (
          AppColors.green,
          AppColors.green.withValues(alpha: .14),
          Icons.check_circle_rounded
        ),
      ApplicationStatus.rejected => (
          const Color(0xFFE5484D),
          const Color(0xFFFDE8E9),
          Icons.cancel_rounded
        ),
      ApplicationStatus.completed => (
          const Color(0xFF7C5CE0),
          const Color(0xFFF0EBFC),
          Icons.workspace_premium_rounded
        ),
      ApplicationStatus.withdrawn => (
          AppColors.inkMuted,
          AppColors.line.withValues(alpha: .35),
          Icons.undo_rounded
        ),
    };
    return Chip(
      avatar: Icon(icon, size: 15, color: color),
      label: Text(ApplicationStatusMapper.displayName(status)),
      labelStyle:
          TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w800),
      backgroundColor: background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
