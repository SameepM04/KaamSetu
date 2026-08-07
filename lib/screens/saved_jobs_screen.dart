import 'package:flutter/material.dart';

import '../repositories/jobs_repository.dart';
import '../theme/app_colors.dart';
import 'jobs_screen.dart';

/// Displays the current user's shared Firestore-backed saved-jobs cache.
class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  final _repository = JobsRepository.instance;
  late final Stream<List<SavedJobEntry>> _savedJobsStream;

  @override
  void initState() {
    super.initState();
    _savedJobsStream = _repository.savedJobsStream();
  }

  Future<void> _refresh() => _repository.refreshSavedJobs();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.mist,
        appBar: AppBar(
          backgroundColor: AppColors.mist,
          elevation: 0,
          foregroundColor: AppColors.navy,
          title: const Text('Saved Jobs',
              style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
        ),
        body: SafeArea(
          top: false,
          child: StreamBuilder<List<SavedJobEntry>>(
            stream: _savedJobsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _SavedJobsSkeleton();
              }
              if (snapshot.hasError) {
                return _SavedJobsError(onRetry: _refresh);
              }
              final entries = snapshot.data ?? const <SavedJobEntry>[];
              if (entries.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 180),
                      _SavedJobsEmpty(),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => JobPreviewCard(
                    job: entries[index].toJobPreview(),
                    heroTag: 'saved-jobs-${entries[index].jobId}',
                  ),
                ),
              );
            },
          ),
        ),
      );
}

class _SavedJobsEmpty extends StatelessWidget {
  const _SavedJobsEmpty();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bookmark_border_rounded,
                  color: AppColors.line, size: 52),
              const SizedBox(height: 14),
              const Text('No Saved Jobs Yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Jobs you bookmark will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Browse Jobs'),
              ),
            ],
          ),
        ),
      );
}

class _SavedJobsError extends StatelessWidget {
  const _SavedJobsError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: AppColors.line, size: 46),
              const SizedBox(height: 12),
              const Text("Couldn't load your saved jobs",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}

class _SavedJobsSkeleton extends StatelessWidget {
  const _SavedJobsSkeleton();

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 92,
          decoration: BoxDecoration(
            color: AppColors.line.withValues(alpha: .35),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
}
