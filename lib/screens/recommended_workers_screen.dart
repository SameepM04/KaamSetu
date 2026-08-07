import 'package:flutter/material.dart';

import '../repositories/household_repository.dart';
import '../theme/app_colors.dart';
import 'household_home_screen.dart' show WorkerCard;

/// Full list of available workers, opened from the "See All" action on the
/// Recommended Workers section of the household dashboard.
///
/// Reuses [WorkerCard] (and, on tap, the existing [WorkerDetailScreen]) so
/// the visual language matches the dashboard carousel exactly.
class RecommendedWorkersScreen extends StatelessWidget {
  const RecommendedWorkersScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.mist,
        appBar: AppBar(
          backgroundColor: AppColors.mist,
          title: const Text('Recommended Workers'),
        ),
        body: StreamBuilder<List<WorkerProfile>>(
          stream: HouseholdRepository.instance.workersStream(),
          builder: (context, snapshot) {
            final workers = snapshot.data ?? const <WorkerProfile>[];
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (workers.isEmpty) {
              return const Center(
                child: Text(
                  'No workers available right now.',
                  style: TextStyle(color: AppColors.inkMuted),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
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
      );
}
