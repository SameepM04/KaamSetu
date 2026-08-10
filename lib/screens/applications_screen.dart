import 'package:flutter/material.dart';

import '../animations/page_transition.dart';
import '../repositories/jobs_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/jobs/application_timeline.dart';
import '../widgets/jobs/withdraw_application_button.dart';
import '../widgets/shimmer_loading.dart' show ShimmerLoading;
import '../widgets/success_dialog.dart';
import 'job_details_screen.dart';
import 'jobs_screen.dart';

/// Bottom-navigation destination for the current worker's Firestore-backed
/// applications. The repository supplies a broadcast of its one listener.
class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key, required this.onBrowseJobs});

  final VoidCallback onBrowseJobs;

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final _repo = JobsRepository.instance;
  late Stream<List<ApplicationEntry>> _stream;
  Object? _lastError;
  var _shownUnknownStatusWarning = false;

  @override
  void initState() {
    super.initState();
    _stream = _repo.applicationsStream();
  }

  Future<void> _retry() async {
    await _repo.refreshApplications();
  }

  /// Submits a household rating and shows the success animation.
  ///
  /// Deliberately lives on this screen-level [State] rather than on the
  /// per-row `_RateHouseholdSection` widget. That row sits inside a lazily
  /// built `ListView.separated`: if the list scrolls or rebuilds while the
  /// Firestore write for the rating is still in flight (a very real
  /// possibility — the rating sheet closing, the keyboard dismissing, and
  /// the write itself all take time), the row's own BuildContext can be
  /// disposed before the write resolves. `SuccessDialog.show` would then
  /// silently no-op on an unmounted context — the rating still saves, but
  /// the success Lottie never appears, which is exactly the symptom this
  /// fixes. This screen's context stays mounted for as long as the
  /// Applications tab itself is alive, so the dialog reliably shows.
  Future<void> _submitHouseholdRating(
    ApplicationEntry entry,
    _HouseholdRatingResult result, {
    required bool isEdit,
  }) async {
    try {
      // rateHousehold() always set(merge:true)s the same
      // users/{uid}/applications/{jobId} + jobs/{jobId} docs, so calling it
      // again on an edit UPDATES the existing rating in place — there is no
      // separate "create" path, so no duplicate rating can be created.
      await _repo.rateHousehold(
        entry: entry,
        rating: result.rating,
        thumbUp: result.thumbUp,
        review: result.review,
      );
      if (mounted) {
        await SuccessDialog.show(
          context,
          title: isEdit ? 'Rating Updated' : 'Rating Submitted',
          message: isEdit
              ? 'Your rating has been updated.'
              : 'Thanks for your feedback!',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEdit
                  ? "Couldn't update your rating. Please try again."
                  : "Couldn't submit your rating. Please try again.")),
        );
      }
    }
  }

  void _showErrorSnackBar(Object error) {
    if (_lastError.toString() == error.toString()) return;
    _lastError = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Applications are unavailable. Please try again.'),
        ));
      }
    });
  }

  void _showUnknownStatusWarning() {
    if (_shownUnknownStatusWarning) return;
    _shownUnknownStatusWarning = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('An application has an unknown status.'),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: StreamBuilder<List<ApplicationEntry>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ApplicationsSkeleton();
            }
            if (snapshot.hasError) {
              _showErrorSnackBar(snapshot.error!);
              return _ApplicationsError(onRetry: _retry);
            }
            _lastError = null;
            final entries = snapshot.data ?? const <ApplicationEntry>[];
            if (entries.any((entry) => !entry.hasKnownStatus)) {
              _showUnknownStatusWarning();
            } else {
              _shownUnknownStatusWarning = false;
            }
            if (entries.isEmpty) {
              return _ApplicationsEmpty(onBrowse: widget.onBrowseJobs);
            }
            return RefreshIndicator(
              onRefresh: _retry,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                itemCount: entries.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) return const _ApplicationsHeading();
                  return _ApplicationCard(
                    entry: entries[index - 1],
                    onSubmitRating: _submitHouseholdRating,
                  );
                },
              ),
            );
          },
        ),
      );
}

class _ApplicationsHeading extends StatelessWidget {
  const _ApplicationsHeading();
  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Applications',
              style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 25,
                  fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text('Track the jobs you have applied for.',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 13)),
        ],
      );
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.entry, required this.onSubmitRating});
  final ApplicationEntry entry;
  final Future<void> Function(
    ApplicationEntry entry,
    _HouseholdRatingResult result, {
    required bool isEdit,
  }) onSubmitRating;

  @override
  Widget build(BuildContext context) {
    final job = entry.toJobPreview();
    return JobPreviewCard(
      job: job,
      heroTag: 'applications-${entry.jobId}',
      bottomContent: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Applied',
                        style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(_formatDate(entry.appliedAt),
                        style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(premiumPageRoute(
                    JobDetailsScreen(
                        job: job, heroTag: 'applications-${entry.jobId}'))),
                child: const Text('Details'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ApplicationTimeline(entry: entry),
          if (entry.status == ApplicationStatus.completed) ...[
            const SizedBox(height: 10),
            _RateHouseholdSection(entry: entry, onSubmitRating: onSubmitRating),
          ],
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                    'Last updated ${_formatDate(entry.lastUpdated)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600)),
              ),
              WithdrawApplicationButton(entry: entry),
            ],
          ),
        ],
      ),
    );
  }
}

class _RateHouseholdSection extends StatelessWidget {
  const _RateHouseholdSection({required this.entry, required this.onSubmitRating});
  final ApplicationEntry entry;
  final Future<void> Function(
    ApplicationEntry entry,
    _HouseholdRatingResult result, {
    required bool isEdit,
  }) onSubmitRating;

  Future<void> _openRateSheet(BuildContext context, {bool isEdit = false}) async {
    final result = await showModalBottomSheet<_HouseholdRatingResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RateHouseholdSheet(
        householdName: entry.company,
        isEdit: isEdit,
        // Pre-fill with the existing rating so editing behaves like a real
        // app (Task 2/3/7) — the sheet is reused as-is, just seeded with
        // the current values instead of blank ones.
        initialRating: isEdit ? (entry.workerRating?.round() ?? 0) : 0,
        initialThumbUp: isEdit ? entry.workerThumbUp : null,
        initialReview: isEdit ? (entry.workerReview ?? '') : '',
      ),
    );
    if (result == null) return;
    // Submission + the success dialog are handled by the screen-level
    // State (see ApplicationsScreen._submitHouseholdRating) rather than
    // here, so a slow write can't lose the dialog to this row's own
    // BuildContext being disposed by list scrolling/rebuilds in the
    // meantime.
    await onSubmitRating(entry, result, isEdit: isEdit);
  }

  @override
  Widget build(BuildContext context) {
    if (entry.isRatedByWorker) {
      // Tapping the existing rating reopens the same sheet in edit mode
      // (Task 2/6) instead of leaving the rating permanently locked.
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openRateSheet(context, isEdit: true),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.green.withValues(alpha: .2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < entry.workerRating!.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.warmGold,
                        size: 18,
                      ),
                    ),
                  ),
                  if (entry.workerThumbUp != null)
                    Icon(
                      entry.workerThumbUp!
                          ? Icons.thumb_up_alt_rounded
                          : Icons.thumb_down_alt_rounded,
                      color: entry.workerThumbUp!
                          ? AppColors.green
                          : AppColors.inkMuted,
                      size: 16,
                    ),
                  const Text('Your Rating',
                      style: TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.edit_rounded, size: 13, color: AppColors.blue),
                  SizedBox(width: 4),
                  Text('Edit Rating',
                      style: TextStyle(
                          color: AppColors.blue,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _openRateSheet(context),
        icon: const Icon(Icons.star_outline_rounded, size: 18),
        label: const Text('Rate Household'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

class _HouseholdRatingResult {
  const _HouseholdRatingResult({
    required this.rating,
    required this.thumbUp,
    required this.review,
  });
  final double rating;
  final bool? thumbUp;
  final String review;
}

class _RateHouseholdSheet extends StatefulWidget {
  const _RateHouseholdSheet({
    required this.householdName,
    this.isEdit = false,
    this.initialRating = 0,
    this.initialThumbUp,
    this.initialReview = '',
  });
  final String householdName;
  final bool isEdit;
  final int initialRating;
  final bool? initialThumbUp;
  final String initialReview;

  @override
  State<_RateHouseholdSheet> createState() => _RateHouseholdSheetState();
}

class _RateHouseholdSheetState extends State<_RateHouseholdSheet> {
  late int _stars = widget.initialRating;
  late bool? _thumbUp = widget.initialThumbUp;
  late final _commentCtrl = TextEditingController(text: widget.initialReview);

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
    Navigator.of(context).pop(_HouseholdRatingResult(
      rating: _stars.toDouble(),
      thumbUp: _thumbUp,
      review: _commentCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.householdName.isNotEmpty
        ? widget.householdName
        : 'the household';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              Text(widget.isEdit ? 'Edit Your Rating' : 'Rate $name',
                  style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 19,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                  widget.isEdit
                      ? 'Update your feedback about this household.'
                      : 'How was your experience with this household?',
                  style: const TextStyle(
                      color: AppColors.inkMuted, fontSize: 13)),
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
                  _ThumbChoicePill(
                    icon: Icons.thumb_up_alt_rounded,
                    label: 'Good',
                    selected: _thumbUp == true,
                    color: AppColors.green,
                    onTap: () => setState(() => _thumbUp = true),
                  ),
                  const SizedBox(width: 16),
                  _ThumbChoicePill(
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
                  child: Text(widget.isEdit ? 'Save Changes' : 'Submit',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbChoicePill extends StatelessWidget {
  const _ThumbChoicePill({
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
                color: selected ? color : AppColors.line, width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? color : AppColors.inkMuted, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: selected ? color : AppColors.inkMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ],
          ),
        ),
      );
}

class _ApplicationsEmpty extends StatelessWidget {
  const _ApplicationsEmpty({required this.onBrowse});
  final VoidCallback onBrowse;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                  color: AppColors.paleBlue,
                  borderRadius: BorderRadius.circular(28)),
              child: const Icon(Icons.description_outlined,
                  color: AppColors.blue, size: 44),
            ),
            const SizedBox(height: 18),
            const Text('No Applications Yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Your application status will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkMuted, fontSize: 13)),
            const SizedBox(height: 20),
            FilledButton.icon(
                onPressed: onBrowse,
                icon: const Icon(Icons.work_outline_rounded),
                label: const Text('Browse Jobs')),
          ]),
        ),
      );
}

class _ApplicationsError extends StatelessWidget {
  const _ApplicationsError({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.line, size: 52),
            const SizedBox(height: 12),
            const Text('Applications are unavailable right now.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.navy, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again')),
          ]),
        ),
      );
}

class _ApplicationsSkeleton extends StatelessWidget {
  const _ApplicationsSkeleton();
  @override
  Widget build(BuildContext context) => ShimmerLoading(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            const _ShimmerBlock(height: 26, width: 170),
            const SizedBox(height: 8),
            const _ShimmerBlock(height: 14, width: 230),
            const SizedBox(height: 20),
            for (var i = 0; i < 4; i++) ...[
              const _SkeletonCard(),
              const SizedBox(height: 12)
            ],
          ],
        ),
      );
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) => Container(
        height: 132,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line)),
        child:
            const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ShimmerBlock(height: 52, width: 52),
          SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _ShimmerBlock(height: 16, width: double.infinity),
                SizedBox(height: 9),
                _ShimmerBlock(height: 12, width: 130),
                SizedBox(height: 9),
                _ShimmerBlock(height: 12, width: 180),
              ])),
        ]),
      );
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({required this.height, required this.width});
  final double height;
  final double width;
  @override
  Widget build(BuildContext context) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
          color: AppColors.line.withValues(alpha: .35),
          borderRadius: BorderRadius.circular(8)));
}

String _formatDate(DateTime? date) {
  if (date == null) return 'just now';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
