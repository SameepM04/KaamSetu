import 'package:flutter/material.dart';

import '../repositories/jobs_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
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
                return const SkeletonList(count: 5);
              }
              if (snapshot.hasError) {
                return ErrorState(
                  onRetry: _refresh,
                  message: "We couldn't load your saved jobs.",
                );
              }
              final entries = snapshot.data ?? const <SavedJobEntry>[];
              if (entries.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 140),
                      EmptyState(
                        icon: Icons.bookmark_border_rounded,
                        title: 'No Saved Jobs Yet',
                        message: 'Jobs you bookmark will appear here.',
                        actionLabel: 'Browse Jobs',
                        onAction: () => Navigator.of(context).pop(),
                      ),
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
