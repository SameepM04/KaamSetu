import 'package:flutter/material.dart';

import '../../services/local_worker_session.dart';
import '../../services/worker_auth_service.dart';
import '../../theme/app_colors.dart';

/// Ratings & Reviews screen (read-only).
///
/// Reads `workers/{uid}` for `averageRating`, `totalReviews`, and
/// `completedJobs` and streams `workers/{uid}/reviews` for individual
/// review entries. No write operations are performed — this screen is
/// display-only.
class RatingsScreen extends StatelessWidget {
  const RatingsScreen({super.key});

  static final _workerService = WorkerAuthService();

  @override
  Widget build(BuildContext context) {
    final uid = _workerService.currentUserId;

    // Debug / Fake OTP mode: read from local session
    if (uid == null) {
      return _RatingsBody(
        profileData: LocalWorkerSession.data,
        reviews: const [],
        loading: false,
        hasError: false,
      );
    }

    return StreamBuilder<Map<String, dynamic>>(
      stream: _workerService.workerProfileStream(uid),
      builder: (context, profileSnap) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _workerService.workerReviewsStream(uid),
          builder: (context, reviewsSnap) {
            final loading =
                profileSnap.connectionState == ConnectionState.waiting ||
                    reviewsSnap.connectionState == ConnectionState.waiting;
            final hasError =
                profileSnap.hasError || reviewsSnap.hasError;
            return _RatingsBody(
              profileData: profileSnap.data ?? const {},
              reviews: reviewsSnap.data ?? const [],
              loading: loading,
              hasError: hasError,
            );
          },
        );
      },
    );
  }
}

class _RatingsBody extends StatelessWidget {
  const _RatingsBody({
    required this.profileData,
    required this.reviews,
    required this.loading,
    required this.hasError,
  });

  final Map<String, dynamic> profileData;
  final List<Map<String, dynamic>> reviews;
  final bool loading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        backgroundColor: AppColors.mist,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ratings & Reviews',
            style: TextStyle(
                color: AppColors.navy, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: AppColors.navy),
      ),
      body: SafeArea(
        child: loading
            ? const _RatingsSkeleton()
            : hasError
                ? const _ErrorState()
                : _RatingsContent(
                    profileData: profileData, reviews: reviews),
      ),
    );
  }
}

class _RatingsContent extends StatelessWidget {
  const _RatingsContent(
      {required this.profileData, required this.reviews});

  final Map<String, dynamic> profileData;
  final List<Map<String, dynamic>> reviews;

  @override
  Widget build(BuildContext context) {
    final avgRating =
        (profileData['averageRating'] as num?)?.toDouble() ?? 0.0;
    final totalReviews =
        (profileData['totalReviews'] as num?)?.toInt() ?? 0;
    final completedJobs =
        (profileData['completedJobs'] as num?)?.toInt() ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Overall summary card
        _RatingSummaryCard(
            avgRating: avgRating,
            totalReviews: totalReviews,
            completedJobs: completedJobs),
        const SizedBox(height: 24),

        if (reviews.isEmpty)
          const _EmptyReviews()
        else ...[
          const Text('All Reviews',
              style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          for (final review in reviews) ...[
            _ReviewCard(data: review),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard({
    required this.avgRating,
    required this.totalReviews,
    required this.completedJobs,
  });

  final double avgRating;
  final int totalReviews;
  final int completedJobs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2457), Color(0xFF1463EC)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: Color(0x301463EC),
              blurRadius: 20,
              offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // Big rating number
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(avgRating == 0 ? '—' : avgRating.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      height: 1)),
              if (avgRating > 0) ...[
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('/5',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 20,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Star row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < avgRating.round();
              return Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: filled ? AppColors.warmGold : Colors.white38,
                size: 24,
              );
            }),
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  value: '$totalReviews',
                  label: 'Reviews',
                  icon: Icons.rate_review_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatPill(
                  value: '$completedJobs',
                  label: 'Jobs Done',
                  icon: Icons.check_circle_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill(
      {required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final name =
        (data['householdName'] as String?)?.trim() ?? 'Anonymous';
    final rating = (data['rating'] as num?)?.toInt() ?? 0;
    final comment =
        (data['comment'] as String?)?.trim() ?? '';
    final date = data['date'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                    color: AppColors.paleBlue, shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded,
                    color: AppColors.blue, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800)),
                    if (date.isNotEmpty)
                      Text(date,
                          style: const TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              // Star rating
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color:
                        i < rating ? AppColors.warmGold : AppColors.line,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(comment,
                style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty, error and loading states
// ---------------------------------------------------------------------------

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: AppColors.paleBlue, shape: BoxShape.circle),
              child: const Icon(Icons.star_outline_rounded,
                  color: AppColors.blue, size: 40),
            ),
            const SizedBox(height: 18),
            const Text('No Reviews Yet',
                style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Complete jobs to earn reviews\nfrom households.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.error_outline_rounded,
                color: AppColors.inkMuted, size: 52),
            SizedBox(height: 14),
            Text('Could not load reviews',
                style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _RatingsSkeleton extends StatefulWidget {
  const _RatingsSkeleton();

  @override
  State<_RatingsSkeleton> createState() => _RatingsSkeletonState();
}

class _RatingsSkeletonState extends State<_RatingsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final opacity = .35 + (_ctrl.value * .35);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _block(height: 160, opacity: opacity),
            const SizedBox(height: 24),
            _block(height: 18, width: 140, opacity: opacity),
            const SizedBox(height: 14),
            for (var i = 0; i < 3; i++) ...[
              _block(height: 90, opacity: opacity),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _block(
      {required double height, double? width, required double opacity}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        color: AppColors.line.withValues(alpha: opacity),
      ),
    );
  }
}
