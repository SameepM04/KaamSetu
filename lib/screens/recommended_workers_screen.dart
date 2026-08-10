import 'package:flutter/material.dart';

import '../repositories/household_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
import 'household_home_screen.dart' show WorkerCard;

/// Full list of available workers, opened from the "See All" action on the
/// Recommended Workers section of the household dashboard.
///
/// Reuses [WorkerCard] (and, on tap, the existing [WorkerDetailScreen]) so
/// the visual language matches the dashboard carousel exactly. Loading,
/// empty, and error states follow the same shimmer / illustration / retry
/// pattern used throughout the Household module (see [SavedJobsScreen]).
class RecommendedWorkersScreen extends StatefulWidget {
  const RecommendedWorkersScreen({super.key});

  @override
  State<RecommendedWorkersScreen> createState() =>
      _RecommendedWorkersScreenState();
}

class _RecommendedWorkersScreenState extends State<RecommendedWorkersScreen> {
  late Stream<List<WorkerProfile>> _workersStream;

  @override
  void initState() {
    super.initState();
    _workersStream = HouseholdRepository.instance.workersStream();
  }

  void _retry() {
    setState(() {
      _workersStream = HouseholdRepository.instance.workersStream();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.mist,
        appBar: AppBar(
          backgroundColor: AppColors.mist,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: const BackButton(color: AppColors.navy),
          centerTitle: false,
          title: const Text(
            'Recommended Workers',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: StreamBuilder<List<WorkerProfile>>(
            stream: _workersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SkeletonList(itemBuilder: _skeletonItem, count: 6);
              }
              if (snapshot.hasError) {
                return ErrorState(
                  onRetry: _retry,
                  message:
                      "We couldn't load recommended workers. Please try again.",
                );
              }
              final workers = snapshot.data ?? const <WorkerProfile>[];
              if (workers.isEmpty) {
                return const EmptyState(
                  icon: Icons.badge_outlined,
                  title: 'No Workers Available',
                  message: 'Check back soon — new workers join every day.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: workers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, i) => TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 250 + i * 40),
                  curve: Curves.easeOut,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * 14),
                      child: child,
                    ),
                  ),
                  child: WorkerCard(worker: workers[i]),
                ),
              );
            },
          ),
        ),
      );

  static Widget _skeletonItem(BuildContext context) =>
      const WorkerCardSkeleton();
}
