import 'package:flutter/material.dart';

import '../../repositories/jobs_repository.dart';
import '../../theme/app_colors.dart';

/// Material 3 timeline for a single application (Phase 3C, Task 1).
///
/// Purely presentational — every step comes from
/// [JobsRepository.applicationTimeline], which derives it from the same
/// [ApplicationEntry] already streamed by the existing repository, so this
/// widget updates automatically whenever Firestore changes (Task 6)
/// without opening any listener of its own.
class ApplicationTimeline extends StatelessWidget {
  const ApplicationTimeline({super.key, required this.entry});

  final ApplicationEntry entry;

  @override
  Widget build(BuildContext context) {
    final steps = JobsRepository.instance.applicationTimeline(entry);
    // Each step gets an equal share of the available width (Task 1 fix) so
    // "Employer Viewed" and "Accepted" never crowd/overlap each other on
    // narrow screens — previously each step had a fixed 96px, left-aligned
    // width, which visually mashed the middle/last labels together.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            Expanded(
              child: _TimelineStep(
                step: steps[i],
                isFirst: i == 0,
                isLast: i == steps.length - 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.step,
    required this.isFirst,
    required this.isLast,
  });

  final TimelineStepData step;
  final bool isFirst;
  final bool isLast;

  (Color, Color, IconData) _visuals() {
    switch (step.state) {
      case TimelineStepState.done:
        return (Colors.white, AppColors.green, Icons.check_rounded);
      case TimelineStepState.current:
        return (Colors.white, AppColors.blue, Icons.radio_button_checked_rounded);
      case TimelineStepState.upcoming:
        return (AppColors.inkMuted, AppColors.line, Icons.circle_outlined);
      case TimelineStepState.terminalNegative:
        return (Colors.white, const Color(0xFFE5484D), Icons.close_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (dotFg, dotBg, icon) = _visuals();
    final connectorColor =
        step.state == TimelineStepState.upcoming ? AppColors.line : dotBg;
    final labelColor = step.state == TimelineStepState.upcoming
        ? AppColors.inkMuted
        : AppColors.navy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 3,
                color: isFirst ? Colors.transparent : connectorColor,
              ),
            ),
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotBg,
                border: step.state == TimelineStepState.upcoming
                    ? Border.all(color: AppColors.line, width: 2)
                    : null,
              ),
              child: Icon(icon, size: 15, color: dotFg),
            ),
            Expanded(
              child: Container(
                height: 3,
                color: isLast ? Colors.transparent : connectorColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Centered + allowed to wrap onto a second line (e.g. "Employer" /
        // "Viewed") rather than truncating — each step now owns an equal,
        // bounded share of the row's width via the Expanded above, so
        // neighboring labels can no longer collide.
        Text(
          step.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: step.state == TimelineStepState.current
                ? FontWeight.w800
                : FontWeight.w700,
          ),
        ),
        if (step.timestamp != null) ...[
          const SizedBox(height: 2),
          Text(
            _formatTimelineDate(step.timestamp!),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.inkMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

String _formatTimelineDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];
  return '${date.day} ${months[date.month - 1]}';
}
