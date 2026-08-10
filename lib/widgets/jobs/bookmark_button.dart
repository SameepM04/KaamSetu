import 'package:flutter/material.dart';

import '../../data/job_categories.dart';
import '../../data/job_previews.dart';
import '../../repositories/jobs_repository.dart';
import '../../theme/app_colors.dart';

/// The single bookmark control reused on every job card across the app
/// (Jobs, Nearby Jobs, Recommended Jobs, Applications, Saved Jobs, Job
/// Details). Wraps [JobsRepository] so no screen or card talks to
/// Firestore directly.
///
/// Visual identity: neutral/navy outline when unsaved (consistent
/// everywhere). Once saved, the icon, tinted background, and glow all
/// switch to that job's own category accent color — the same accent
/// already used by [JobCategoryMapper] for the category icon — so a
/// bookmarked Painting job glows blue, a bookmarked Plumbing job glows
/// green, etc., instead of every saved job turning the same blue.
class BookmarkButton extends StatefulWidget {
  const BookmarkButton({
    super.key,
    required this.job,
    this.size = 20,
    double? containerSize,
    this.outlineColor = AppColors.navy,
  }) : _containerSize = containerSize;

  final JobPreview job;

  /// Icon size. Compact cards use ~18-22, larger contexts (e.g. the Job
  /// Details app bar) can pass a bit more.
  final double size;

  /// Touch-target/chip diameter. Defaults to [size] + 14, which keeps a
  /// consistent ~36-44px Android-friendly touch target proportional to
  /// whatever icon size is passed in.
  final double? _containerSize;

  /// Icon color when NOT saved. Deliberately not a per-category color —
  /// only the saved state inherits the category accent.
  final Color outlineColor;

  double get containerSize => _containerSize ?? size + 14;

  @override
  State<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<BookmarkButton> {
  final _repo = JobsRepository.instance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _repo.ensureListening();
  }

  Future<void> _onTap() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _repo.toggleWishlist(widget.job);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Couldn't update your saved jobs. Try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Same accent color already driving this job's category icon — the
    // single source of truth in JobCategoryMapper, not a second mapping.
    final accent = JobCategoryMapper.accentColor(widget.job.category);

    return ValueListenableBuilder<Set<String>>(
      valueListenable: _repo.savedJobIds,
      builder: (context, savedIds, _) {
        final saved = savedIds.contains(widget.job.id);
        return Semantics(
          button: true,
          label: saved ? 'Remove job from saved' : 'Save job',
          child: GestureDetector(
            onTap: _onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.containerSize,
              height: widget.containerSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: saved ? accent.withValues(alpha: .14) : AppColors.mist,
                border: Border.all(
                  color: saved ? accent.withValues(alpha: .35) : AppColors.line,
                  width: 1,
                ),
                boxShadow: [
                  // Consistent, very subtle base shadow everywhere.
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: .06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                  // Soft glow in the job's own category color once saved.
                  if (saved)
                    BoxShadow(
                      color: accent.withValues(alpha: .28),
                      blurRadius: 10,
                      spreadRadius: .5,
                    ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  key: ValueKey(saved),
                  color: saved ? accent : widget.outlineColor,
                  size: widget.size,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
