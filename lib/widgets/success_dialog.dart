import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme/app_colors.dart';

/// A single, reusable "success" confirmation used across the whole app.
///
/// Plays `assets/lottie/success_check.lottie` once, auto-dismisses after a
/// short delay, and never blocks the app permanently. If the Lottie asset
/// fails to load for any reason (corrupt file, unsupported platform, etc.)
/// it falls back to a plain green check icon so the confirmation still
/// shows and the calling flow is never interrupted.
///
/// Usage:
/// ```dart
/// await SuccessDialog.show(
///   context,
///   title: 'Job Posted!',
///   message: 'Your job is now visible to suitable workers.',
/// );
/// ```
///
/// `show` completes once the dialog has auto-dismissed, so callers can
/// simply `await` it and then navigate / refresh — this also guarantees the
/// same success event can never stack two dialogs on top of each other.
class SuccessDialog extends StatefulWidget {
  const SuccessDialog({
    super.key,
    required this.title,
    this.message,
    this.displayDuration = const Duration(milliseconds: 1500),
  });

  final String title;
  final String? message;
  final Duration displayDuration;

  /// Shows the dialog, waits for it to play + auto-dismiss, then returns.
  ///
  /// Safe to call even if another dialog/route transition is mid-flight —
  /// it simply no-ops if the widget tied to [context] is no longer mounted.
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? message,
    Duration displayDuration = const Duration(milliseconds: 1500),
  }) {
    if (!context.mounted) return Future.value();
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: .25),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => SuccessDialog(
        title: title,
        message: message,
        displayDuration: displayDuration,
      ),
      transitionBuilder: (context, animation, __, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: .85, end: 1).animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.displayDuration, () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
            SizedBox(
              width: 140,
              height: 140,
              child: Lottie.asset(
                'assets/lottie/success_check.lottie',
                repeat: false,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppColors.green, size: 52),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            if (widget.message != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
