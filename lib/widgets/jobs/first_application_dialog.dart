import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Centralized copy for the Phase 2 motivational first-application popup —
/// one place to localize later instead of hardcoding the strings into the
/// dialog widget itself.
abstract final class FirstApplicationCopy {
  static const title = 'Every journey begins\nwith a single step.';
  static const subtitle = 'Today, that step is your\nfirst job application.';
  static const closing = 'Good luck!';
}

/// The "first application" milestone moment (Phase 2). Shown once, in place
/// of the normal Apply confirmation, the first time a worker with a 100%
/// complete profile applies for a job — never before the profile-completion
/// gate has already passed.
///
/// This is presentation only: it knows nothing about Firestore or the
/// application repository. [onApply]/`show`'s return value tell the caller
/// what the worker chose; the caller (job_details_screen) remains the only
/// place that calls into [JobsRepository.applyForJob].
class FirstApplicationDialog extends StatefulWidget {
  const FirstApplicationDialog({super.key});

  /// Shows the dialog and resolves to `true` if the worker tapped
  /// "Apply now", or `false`/`null` if they dismissed it via "Maybe later",
  /// the barrier, or the back gesture. Dismissing never creates an
  /// application — that decision is entirely the caller's.
  static Future<bool?> show(BuildContext context) {
    if (!context.mounted) return Future.value(null);
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'First application',
      barrierColor: Colors.black.withValues(alpha: .25),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const FirstApplicationDialog(),
      transitionBuilder: (context, animation, __, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curve,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - curve.value)),
            child: ScaleTransition(
              scale: Tween<double>(begin: .94, end: 1).animate(curve),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  State<FirstApplicationDialog> createState() =>
      _FirstApplicationDialogState();
}

class _FirstApplicationDialogState extends State<FirstApplicationDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetAnimationDuration: Duration.zero,
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line.withValues(alpha: .6)),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: .18),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.paleBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.blue, size: 30),
            ),
            const SizedBox(height: 20),
            const Text(
              FirstApplicationCopy.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                height: 1.28,
                letterSpacing: -0.3,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              FirstApplicationCopy.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              FirstApplicationCopy.closing,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Apply now'),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Maybe later'),
            ),
          ],
        ),
      ),
    );
  }
}
