import 'package:flutter/material.dart';

import '../data/job_categories.dart';
import '../repositories/household_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/success_dialog.dart';

/// Premium read-only summary of a completed job — the destination when a
/// household taps a card in the "Completed" tab (see `MyHouseholdJobs` in
/// household_home_screen.dart). Shows the assigned worker plus every
/// completed-job field (category, budget, date, duration, rating, thumb,
/// review) and, if the household hasn't rated the job yet, a "Rate Worker"
/// action that opens [_RateWorkerSheet].
class JobSummaryScreen extends StatefulWidget {
  const JobSummaryScreen({super.key, required this.job});
  final HouseholdJob job;

  @override
  State<JobSummaryScreen> createState() => _JobSummaryScreenState();
}

class _JobSummaryScreenState extends State<JobSummaryScreen> {
  WorkerProfile? _worker;
  bool _loadingWorker = true;

  // Optimistic local copy so the screen reflects a submitted rating
  // immediately, without waiting on a re-fetch or leaving the screen.
  late double? _rating = widget.job.householdRating;
  late bool? _thumbUp = widget.job.householdThumbUp;
  late String? _review = widget.job.householdReview;

  @override
  void initState() {
    super.initState();
    _loadWorker();
  }

  Future<void> _loadWorker() async {
    final id = widget.job.selectedWorkerId ?? '';
    final worker = await HouseholdRepository.instance.workerById(id);
    if (!mounted) return;
    setState(() {
      _worker = worker;
      _loadingWorker = false;
    });
  }

  bool get _isRated => (_rating ?? 0) > 0;

  Future<void> _openRateSheet() async {
    final result = await showModalBottomSheet<_RatingResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RateWorkerSheet(workerName: _worker?.name ?? 'the worker'),
    );
    if (result == null || !mounted) return;
    try {
      await HouseholdRepository.instance.rateJob(
        job: widget.job,
        rating: result.rating,
        thumbUp: result.thumbUp,
        review: result.review,
        isHouseholdRating: true,
      );
      if (!mounted) return;
      setState(() {
        _rating = result.rating;
        _thumbUp = result.thumbUp;
        _review = result.review;
      });
      await SuccessDialog.show(
        context,
        title: 'Rating Submitted',
        message: 'Thanks for sharing your experience!',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't submit your rating. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final categoryLabel = JobCategoryMapper.fromStorage(job.category) != null
        ? JobCategoryMapper.displayName(JobCategoryMapper.fromStorage(job.category)!)
        : job.category;

    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: const Text('Job Summary'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _WorkerHeader(
              worker: _worker,
              loading: _loadingWorker,
              jobTitle: job.title,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    icon: Icons.category_rounded,
                    label: 'Category',
                    value: categoryLabel,
                  ),
                  _SummaryRow(
                    icon: Icons.payments_rounded,
                    label: 'Budget',
                    value: job.budget.isNotEmpty ? job.budget : '—',
                  ),
                  _SummaryRow(
                    icon: Icons.event_rounded,
                    label: 'Date',
                    value: job.date.isNotEmpty ? job.date : '—',
                  ),
                  _SummaryRow(
                    icon: Icons.schedule_rounded,
                    label: 'Duration',
                    value: job.duration.isNotEmpty ? job.duration : '—',
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isRated)
              _RatingSummaryCard(
                rating: _rating!,
                thumbUp: _thumbUp,
                review: _review,
              )
            else
              _UnratedCard(onRate: _openRateSheet),
          ],
        ),
      ),
    );
  }
}

class _WorkerHeader extends StatelessWidget {
  const _WorkerHeader({
    required this.worker,
    required this.loading,
    required this.jobTitle,
  });
  final WorkerProfile? worker;
  final bool loading;
  final String jobTitle;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.paleBlue,
              backgroundImage: workerAvatarImage(worker?.photoUrl),
              child: worker?.photoUrl == null
                  ? const Icon(Icons.person_rounded,
                      color: AppColors.blue, size: 30)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jobTitle,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (loading)
                    const SizedBox(
                      height: 16,
                      width: 120,
                      child: LinearProgressIndicator(minHeight: 3),
                    )
                  else
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            worker?.name ?? 'Worker unavailable',
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (worker?.verified == true)
                          const Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Icon(Icons.verified_rounded,
                                color: AppColors.blue, size: 18),
                          ),
                      ],
                    ),
                  if (!loading && worker != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '★ ${worker!.rating.toStringAsFixed(1)} · ${worker!.completedJobs} jobs completed',
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: AppColors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (showDivider) const Divider(height: 1),
        ],
      );
}

class _UnratedCard extends StatelessWidget {
  const _UnratedCard({required this.onRate});
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star_outline_rounded, color: AppColors.blue),
                SizedBox(width: 8),
                Text(
                  "You haven't rated this job yet",
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(left: 32),
              child: Text(
                'Share how the work went — it helps other households too.',
                style: TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRate,
                icon: const Icon(Icons.star_rounded),
                label: const Text('Rate Worker'),
              ),
            ),
          ],
        ),
      );
}

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard({
    required this.rating,
    required this.thumbUp,
    required this.review,
  });
  final double rating;
  final bool? thumbUp;
  final String? review;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.green.withValues(alpha: .2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Rating',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.warmGold,
                    size: 26,
                  ),
                ),
                if (thumbUp != null) ...[
                  const SizedBox(width: 10),
                  Icon(
                    thumbUp! ? Icons.thumb_up_alt_rounded : Icons.thumb_down_alt_rounded,
                    color: thumbUp! ? AppColors.green : AppColors.inkMuted,
                    size: 20,
                  ),
                ],
              ],
            ),
            if (review != null && review!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '"$review"',
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// RATE WORKER BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _RatingResult {
  const _RatingResult({
    required this.rating,
    required this.thumbUp,
    required this.review,
  });
  final double rating;
  final bool? thumbUp;
  final String review;
}

class _RateWorkerSheet extends StatefulWidget {
  const _RateWorkerSheet({required this.workerName});
  final String workerName;

  @override
  State<_RateWorkerSheet> createState() => _RateWorkerSheetState();
}

class _RateWorkerSheetState extends State<_RateWorkerSheet> {
  int _stars = 0;
  bool? _thumbUp;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }
    Navigator.of(context).pop(_RatingResult(
      rating: _stars.toDouble(),
      thumbUp: _thumbUp,
      review: _commentCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  'Rate ${widget.workerName}',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'How was your experience with this worker?',
                  style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final starIndex = i + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _stars = starIndex),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedScale(
                          scale: _stars >= starIndex ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            _stars >= starIndex
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: AppColors.warmGold,
                            size: 40,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ThumbChoice(
                      icon: Icons.thumb_up_alt_rounded,
                      label: 'Good',
                      selected: _thumbUp == true,
                      color: AppColors.green,
                      onTap: () => setState(() => _thumbUp = true),
                    ),
                    const SizedBox(width: 16),
                    _ThumbChoice(
                      icon: Icons.thumb_down_alt_rounded,
                      label: 'Not great',
                      selected: _thumbUp == false,
                      color: const Color(0xFFE53935),
                      onTap: () => setState(() => _thumbUp = false),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _commentCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Write a review (optional)',
                    filled: true,
                    fillColor: AppColors.mist,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ThumbChoice extends StatelessWidget {
  const _ThumbChoice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: .12) : AppColors.mist,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : AppColors.line,
              width: 1.4,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? color : AppColors.inkMuted, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppColors.inkMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
}
