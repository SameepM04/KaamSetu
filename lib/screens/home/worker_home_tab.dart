import 'package:flutter/material.dart';

import '../../animations/page_transition.dart';
import '../../data/job_categories.dart';
import '../../data/job_previews.dart';
import '../../repositories/jobs_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/home/category_icon.dart';
import '../../widgets/home/worker_profile_avatar.dart';
import '../../widgets/jobs/bookmark_button.dart';
import '../../services/local_worker_session.dart';
import '../../services/worker_auth_service.dart';
import '../all_categories_screen.dart';
import '../job_details_screen.dart';
import '../jobs_screen.dart';
import '../worker_profile_screen.dart';

/// The real Worker Home content — App Bar / greeting / search / categories /
/// statistics / today's earnings + active job / nearby jobs / recommended
/// (or the complete-profile prompt) — matching the approved design pixel
/// for pixel. Everything reads live from `workers/{uid}` in Firestore with
/// zero-state defaults when a field hasn't been written yet.
///
/// [onNavigateToTab] lets pieces of this screen (search bar, "See all",
/// category cards, job cards) jump to sibling tabs in the parent
/// [IndexedStack] (1 = Jobs) without this widget knowing about the shell.
class WorkerHomeTab extends StatelessWidget {
  const WorkerHomeTab({super.key, required this.navigateToJobs});

  static final _workerService = WorkerAuthService();

  final ValueChanged<JobCategory?> navigateToJobs;

  @override
  Widget build(BuildContext context) {
    final uid = _workerService.currentUserId;

    // No signed-in user (e.g. a kDebugMode run, where sign up never calls
    // Firebase — see LocalWorkerSession) — fall back to whatever the
    // debug session has, instead of an empty map that would always show
    // the "Worker" default no matter what name was entered at sign up.
    if (uid == null) {
      return _WorkerHomeBody(
          data: LocalWorkerSession.data, navigateToJobs: navigateToJobs);
    }

    return StreamBuilder<Map<String, dynamic>>(
      stream: _workerService.workerProfileStream(uid),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const <String, dynamic>{};
        return _WorkerHomeBody(data: data, navigateToJobs: navigateToJobs);
      },
    );
  }
}

class _WorkerHomeBody extends StatelessWidget {
  const _WorkerHomeBody({required this.data, required this.navigateToJobs});

  final Map<String, dynamic> data;
  final ValueChanged<JobCategory?> navigateToJobs;

  // The Home "Complete your profile" card now opens the Worker Profile
  // screen itself (header + completion % + section cards) instead of
  // jumping straight into the standalone Complete Profile flow, so the
  // worker lands on the same foundation screen reachable from the bottom
  // nav's Profile tab. `fullName` is threaded through so a signed-in-but-
  // Firestore-empty worker still sees their name instead of "Worker".
  void _openCompleteProfile(BuildContext context, String fullName) {
    Navigator.of(context)
        .push(premiumPageRoute(const WorkerProfileScreen()));
  }

  /// Returns true when all 10 required profile fields are present —
  /// mirroring the calculation in WorkerProfileScreen._ProfileCompletion.
  /// Phone number is intentionally excluded.
  static bool _isProfileComplete(Map<String, dynamic> data) {
    const keys = [
      'fullName',
      'address',
      'skills',
      'experienceYears',
      'preferredCategories',
      'availability',
      'workingRadiusKm',
      'expectedDailyWage',
      'languagesKnown',
    ];

    bool isFilled(dynamic value) => switch (value) {
          null => false,
          String s => s.trim().isNotEmpty,
          Iterable i => i.isNotEmpty,
          num n => n > 0,
          _ => true,
        };

    final hasPhoto = isFilled(data['profilePhotoURL']) ||
        isFilled(data['selectedAvatar']);
    if (!hasPhoto) return false;
    return keys.every((k) => isFilled(data[k]));
  }

  @override
  Widget build(BuildContext context) {
    final fullName = (data['fullName'] as String?)?.trim();
    final firstName = (fullName == null || fullName.isEmpty)
        ? 'Worker'
        : fullName.split(' ').first;
    final selectedAvatar = data['selectedAvatar'] as String?;
    final profilePhotoURL = data['profilePhotoURL'] as String?;

    final stats = (data['stats'] as Map<String, dynamic>?) ?? const {};
    final applied = (stats['applied'] as num?)?.toInt() ?? 0;
    final accepted = (stats['accepted'] as num?)?.toInt() ?? 0;
    final completed = (stats['completed'] as num?)?.toInt() ?? 0;

    final todayEarnings = (data['todayEarnings'] as num?)?.toInt() ?? 0;
    final activeJob = data['activeJob'] as Map<String, dynamic>?;
    // Dynamic completion — mirrors WorkerProfileScreen._ProfileCompletion:
    // 10 equally-weighted fields (phone excluded). Card hides at 100%.
    final profileCompleted = _isProfileComplete(data);
    final unreadNotifications =
        (data['unreadNotifications'] as num?)?.toInt() ?? 0;

    void openJobDetails(JobPreview job, String heroTag) =>
        Navigator.of(context).push(
          premiumPageRoute(JobDetailsScreen(job: job, heroTag: heroTag)),
        );

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AppBarRow(
                    unreadNotifications: unreadNotifications,
                    selectedAvatar: selectedAvatar,
                    profilePhotoURL: profilePhotoURL,
                  ),
                  const SizedBox(height: 22),
                  _GreetingBlock(firstName: firstName),
                  const SizedBox(height: 16),
                  _SearchBar(onTap: () => navigateToJobs(null)),
                  const SizedBox(height: 24),
                  _SectionHeaderWithAction(
                    title: 'Browse by Skill',
                    actionLabel: 'See all',
                    onAction: () => Navigator.of(context).push(
                      premiumPageRoute(AllCategoriesScreen(
                          onSelectCategory: navigateToJobs)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _CategoryRow(onTap: navigateToJobs),
                  const SizedBox(height: 22),
                  _StatsRow(
                      applied: applied,
                      accepted: accepted,
                      completed: completed),
                  const SizedBox(height: 16),
                  _EarningsAndActiveJobCard(
                      amount: todayEarnings, job: activeJob),
                  const SizedBox(height: 24),
                  _SectionHeaderWithAction(
                    title: 'Nearby Jobs',
                    actionLabel: 'See all',
                    onAction: () => navigateToJobs(null),
                  ),
                  const SizedBox(height: 14),
                  _NearbyJobsList(onOpen: openJobDetails),
                  const SizedBox(height: 24),
                  _SectionHeaderWithAction(
                    title: 'Recommended for You',
                    actionLabel: 'See all',
                    onAction: () => navigateToJobs(null),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _RecommendedList(onTap: openJobDetails)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                children: [
                  if (!profileCompleted)
                    _CompleteProfileCard(
                        onTap: () => _openCompleteProfile(
                            context, fullName ?? 'Worker')),
                  if (!profileCompleted) const SizedBox(height: 12),
                  const _InviteEarnCard(),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App bar: compact brand lockup + notification bell + profile avatar
// ---------------------------------------------------------------------------

class _AppBarRow extends StatelessWidget {
  const _AppBarRow(
      {required this.unreadNotifications,
      required this.selectedAvatar,
      required this.profilePhotoURL});

  final int unreadNotifications;
  final String? selectedAvatar;
  final String? profilePhotoURL;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _CompactBrandLockup()),
        _NotificationBell(count: unreadNotifications, onTap: () {}),
        const SizedBox(width: 12),
        WorkerProfileAvatar(
            selectedAvatar: selectedAvatar,
            profilePhotoURL: profilePhotoURL,
            size: 46),
      ],
    );
  }
}

/// Horizontal "logo icon + KaamSetu + tagline" lockup for the Home app bar.
/// Reuses the same official logo asset and text styling as
/// `KaamSetuBrand`, just arranged inline instead of stacked, since the
/// approved Home design places it top-left in a compact row rather than
/// centered as a splash/onboarding hero.
class _CompactBrandLockup extends StatelessWidget {
  const _CompactBrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Image.asset('assets/branding/kaamsetu_official_logo.png',
              fit: BoxFit.contain, filterQuality: FilterQuality.high),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.6,
                    height: 1),
                children: [
                  TextSpan(
                      text: 'Kaam', style: TextStyle(color: AppColors.blue)),
                  TextSpan(
                      text: 'Setu', style: TextStyle(color: AppColors.orange)),
                ],
              ),
            ),
            const Text('Bridging Work. Building Trust.',
                style: TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _NotificationBell extends StatefulWidget {
  const _NotificationBell({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      value: 1,
      lowerBound: .9,
      upperBound: 1);

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scale.animateTo(.9),
      onTapUp: (_) => _scale.animateTo(1),
      onTapCancel: () => _scale.animateTo(1),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded,
                  color: AppColors.navy, size: 27),
              if (widget.count > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: const BoxDecoration(
                        color: Color(0xFFE5484D), shape: BoxShape.circle),
                    child: Text(
                      widget.count > 9 ? '9+' : '${widget.count}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Greeting
// ---------------------------------------------------------------------------

class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock({required this.firstName});
  final String firstName;

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text('${_greeting()}, $firstName!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.4)),
            ),
            const SizedBox(width: 6),
            const Text('👋', style: TextStyle(fontSize: 20)),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Find work, earn with dignity and\ngrow every day.',
            style: TextStyle(
                color: AppColors.inkMuted,
                fontSize: 14,
                height: 1.32,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      value: 1,
      lowerBound: .98,
      upperBound: 1);

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scale.animateTo(.98),
      onTapUp: (_) => _scale.animateTo(1),
      onTapCancel: () => _scale.animateTo(1),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x14102A54),
                  blurRadius: 16,
                  offset: Offset(0, 6))
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded,
                  color: AppColors.inkMuted, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Search for jobs, skills or locations...',
                    style: TextStyle(
                        color: AppColors.inkMuted.withValues(alpha: .85),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500)),
              ),
              const Icon(Icons.tune_rounded, color: AppColors.navy, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section headers
// ---------------------------------------------------------------------------

class _SectionHeaderWithAction extends StatelessWidget {
  const _SectionHeaderWithAction(
      {required this.title, required this.actionLabel, required this.onAction});

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.navy,
                fontSize: 16.5,
                fontWeight: FontWeight.w800)),
        InkWell(
          onTap: onAction,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(actionLabel,
                style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Categories
// ---------------------------------------------------------------------------

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.onTap});
  final ValueChanged<JobCategory> onTap;

  @override
  Widget build(BuildContext context) {
    // Horizontal, smooth-scrolling row — all 9 categories fit without
    // overflow on any width (320dp–412dp+) since the list simply scrolls
    // instead of being squeezed into a fixed-width Row.
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: JobCategoryMapper.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) =>
            _CategoryCard(category: JobCategoryMapper.all[i], onTap: onTap),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final JobCategory category;
  final ValueChanged<JobCategory> onTap;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      value: 1,
      lowerBound: .9,
      upperBound: 1);

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scale.animateTo(.9),
      onTapUp: (_) => _scale.animateTo(1),
      onTapCancel: () => _scale.animateTo(1),
      onTap: () => widget.onTap(widget.category),
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: 70,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              JobCategoryIcon(category: widget.category),
              const SizedBox(height: 7),
              Text(
                JobCategoryMapper.displayName(widget.category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Statistics
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow(
      {required this.applied, required this.accepted, required this.completed});

  final int applied;
  final int accepted;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
              value: applied,
              valueLabel: 'Applied',
              color: AppColors.blue,
              bg: const Color(0xFFEAF1FF),
              icon: Icons.description_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
              value: accepted,
              valueLabel: 'Accepted',
              color: AppColors.green,
              bg: const Color(0xFFE6F8ED),
              icon: Icons.check_circle_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
              value: completed,
              valueLabel: 'Completed',
              color: const Color(0xFF7C5CE0),
              bg: const Color(0xFFF0EBFC),
              icon: Icons.work_history_rounded),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.value,
      required this.valueLabel,
      required this.color,
      required this.bg,
      required this.icon});

  final int value;
  final String valueLabel;
  final Color color;
  final Color bg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .7),
                shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text('$value',
              style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(valueLabel,
              style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today's earnings + Active job (combined card, matches approved design)
// ---------------------------------------------------------------------------

class _EarningsAndActiveJobCard extends StatelessWidget {
  const _EarningsAndActiveJobCard({required this.amount, required this.job});

  final int amount;
  final Map<String, dynamic>? job;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF3E3),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF3E1BE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: Color(0xFF7C5CE0), size: 19),
                    ),
                    const SizedBox(width: 10),
                    const Text("Today's Earnings",
                        style: TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('₹$amount',
                    style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5)),
                const SizedBox(height: 4),
                Text(
                  amount > 0
                      ? "Keep going! You're doing great."
                      : 'Complete a job to start earning.',
                  style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (job != null) const SizedBox(width: 12),
          if (job != null) Expanded(child: _ActiveJobInline(job: job!)),
        ],
      ),
    );
  }
}

class _ActiveJobInline extends StatelessWidget {
  const _ActiveJobInline({required this.job});
  final Map<String, dynamic> job;

  @override
  Widget build(BuildContext context) {
    final title = job['title'] as String? ?? 'Job';
    final location = job['location'] as String? ?? '';
    final time = job['time'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(8)),
          child: const Text('Active Job',
              style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 8),
        Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppColors.navy,
                fontSize: 13.5,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Row(children: [
          const Icon(Icons.place_rounded, color: AppColors.inkMuted, size: 13),
          const SizedBox(width: 3),
          Expanded(
              child: Text(location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500))),
        ]),
        const SizedBox(height: 3),
        Row(children: [
          const Icon(Icons.calendar_today_rounded,
              color: AppColors.inkMuted, size: 12),
          const SizedBox(width: 4),
          Expanded(
              child: Text(time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500))),
        ]),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Nearby jobs use the same preview data and card as the Jobs tab.
// ---------------------------------------------------------------------------

class _NearbyJobsList extends StatelessWidget {
  const _NearbyJobsList({required this.onOpen});
  final void Function(JobPreview job, String heroTag) onOpen;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<JobPreview>>(
      valueListenable: JobsRepository.instance.jobs,
      builder: (context, jobs, _) {
        final nearby = jobs.take(3).toList(growable: false);
        return Column(
          children: [
            for (var index = 0; index < nearby.length; index++) ...[
              _NearbyJobCard(job: nearby[index], onOpen: onOpen),
              if (index + 1 < nearby.length) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _NearbyJobCard extends StatelessWidget {
  const _NearbyJobCard({required this.job, required this.onOpen});
  final JobPreview job;
  final void Function(JobPreview job, String heroTag) onOpen;

  @override
  Widget build(BuildContext context) {
    final heroTag = 'home-nearby-${job.id}';
    return JobPreviewCard(
      job: job,
      heroTag: heroTag,
      actionLabel: 'Apply now',
      onTap: () => onOpen(job, heroTag),
      onAction: () => onOpen(job, heroTag),
    );
  }
}

// ---------------------------------------------------------------------------
// Recommended for you
// ---------------------------------------------------------------------------

class _RecommendedList extends StatelessWidget {
  const _RecommendedList({required this.onTap});
  final void Function(JobPreview job, String heroTag) onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<JobPreview>>(
      valueListenable: JobsRepository.instance.jobs,
      builder: (context, jobs, _) {
        final recommended = jobs
            .where((job) =>
                job.category == JobCategory.cleaning ||
                job.category == JobCategory.electrical)
            .take(3)
            .toList(growable: false);
        return SizedBox(
          height: 190,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recommended.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) =>
                _RecommendedCard(item: recommended[i], onTap: onTap),
          ),
        );
      },
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.item, required this.onTap});
  final JobPreview item;
  final void Function(JobPreview job, String heroTag) onTap;

  @override
  Widget build(BuildContext context) {
    final category = JobCategoryMapper.fromJobTitle(item.title)!;
    final heroTag = 'home-recommended-${item.id}';
    return GestureDetector(
      onTap: () => onTap(item, heroTag),
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: heroTag,
                  child: JobCategoryIcon(
                      category: category,
                      size: 56,
                      borderRadius: 13,
                      iconSize: 26),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: BookmarkButton(job: item, size: 18),
                ),
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: ValueListenableBuilder<Map<String, ApplicationEntry>>(
                    valueListenable: JobsRepository.instance.applications,
                    builder: (context, applications, _) =>
                        applications.containsKey(item.id)
                            ? const CircleAvatar(
                                radius: 10,
                                backgroundColor: AppColors.green,
                                child: Icon(Icons.check_rounded,
                                    color: Colors.white, size: 14),
                              )
                            : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text('${item.location} · ${item.distanceKm}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.currency_rupee_rounded,
                  color: AppColors.green, size: 12),
              Expanded(
                  child: Text(item.pay.replaceFirst('₹', ''),
                      style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800))),
            ]),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: JobCategoryMapper.backgroundColor(category),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(JobCategoryMapper.displayName(category),
                  style: TextStyle(
                      color: JobCategoryMapper.accentColor(category),
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Complete your profile
// ---------------------------------------------------------------------------

class _CompleteProfileCard extends StatelessWidget {
  const _CompleteProfileCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          color: const Color(0xFFEAF1FF),
          borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
                color: AppColors.blue, shape: BoxShape.circle),
            child: const Icon(Icons.verified_rounded,
                color: Colors.white, size: 21),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Complete your profile',
                    style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Increase your chances of getting more jobs.',
                    style: TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _PillButton(
              label: 'Complete Now', color: AppColors.blue, onTap: onTap),
        ],
      ),
    );
  }
}

class _InviteEarnCard extends StatelessWidget {
  const _InviteEarnCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          color: const Color(0xFFE6F8ED),
          borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
                color: AppColors.green, shape: BoxShape.circle),
            child:
                const Icon(Icons.groups_rounded, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invite & Earn',
                    style: TextStyle(
                        color: AppColors.green,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Invite friends and earn exciting rewards.',
                    style: TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _PillButton(
              label: 'Invite Now', color: AppColors.green, onTap: () {}),
        ],
      ),
    );
  }
}

class _PillButton extends StatefulWidget {
  const _PillButton(
      {required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      value: 1,
      lowerBound: .93,
      upperBound: 1);

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scale.animateTo(.93),
      onTapUp: (_) => _scale.animateTo(1),
      onTapCancel: () => _scale.animateTo(1),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Text(widget.label,
              style: TextStyle(
                  color: widget.color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
