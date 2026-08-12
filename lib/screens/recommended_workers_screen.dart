import 'package:flutter/material.dart';

import '../data/worker_filters.dart';
import '../repositories/household_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/household/worker_filter_sheet.dart';
import '../widgets/shimmer_loading.dart';
import 'household_home_screen.dart' show WorkerCard;

/// Full list of available workers, opened from the "See All" action on the
/// Recommended Workers section of the household dashboard.
///
/// Reuses [WorkerCard] (and, on tap, the existing [WorkerDetailScreen]) so
/// the visual language matches the dashboard carousel exactly. Loading,
/// empty, and error states follow the same shimmer / illustration / retry
/// pattern used throughout the Household module (see [SavedJobsScreen]).
///
/// Carries its own independent [WorkerFilters] state — filtering here never
/// touches the dashboard's filters and vice versa — using the same
/// [WorkerFilterEngine] so both screens filter identically.
class RecommendedWorkersScreen extends StatefulWidget {
  const RecommendedWorkersScreen({super.key});

  @override
  State<RecommendedWorkersScreen> createState() =>
      _RecommendedWorkersScreenState();
}

class _RecommendedWorkersScreenState extends State<RecommendedWorkersScreen> {
  late Stream<List<WorkerProfile>> _workersStream;
  WorkerFilters _filters = const WorkerFilters();

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

  Future<void> _openFilters() async {
    final result = await showWorkerFilterSheet(context, _filters);
    if (result != null && mounted) {
      setState(() => _filters = result);
    }
  }

  void _clearFilters() => setState(() => _filters = const WorkerFilters());

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
          actions: [
            IconButton(
              onPressed: _openFilters,
              icon: Icon(
                Icons.tune_rounded,
                color: _filters.isActive ? AppColors.blue : AppColors.navy,
              ),
              tooltip: 'Filter workers',
            ),
          ],
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
              final all = snapshot.data ?? const <WorkerProfile>[];
              final workers =
                  WorkerFilterEngine.apply(all, filters: _filters);
              if (workers.isEmpty) {
                return EmptyState(
                  icon: Icons.badge_outlined,
                  title: _filters.isActive
                      ? 'No Workers Found'
                      : 'No Workers Available',
                  message: _filters.isActive
                      ? 'Try adjusting your filters to see more workers.'
                      : 'Check back soon — new workers join every day.',
                  actionLabel: _filters.isActive ? 'Clear Filters' : null,
                  onAction: _filters.isActive ? _clearFilters : null,
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
