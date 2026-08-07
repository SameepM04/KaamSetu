import 'package:flutter/material.dart';

import '../animations/page_transition.dart';
import '../repositories/jobs_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/jobs/application_status_chip.dart';
import '../widgets/jobs/application_timeline.dart';
import '../widgets/jobs/withdraw_application_button.dart';
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
                  return _ApplicationCard(entry: entries[index - 1]);
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
  const _ApplicationCard({required this.entry});
  final ApplicationEntry entry;

  @override
  Widget build(BuildContext context) {
    final job = entry.toJobPreview();
    return JobPreviewCard(
      job: job,
      heroTag: 'applications-${entry.jobId}',
      bottomContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text('Applied ${_formatDate(entry.appliedAt)}',
                    style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600))),
            ApplicationStatusChip(status: entry.status),
            TextButton(
              onPressed: () => Navigator.of(context).push(premiumPageRoute(
                  JobDetailsScreen(
                      job: job, heroTag: 'applications-${entry.jobId}'))),
              child: const Text('Details'),
            ),
          ]),
          const SizedBox(height: 8),
          ApplicationTimeline(entry: entry),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
                child: Text(
                    'Last updated ${_formatDate(entry.lastUpdated)}',
                    style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600))),
            WithdrawApplicationButton(entry: entry),
          ]),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) => ListView(
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
