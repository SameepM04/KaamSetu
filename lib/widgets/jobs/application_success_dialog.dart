import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../theme/app_colors.dart';

/// Phase 3 — shown immediately after a worker's application is
/// successfully written to Firestore (never before; never on failure).
///
/// This is presentation only, exactly like [FirstApplicationDialog]: it
/// knows nothing about Firestore or the application repository. The caller
/// (`JobDetailsScreen._submitApplication`) is the only place that decides
/// whether the write actually succeeded, and only calls [show] once it has
/// a real, confirmed success — so this dialog can never appear for a
/// failed or duplicate application.
///
/// Reuses the same `assets/lottie/success_check.lottie` asset and the same
/// graceful icon fallback already used by [SuccessDialog] (see
/// `widgets/success_dialog.dart`) — no new package or asset needed. Unlike
/// [SuccessDialog] (which auto-dismisses and is used for generic
/// confirmations app-wide), this variant stays open until the worker picks
/// one of the two explicit actions, since Phase 3 calls for
/// "View Applications" / "Continue" buttons rather than an auto-dismiss.
class ApplicationSuccessDialog extends StatelessWidget {
  const ApplicationSuccessDialog({super.key, required this.jobTitle});

  final String jobTitle;

  /// Shows the dialog and resolves to `true` if the worker tapped
  /// "View Applications", or `false`/`null` for "Continue"/dismiss. The
  /// caller decides what navigation (if any) that maps to.
  static Future<bool?> show(BuildContext context, {required String jobTitle}) {
    if (!context.mounted) return Future.value(null);
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Application sent',
      barrierColor: Colors.black.withValues(alpha: .25),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => ApplicationSuccessDialog(jobTitle: jobTitle),
      transitionBuilder: (context, animation, __, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: .9, end: 1).animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetAnimationDuration: Duration.zero,
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
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
            // Same asset + fallback pattern as SuccessDialog — plays once,
            // no looping, ~1-2s per the bundled Lottie's own duration.
            SizedBox(
              width: 104,
              height: 104,
              child: Lottie.asset(
                'assets/lottie/success_check.lottie',
                repeat: false,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppColors.green, size: 42),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Application Sent!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkMuted,
                ),
                children: [
                  const TextSpan(text: 'Your application for '),
                  TextSpan(
                    text: jobTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.navy),
                  ),
                  const TextSpan(text: ' has been submitted successfully.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('View Applications'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
