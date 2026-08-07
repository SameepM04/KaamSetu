import 'package:flutter/material.dart';

import '../../data/job_previews.dart';
import '../../repositories/jobs_repository.dart';
import '../../theme/app_colors.dart';

/// The single bookmark control reused on every job card across the app
/// (Browse by Skill, Nearby Jobs, Recommended Jobs, Marketplace, Search,
/// Filtered/Category results, and Saved Jobs). Wraps [JobsRepository] so
/// no screen or card talks to Firestore directly.
class BookmarkButton extends StatefulWidget {
  const BookmarkButton({
    super.key,
    required this.job,
    this.size = 20,
    this.filledColor = AppColors.blue,
    this.outlineColor = AppColors.inkMuted,
  });

  final JobPreview job;
  final double size;
  final Color filledColor;
  final Color outlineColor;

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
    return ValueListenableBuilder<Set<String>>(
      valueListenable: _repo.savedJobIds,
      builder: (context, savedIds, _) {
        final saved = savedIds.contains(widget.job.id);
        return GestureDetector(
          onTap: _onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                key: ValueKey(saved),
                color: saved ? widget.filledColor : widget.outlineColor,
                size: widget.size,
              ),
            ),
          ),
        );
      },
    );
  }
}
