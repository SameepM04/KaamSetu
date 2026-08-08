import 'dart:async';

import 'package:flutter/material.dart';

import '../data/demo_workers.dart';
import '../data/job_categories.dart';
import '../data/job_filters.dart';
import '../repositories/household_repository.dart';
import '../services/worker_auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/home/category_icon.dart';
import '../widgets/home/worker_profile_avatar.dart';
import '../widgets/jobs/job_filter_sheet.dart';
import 'all_categories_screen.dart';
import 'login_screen.dart';
import 'recommended_workers_screen.dart';
import 'settings/help_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROOT — five-tab scaffold
// ─────────────────────────────────────────────────────────────────────────────

/// Household's five-tab root. Each tab is a real Firestore-backed surface and
/// remains mounted while the household moves between tabs.
class HouseholdHomeScreen extends StatefulWidget {
  const HouseholdHomeScreen({super.key});
  @override
  State<HouseholdHomeScreen> createState() => _HouseholdHomeScreenState();
}

class _HouseholdHomeScreenState extends State<HouseholdHomeScreen> {
  int _index = 0;
  void _go(int index) => setState(() => _index = index);
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.mist,
        body: IndexedStack(
          index: _index,
          children: [
            HouseholdDashboard(onTab: _go),
            MyHouseholdJobs(onPost: () => _go(2)),
            PostJobScreen(onPosted: () => _go(1)),
            SavedWorkersScreen(onBrowse: () => _go(0)),
            const HouseholdProfileScreen(),
          ],
        ),
        bottomNavigationBar: _HouseholdBottomNav(index: _index, onChanged: _go),
      );
}

class _HouseholdBottomNav extends StatelessWidget {
  const _HouseholdBottomNav({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;
  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.work_rounded, Icons.work_outline_rounded, 'My Jobs'),
    (Icons.add_circle_rounded, Icons.add_circle_outline_rounded, 'Post Job'),
    (Icons.bookmark_rounded, Icons.bookmark_outline_rounded, 'Saved'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A102A54),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => onChanged(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            i == index ? _items[i].$1 : _items[i].$2,
                            size: 23,
                            color: i == index
                                ? AppColors.blue
                                : AppColors.inkMuted,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _items[i].$3,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 10,
                              color: i == index
                                  ? AppColors.blue
                                  : AppColors.inkMuted,
                              fontWeight: i == index
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// A small press-scale + elevation wrapper used throughout the Household
/// Home screen to give cards and buttons a premium, tactile feel without
/// pulling in an animation package.
class _PressableScale extends StatefulWidget {
  const _PressableScale({
    required this.onTap,
    required this.child,
    this.borderRadius = 17,
  });
  final VoidCallback onTap;
  final Widget child;
  final double borderRadius;
  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;
  void _setPressed(bool value) => setState(() => _pressed = value);
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: widget.child,
            ),
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.action, this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                action!,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(message, style: const TextStyle(color: AppColors.inkMuted)),
      );
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF1FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.blue,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final String status;
  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'inProgress' => 'In Progress',
      'cancelled' => 'Cancelled',
      _ => '${status[0].toUpperCase()}${status.substring(1)}',
    };
    final color = switch (status) {
      'completed' => AppColors.green,
      'open' => AppColors.blue,
      'cancelled' => const Color(0xFFE53935),
      _ => AppColors.orange,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: AppColors.inkMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

class HouseholdDashboard extends StatefulWidget {
  const HouseholdDashboard({super.key, required this.onTab});
  final ValueChanged<int> onTab;
  @override
  State<HouseholdDashboard> createState() => _HouseholdDashboardState();
}

class _HouseholdDashboardState extends State<HouseholdDashboard> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  JobFilters _filters = const JobFilters();
  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (mounted) setState(() => _query = value.trim().toLowerCase());
    });
  }

  Future<void> _openFilters() async {
    final result =
        await showJobFilterSheet(context, _filters, forWorkers: true);
    if (result != null && mounted) {
      setState(() {
        _filters = result;
        if (result.category != null) {
          _search.text = JobCategoryMapper.displayName(result.category!);
          _query = _search.text.toLowerCase();
        }
      });
    }
  }

  Future<void> _browseCategories() async {
    final picked = await Navigator.push<JobCategory>(
      context,
      MaterialPageRoute(
        builder: (_) => AllCategoriesScreen(
          onSelectCategory: (c) => Navigator.pop(context, c),
        ),
      ),
    );
    if (picked != null && mounted) {
      _search.text = JobCategoryMapper.displayName(picked);
      _onSearch(_search.text);
    }
  }

  /// Applies the current [_filters] and text [_query] to the worker list.
  List<WorkerProfile> _applyFilters(List<WorkerProfile> all) {
    return all.where((worker) {
      // Text search
      if (_query.isNotEmpty) {
        final haystack =
            '${worker.name} ${worker.skills.join(' ')} ${worker.categories.join(' ')}'
                .toLowerCase();
        if (!haystack.contains(_query)) return false;
      }
      // Category filter
      if (_filters.category != null) {
        final filterCat =
            JobCategoryMapper.filterValue(_filters.category!).toLowerCase();
        if (!worker.categories
            .any((c) => c.toLowerCase() == filterCat)) {
          return false;
        }
      }
      // Salary range (wage)
      if (worker.wage < _filters.salaryRange.$1 ||
          worker.wage > _filters.salaryRange.$2) {
        return false;
      }
      // Distance
      if (worker.distance > _filters.maxDistance) return false;
      // Nearby only
      if (_filters.nearbyOnly && worker.distance > 3) return false;
      // Verified only
      if (_filters.verifiedOnly && !worker.verified) return false;
      // Availability — worker must offer at least one selected slot
      if (_filters.availability.isNotEmpty &&
          !worker.availability.any((a) => _filters.availability.contains(a))) {
        return false;
      }
      // Minimum rating
      if (_filters.minRating > 0 && worker.rating < _filters.minRating) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: StreamBuilder<HouseholdProfile>(
          stream: HouseholdRepository.instance.profileStream(),
          builder: (context, profile) => StreamBuilder<List<WorkerProfile>>(
            stream: HouseholdRepository.instance.workersStream(),
            builder: (context, workers) {
              final all = workers.data ?? const <WorkerProfile>[];
              final matches = _applyFilters(all);
              final isSearching = _query.isNotEmpty || _filters.isActive;
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DashboardHeader(profile: profile.data),
                          const SizedBox(height: 22),
                          _HouseholdGreetingBlock(
                            firstName: profile.data?.firstName ??
                                kDemoHouseholdProfile.firstName,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.line),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x14102A54),
                                        blurRadius: 16,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _search,
                                    onChanged: _onSearch,
                                    autofocus: false,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.navy,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.search_rounded,
                                        color: AppColors.inkMuted,
                                        size: 21,
                                      ),
                                      suffixIcon: _query.isEmpty
                                          ? null
                                          : IconButton(
                                              onPressed: () {
                                                _search.clear();
                                                _onSearch('');
                                              },
                                              icon: const Icon(
                                                  Icons.close_rounded),
                                            ),
                                      hintText:
                                          'Search workers, skills or categories...',
                                      hintStyle: TextStyle(
                                        color: AppColors.inkMuted
                                            .withValues(alpha: .85),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _FilterButton(
                                active: _filters.isActive,
                                onTap: _openFilters,
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          if (isSearching) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _SectionTitle(
                                    '${matches.length} result${matches.length == 1 ? '' : 's'}',
                                  ),
                                ),
                                if (_filters.isActive)
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _filters = const JobFilters();
                                        if (_query.isEmpty) _search.clear();
                                      });
                                    },
                                    icon: const Icon(Icons.clear_rounded,
                                        size: 16),
                                    label: const Text('Clear filters'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.blue,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (matches.isEmpty)
                              const _EmptyCard(
                                message:
                                    'No workers match your search. Try different filters.',
                              ),
                            for (final worker in matches)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child:
                                    WorkerCard(worker: worker, compact: false),
                              ),
                            const SizedBox(height: 8),
                          ] else ...[
                            _PostJobHeroCard(onPost: () => widget.onTab(2)),
                            const SizedBox(height: 26),
                            const _SectionTitle('Quick Actions'),
                            const SizedBox(height: 12),
                            _QuickActions(
                              onTab: widget.onTab,
                              onCategories: _browseCategories,
                            ),
                            const SizedBox(height: 26),
                            _SectionTitle(
                              'Recommended Workers',
                              action: 'See All',
                              onAction: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const RecommendedWorkersScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _WorkerCarousel(workers: all),
                            const SizedBox(height: 26),
                            _SectionTitle(
                              'Recent Jobs',
                              action: 'See All',
                              onAction: () => widget.onTab(1),
                            ),
                            const SizedBox(height: 12),
                            const _DashboardJobs(),
                            const SizedBox(height: 26),
                            const _SectionTitle('Recently hired'),
                            const SizedBox(height: 12),
                            const _RecentlyHired(),
                          ],
                          const SizedBox(height: 22),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
}

/// Same compact brand lockup + notification bell + profile avatar as the
/// Worker Home app bar, so both experiences feel like one application.
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({this.profile});
  final HouseholdProfile? profile;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.asset(
                    'assets/branding/kaamsetu_official_logo.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
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
                          height: 1,
                        ),
                        children: [
                          TextSpan(
                              text: 'Kaam',
                              style: TextStyle(color: AppColors.blue)),
                          TextSpan(
                              text: 'Setu',
                              style: TextStyle(color: AppColors.orange)),
                        ],
                      ),
                    ),
                    const Text(
                      'Bridging Work. Building Trust.',
                      style: TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _HouseholdNotificationBell(onTap: () {}),
          const SizedBox(width: 12),
          WorkerProfileAvatar(
            selectedAvatar: profile?.avatar ?? kDemoHouseholdProfile.avatar,
            profilePhotoURL: profile?.photoUrl,
            size: 46,
          ),
        ],
      );
}

class _HouseholdNotificationBell extends StatelessWidget {
  const _HouseholdNotificationBell({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: const SizedBox(
          width: 30,
          height: 30,
          child: Icon(
            Icons.notifications_none_rounded,
            color: AppColors.navy,
            size: 27,
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Greeting — matches Worker Home's time-of-day pattern exactly.
// ---------------------------------------------------------------------------

class _HouseholdGreetingBlock extends StatelessWidget {
  const _HouseholdGreetingBlock({required this.firstName});
  final String firstName;

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  '${_greeting()}, $firstName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.4,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text('👋', style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Find trusted help for your home.',
            style: TextStyle(
              color: AppColors.inkMuted,
              fontSize: 14,
              height: 1.32,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _PressableScale(
        onTap: onTap,
        borderRadius: 15,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border:
                active ? Border.all(color: AppColors.blue, width: 1.4) : null,
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F102A54),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.tune_rounded,
            color: active ? AppColors.blue : AppColors.inkMuted,
          ),
        ),
      );
}

/// The premium "Post a Job" hero card at the top of the dashboard.
class _PostJobHeroCard extends StatelessWidget {
  const _PostJobHeroCard({required this.onPost});
  final VoidCallback onPost;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 8, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.paleBlue,
              AppColors.paleBlue.withValues(alpha: .55),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Post a Job',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Find the right worker for your needs',
                    style: TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PressableScale(
                    onTap: onPost,
                    borderRadius: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Post Job',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 88,
                child: Icon(
                  Icons.assignment_turned_in_rounded,
                  size: 72,
                  color: AppColors.blue.withValues(alpha: .55),
                ),
              ),
            ),
          ],
        ),
      );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onTab, required this.onCategories});
  final ValueChanged<int> onTab;
  final VoidCallback onCategories;

  @override
  Widget build(BuildContext context) {
    final entries = <(IconData, String, VoidCallback)>[
      (Icons.category_rounded, 'Categories', onCategories),
      (Icons.bookmark_rounded, 'Saved Workers', () => onTab(3)),
      (Icons.work_history_rounded, 'My Jobs', () => onTab(1)),
      (
        Icons.star_rounded,
        'Reviews',
        () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const HouseholdReviewsScreen()),
            ),
      ),
      (
        Icons.support_agent_rounded,
        'Help & Support',
        () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            ),
      ),
    ];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = entries[i];
          return SizedBox(
            width: 92,
            child: _PressableScale(
              onTap: item.$3,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F102A54),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.$1, color: AppColors.blue),
                    const SizedBox(height: 8),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WorkerCarousel extends StatelessWidget {
  const _WorkerCarousel({required this.workers});
  final List<WorkerProfile> workers;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 275,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: workers.length > 5 ? 5 : workers.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) =>
              SizedBox(width: 276, child: WorkerCard(worker: workers[i])),
        ),
      );
}

class _DashboardJobs extends StatelessWidget {
  const _DashboardJobs();
  @override
  Widget build(BuildContext context) => StreamBuilder<List<HouseholdJob>>(
        stream: HouseholdRepository.instance.myJobsStream(),
        builder: (context, snapshot) {
          final jobs = snapshot.data
                  ?.where((j) => j.status != 'completed' && j.status != 'cancelled')
                  .take(3)
                  .toList() ??
              [];
          if (jobs.isEmpty) {
            return const _EmptyCard(
              message: 'No active jobs yet. Post a job to find help.',
            );
          }
          return Column(
            children: jobs
                .map(
                  (job) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: JobCard(job: job),
                  ),
                )
                .toList(),
          );
        },
      );
}

class _RecentlyHired extends StatelessWidget {
  const _RecentlyHired();
  @override
  Widget build(BuildContext context) => StreamBuilder<List<WorkerProfile>>(
        stream: HouseholdRepository.instance.savedWorkersStream(),
        builder: (context, snapshot) {
          final workers = snapshot.data ?? [];
          if (workers.isEmpty) {
            return const _EmptyCard(
                message: 'Workers you hire will appear here.');
          }
          return Column(
            children: workers
                .take(2)
                .map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: WorkerCard(worker: w, compact: true),
                  ),
                )
                .toList(),
          );
        },
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// WORKER CARD
// ─────────────────────────────────────────────────────────────────────────────

class WorkerCard extends StatelessWidget {
  const WorkerCard({super.key, required this.worker, this.compact = false});
  final WorkerProfile worker;
  final bool compact;
  void _open(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WorkerDetailScreen(worker: worker)),
      );
  @override
  Widget build(BuildContext context) {
    final category = worker.categories.isEmpty
        ? null
        : JobCategoryMapper.fromStorage(worker.categories.first);
    return _PressableScale(
      onTap: () => _open(context),
      borderRadius: 21,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: AppColors.line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D102A54),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.mist,
                      backgroundImage: workerAvatarImage(worker.photoUrl),
                      child: worker.photoUrl == null
                          ? Text(
                              worker.name.isNotEmpty
                                  ? worker.name[0].toUpperCase()
                                  : 'W',
                              style: const TextStyle(
                                color: AppColors.blue,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
                    if (category != null)
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: JobCategoryIcon(
                          category: category,
                          size: 22,
                          borderRadius: 7,
                          iconSize: 13,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              worker.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (worker.verified)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.verified_rounded,
                                color: AppColors.blue,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '★ ${worker.rating.toStringAsFixed(1)}  •  ${worker.reviews} reviews  •  ${worker.completedJobs} jobs',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: worker.skills.take(3).map((s) => _Tag(s)).toList(),
            ),
            const SizedBox(height: 9),
            Text(
              '${worker.languages.isEmpty ? 'Languages not specified' : worker.languages.join(', ')}  •  ₹${worker.wage}/day',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 11.5),
            ),
            const SizedBox(height: 5),
            Text(
              '${worker.distance.toStringAsFixed(1)} km away  •  ${worker.availability.isEmpty ? 'Availability on request' : worker.availability.first}',
              style: const TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
            if (!compact) const Spacer(),
            const SizedBox(height: 6),
            Row(
              children: [
                StreamBuilder<Set<String>>(
                  stream: HouseholdRepository.instance.savedWorkerIdsStream(),
                  builder: (context, snapshot) {
                    final saved = snapshot.data?.contains(worker.id) ?? false;
                    return IconButton(
                      tooltip: saved ? 'Remove bookmark' : 'Bookmark worker',
                      onPressed: () => HouseholdRepository.instance
                          .toggleSavedWorker(worker, saved: saved),
                      icon: Icon(
                        saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: AppColors.blue,
                      ),
                    );
                  },
                ),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _open(context),
                    child: const Text('View profile'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _open(context),
                    style:
                        FilledButton.styleFrom(backgroundColor: AppColors.blue),
                    child: const Text('Invite'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — MY JOBS (with tabs: Active / Applications / In Progress / Completed / Cancelled)
// ─────────────────────────────────────────────────────────────────────────────

class MyHouseholdJobs extends StatefulWidget {
  const MyHouseholdJobs({super.key, required this.onPost});
  final VoidCallback onPost;
  @override
  State<MyHouseholdJobs> createState() => _MyHouseholdJobsState();
}

class _MyHouseholdJobsState extends State<MyHouseholdJobs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  static const _tabs = [
    (Icons.circle_outlined, 'Active'),
    (Icons.people_alt_rounded, 'Applications'),
    (Icons.play_circle_rounded, 'In Progress'),
    (Icons.check_circle_rounded, 'Completed'),
    (Icons.cancel_rounded, 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  bool _matchesTab(HouseholdJob job, int tabIndex) => switch (tabIndex) {
        0 => job.status == 'open',
        1 => job.status == 'open' && job.applicants > 0,
        2 => job.status == 'inProgress',
        3 => job.status == 'completed',
        4 => job.status == 'cancelled',
        _ => false,
      };

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.mist,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: widget.onPost,
            backgroundColor: AppColors.blue,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Post Job'),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Jobs',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Track applications and job progress.',
                      style: TextStyle(color: AppColors.inkMuted),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // Tab bar
              Container(
                decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: AppColors.line)),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.blue,
                  unselectedLabelColor: AppColors.inkMuted,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  indicatorColor: AppColors.blue,
                  indicatorWeight: 2.5,
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  tabs: _tabs
                      .map((t) => Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(t.$1, size: 15),
                                const SizedBox(width: 5),
                                Text(t.$2),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              // Tab body
              Expanded(
                child: StreamBuilder<List<HouseholdJob>>(
                  stream: HouseholdRepository.instance.myJobsStream(),
                  builder: (context, snapshot) {
                    final allJobs = snapshot.data ?? [];
                    return TabBarView(
                      controller: _tabCtrl,
                      children: List.generate(_tabs.length, (tabIndex) {
                        final filtered = allJobs
                            .where((j) => _matchesTab(j, tabIndex))
                            .toList();
                        if (filtered.isEmpty) {
                          return ListView(
                            padding:
                                const EdgeInsets.fromLTRB(20, 24, 20, 95),
                            children: [
                              _EmptyCard(
                                message: switch (tabIndex) {
                                  0 => 'No active jobs. Post a job to get started!',
                                  1 => 'No applications yet.',
                                  2 => 'No jobs in progress.',
                                  3 => 'No completed jobs yet.',
                                  4 => 'No cancelled jobs.',
                                  _ => 'No jobs.',
                                },
                              ),
                            ],
                          );
                        }
                        return ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(20, 16, 20, 95),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) =>
                              JobCard(job: filtered[i]),
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// JOB CARD
// ─────────────────────────────────────────────────────────────────────────────

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job});
  final HouseholdJob job;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => HouseholdJobDetailsScreen(job: job)),
        ),
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _StatusChip(job.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${job.category}  •  ${job.location}',
                style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.currency_rupee_rounded,
                    size: 16,
                    color: AppColors.green,
                  ),
                  Text(
                    job.budget,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.groups_rounded,
                      size: 16, color: AppColors.inkMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${job.applicants} applicants',
                    style: const TextStyle(
                        color: AppColors.inkMuted, fontSize: 12),
                  ),
                ],
              ),
              if (job.selectedWorkerName?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Assigned: ${job.selectedWorkerName}',
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — POST JOB (8 fields: title, category, description, location,
//                    budget, date, working hours, additional notes)
// ─────────────────────────────────────────────────────────────────────────────

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key, required this.onPosted});
  final VoidCallback onPosted;
  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _description = TextEditingController(),
      _location = TextEditingController(),
      _budget = TextEditingController(),
      _workingHours = TextEditingController(),
      _notes = TextEditingController();
  JobCategory? _category;
  DateTime? _date;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_title, _description, _location, _budget, _workingHours, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.blue,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _post() async {
    if (!_form.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final dateStr = _date != null
          ? '${_date!.day}/${_date!.month}/${_date!.year}'
          : '';
      await HouseholdRepository.instance.postJob(
        title: _title.text.trim(),
        category: JobCategoryMapper.displayName(_category!),
        description: _description.text.trim(),
        location: _location.text.trim(),
        budget: _budget.text.trim(),
        schedule: '',
        date: dateStr,
        workingHours: _workingHours.text.trim(),
        additionalNotes: _notes.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your job is live. Workers can apply now! 🎉'),
            backgroundColor: AppColors.green,
          ),
        );
        // Clear form
        _title.clear();
        _description.clear();
        _location.clear();
        _budget.clear();
        _workingHours.clear();
        _notes.clear();
        setState(() {
          _category = null;
          _date = null;
        });
        widget.onPosted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.mist,
          body: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              children: [
                const Text(
                  'Post a Job',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tell local workers what help you need.',
                  style: TextStyle(color: AppColors.inkMuted),
                ),
                const SizedBox(height: 22),

                // Job title
                _field(_title, 'Job Title', 'e.g. Home Cleaning'),
                // Category picker
                _label('Category'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: JobCategoryMapper.all.map((cat) {
                    final selected = _category == cat;
                    return ChoiceChip(
                      label: Text(JobCategoryMapper.displayName(cat)),
                      selected: selected,
                      onSelected: (val) =>
                          setState(() => _category = val ? cat : null),
                      selectedColor: JobCategoryMapper.backgroundColor(cat),
                      labelStyle: TextStyle(
                        color: selected
                            ? JobCategoryMapper.accentColor(cat)
                            : AppColors.inkMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                      side: BorderSide(
                        color:
                            selected ? Colors.transparent : AppColors.line,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Description
                _field(
                  _description,
                  'Description',
                  'Include the tasks and requirements',
                  lines: 4,
                ),
                // Location
                _field(_location, 'Location', 'Your area or address',
                    prefixIcon: Icons.location_on_outlined),
                // Budget
                _field(_budget, 'Daily Budget', 'e.g. ₹800',
                    prefixIcon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number),

                // Date picker
                _label('Date'),
                const SizedBox(height: 8),
                _PressableScale(
                  onTap: _pickDate,
                  borderRadius: 15,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: _date != null
                              ? AppColors.blue
                              : AppColors.inkMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _date != null
                                ? '${_date!.day}/${_date!.month}/${_date!.year}'
                                : 'Select a date',
                            style: TextStyle(
                              color: _date != null
                                  ? AppColors.navy
                                  : AppColors.inkMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Working hours
                _field(_workingHours, 'Working Hours', 'e.g. 9 AM – 5 PM',
                    prefixIcon: Icons.schedule_rounded),
                // Additional notes
                _field(
                  _notes,
                  'Additional Notes',
                  'Any special instructions (optional)',
                  lines: 3,
                  required: false,
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _saving ? null : _post,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Publish Job',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
        ),
      );

  Widget _field(
    TextEditingController c,
    String label,
    String hint, {
    int lines = 1,
    bool required = true,
    IconData? prefixIcon,
    TextInputType? keyboardType,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: c,
          maxLines: lines,
          keyboardType: keyboardType,
          validator: required
              ? (v) =>
                  v == null || v.trim().isEmpty ? '$label is required' : null
              : null,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: AppColors.inkMuted)
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4 — SAVED WORKERS
// ─────────────────────────────────────────────────────────────────────────────

class SavedWorkersScreen extends StatelessWidget {
  const SavedWorkersScreen({super.key, required this.onBrowse});
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.mist,
          body: StreamBuilder<List<WorkerProfile>>(
            stream: HouseholdRepository.instance.savedWorkersStream(),
            builder: (context, snapshot) {
              final workers = snapshot.data ?? [];
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  const Text(
                    'Saved Workers',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (workers.isEmpty)
                    Column(
                      children: [
                        const _EmptyCard(
                          message:
                              'Save workers you would like to hire again.',
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: onBrowse,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.blue,
                          ),
                          child: const Text('Browse workers'),
                        ),
                      ],
                    ),
                  for (final worker in workers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: WorkerCard(worker: worker),
                    ),
                ],
              );
            },
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 5 — PROFILE
// ─────────────────────────────────────────────────────────────────────────────

class HouseholdProfileScreen extends StatelessWidget {
  const HouseholdProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.mist,
          body: StreamBuilder<HouseholdProfile>(
            stream: HouseholdRepository.instance.profileStream(),
            builder: (context, snapshot) {
              final p = snapshot.data;
              final hasName = p != null && p.name.isNotEmpty;
              final hasAddress = p != null && p.address.isNotEmpty;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.blue.withValues(alpha: .12),
                      backgroundImage: p?.photoUrl == null
                          ? null
                          : NetworkImage(p!.photoUrl!),
                      child: p?.photoUrl == null
                          ? const Icon(
                              Icons.home_rounded,
                              color: AppColors.blue,
                              size: 38,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      hasName ? p.name : 'Household',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      hasAddress
                          ? p.address
                          : 'Add your address in profile settings',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.inkMuted),
                    ),
                  ),
                  const SizedBox(height: 26),
                  _ProfileTile(
                    icon: Icons.location_on_outlined,
                    title: 'Address',
                    subtitle: hasAddress ? p.address : 'Not added yet',
                  ),
                  const _ProfileTile(
                    icon: Icons.verified_user_outlined,
                    title: 'Account status',
                    subtitle: 'Verified household',
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await WorkerAuthService().signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (_) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log out'),
                  ),
                ],
              );
            },
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// WORKER DETAIL
// ─────────────────────────────────────────────────────────────────────────────

class WorkerDetailScreen extends StatelessWidget {
  const WorkerDetailScreen({super.key, required this.worker});
  final WorkerProfile worker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        backgroundColor: AppColors.mist,
        title: const Text('Worker profile'),
      ),
      body: StreamBuilder<Set<String>>(
        stream: HouseholdRepository.instance.savedWorkerIdsStream(),
        builder: (context, saved) {
          final isSaved = saved.data?.contains(worker.id) ?? false;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.mist,
                  backgroundImage: workerAvatarImage(worker.photoUrl),
                  child: worker.photoUrl == null
                      ? Text(
                          worker.name.isNotEmpty
                              ? worker.name[0].toUpperCase()
                              : 'W',
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w800,
                            fontSize: 36,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      worker.name,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (worker.verified)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.verified_rounded,
                            color: AppColors.blue, size: 22),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '★ ${worker.rating.toStringAsFixed(1)} · ${worker.reviews} reviews · ${worker.completedJobs} jobs completed',
                  style: const TextStyle(color: AppColors.inkMuted),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${worker.distance.toStringAsFixed(1)} km away',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _ProfileTile(
                icon: Icons.handyman_outlined,
                title: 'Skills',
                subtitle: worker.skills.isEmpty
                    ? 'Not specified'
                    : worker.skills.join(', '),
              ),
              _ProfileTile(
                icon: Icons.language_rounded,
                title: 'Languages',
                subtitle: worker.languages.isEmpty
                    ? 'Not specified'
                    : worker.languages.join(', '),
              ),
              _ProfileTile(
                icon: Icons.currency_rupee_rounded,
                title: 'Expected daily wage',
                subtitle: '₹${worker.wage}',
              ),
              _ProfileTile(
                icon: Icons.calendar_today_outlined,
                title: 'Availability',
                subtitle: worker.availability.isEmpty
                    ? 'Contact for availability'
                    : worker.availability.join(', '),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => HouseholdRepository.instance
                          .toggleSavedWorker(worker, saved: isSaved),
                      icon: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                      ),
                      label: Text(isSaved ? 'Saved' : 'Save'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _invite(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.blue,
                      ),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Invite'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _invite(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => StreamBuilder<List<HouseholdJob>>(
        stream: HouseholdRepository.instance.myJobsStream(),
        builder: (context, snapshot) {
          final jobs =
              snapshot.data?.where((j) => j.status == 'open').toList() ?? [];
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: jobs.isEmpty
                  ? const Text('Post an open job before inviting a worker.')
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Invite to a job',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        for (final job in jobs)
                          ListTile(
                            title: Text(job.title),
                            subtitle: Text(job.budget),
                            onTap: () async {
                              await HouseholdRepository.instance.inviteWorker(
                                worker: worker,
                                job: job,
                              );
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                          ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JOB DETAILS with FULL LIFECYCLE
// ─────────────────────────────────────────────────────────────────────────────

class HouseholdJobDetailsScreen extends StatelessWidget {
  const HouseholdJobDetailsScreen({super.key, required this.job});
  final HouseholdJob job;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.mist,
        appBar: AppBar(
          backgroundColor: AppColors.mist,
          title: const Text('Job details'),
        ),
        body: StreamBuilder<List<HouseholdJob>>(
          // Live-stream the job so the screen updates when status changes
          stream: HouseholdRepository.instance.myJobsStream(),
          builder: (context, snapshot) {
            final liveJob = snapshot.data
                    ?.cast<HouseholdJob?>()
                    .firstWhere((j) => j?.id == job.id,
                        orElse: () => null) ??
                job;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  liveJob.title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                _StatusChip(liveJob.status),
                const SizedBox(height: 18),
                _ProfileTile(
                  icon: Icons.currency_rupee_rounded,
                  title: 'Budget',
                  subtitle: liveJob.budget,
                ),
                _ProfileTile(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  subtitle: liveJob.location,
                ),
                if (liveJob.date.isNotEmpty)
                  _ProfileTile(
                    icon: Icons.calendar_today_outlined,
                    title: 'Date',
                    subtitle: liveJob.date,
                  ),
                if (liveJob.workingHours.isNotEmpty)
                  _ProfileTile(
                    icon: Icons.schedule_rounded,
                    title: 'Working Hours',
                    subtitle: liveJob.workingHours,
                  ),
                if (liveJob.schedule.isNotEmpty && liveJob.workingHours.isEmpty)
                  _ProfileTile(
                    icon: Icons.schedule_rounded,
                    title: 'Schedule',
                    subtitle: liveJob.schedule,
                  ),
                if (liveJob.description.isNotEmpty)
                  _ProfileTile(
                    icon: Icons.notes_rounded,
                    title: 'Description',
                    subtitle: liveJob.description,
                  ),
                if (liveJob.additionalNotes.isNotEmpty)
                  _ProfileTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Additional Notes',
                    subtitle: liveJob.additionalNotes,
                  ),

                // ── Assigned worker (in progress or completed) ──
                if (liveJob.selectedWorkerName?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.blue.withValues(alpha: .2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_rounded, color: AppColors.blue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Assigned Worker',
                                style: TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                liveJob.selectedWorkerName!,
                                style: const TextStyle(
                                  color: AppColors.blue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Action buttons per status ──
                const SizedBox(height: 20),
                if (liveJob.status == 'open') ...[
                  // Cancel job button
                  OutlinedButton.icon(
                    onPressed: () => _cancelJob(context, liveJob.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                      side: const BorderSide(color: Color(0xFFE53935)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Job'),
                  ),
                ],
                if (liveJob.status == 'inProgress') ...[
                  FilledButton.icon(
                    onPressed: () => _markComplete(context, liveJob.id),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Mark as Complete'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _cancelJob(context, liveJob.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                      side: const BorderSide(color: Color(0xFFE53935)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Job'),
                  ),
                ],
                if (liveJob.status == 'completed') ...[
                  _RatingSection(job: liveJob),
                ],

                // ── Applications ──
                if (liveJob.status == 'open' ||
                    liveJob.status == 'inProgress') ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Applications',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<JobApplication>>(
                    stream: HouseholdRepository.instance
                        .applicationsForJobStream(liveJob.id),
                    builder: (context, snapshot) {
                      final apps = snapshot.data ?? [];
                      if (apps.isEmpty) {
                        return const _EmptyCard(
                          message: 'Applications will appear here instantly.',
                        );
                      }
                      return Column(
                        children: apps
                            .map((app) =>
                                _ApplicationCard(application: app, job: liveJob))
                            .toList(),
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
      );

  void _cancelJob(BuildContext context, String jobId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Job?'),
        content: const Text(
          'Are you sure you want to cancel this job? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No, keep it'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await HouseholdRepository.instance.cancelJob(jobId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job cancelled.')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
  }

  void _markComplete(BuildContext context, String jobId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Complete?'),
        content: const Text(
          'Confirm that this job has been completed successfully.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await HouseholdRepository.instance.markJobComplete(jobId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Job marked as complete! 🎉'),
                    backgroundColor: AppColors.green,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.green),
            child: const Text('Yes, complete'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APPLICATION CARD (Accept / Decline)
// ─────────────────────────────────────────────────────────────────────────────

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application, required this.job});
  final JobApplication application;
  final HouseholdJob job;
  @override
  Widget build(BuildContext context) {
    final worker = application.worker;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.mist,
              child: Text(
                (worker?.name ?? 'W').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    worker?.name ?? 'Applicant',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (worker?.verified == true)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.verified_rounded,
                        color: AppColors.blue, size: 16),
                  ),
              ],
            ),
            subtitle: Text(
              worker != null
                  ? '★ ${worker.rating.toStringAsFixed(1)} · ${worker.completedJobs} jobs · ₹${worker.wage}/day'
                  : application.status,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: _StatusChip(application.status),
          ),
          if (application.status == 'pending' ||
              application.status == 'reviewed')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => HouseholdRepository.instance
                        .updateApplication(application, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                      side: const BorderSide(color: Color(0xFFE53935)),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => HouseholdRepository.instance
                        .updateApplication(application, 'accepted'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          if (application.status == 'accepted' &&
              job.status == 'inProgress')
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => HouseholdRepository.instance.updateApplication(
                  application,
                  'completed',
                ),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Mark completed'),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RATING SECTION (shown on completed jobs)
// ─────────────────────────────────────────────────────────────────────────────

class _RatingSection extends StatefulWidget {
  const _RatingSection({required this.job});
  final HouseholdJob job;
  @override
  State<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<_RatingSection> {
  double _rating = 0;
  final _reviewCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await HouseholdRepository.instance.rateJob(
        jobId: widget.job.id,
        rating: _rating,
        review: _reviewCtrl.text.trim(),
        isHouseholdRating: true,
      );
      if (mounted) {
        setState(() => _submitted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your rating! ⭐'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Already rated — show the existing rating
    if (widget.job.isRatedByHousehold || _submitted) {
      final displayRating = widget.job.householdRating ?? _rating;
      final displayReview = widget.job.householdReview ?? _reviewCtrl.text;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.green.withValues(alpha: .2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star_rounded, color: AppColors.green, size: 20),
                SizedBox(width: 6),
                Text(
                  'Your Rating',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < displayRating.round()
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AppColors.warmGold,
                  size: 28,
                ),
              ),
            ),
            if (displayReview.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"$displayReview"',
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Not yet rated — show the interactive picker
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
          const Text(
            'Rate this job',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'How was your experience with the worker?',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = starIndex.toDouble()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedScale(
                    scale: _rating >= starIndex ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      _rating >= starIndex
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.warmGold,
                      size: 38,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reviewCtrl,
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Submit Rating',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REVIEWS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

/// Completed jobs, shown as the household's review history. Reuses the
/// existing [HouseholdRepository.myJobsStream] — no new repository or state.
class HouseholdReviewsScreen extends StatelessWidget {
  const HouseholdReviewsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.mist,
        appBar: AppBar(
          backgroundColor: AppColors.mist,
          title: const Text('Reviews'),
        ),
        body: StreamBuilder<List<HouseholdJob>>(
          stream: HouseholdRepository.instance.myJobsStream(),
          builder: (context, snapshot) {
            final completed = snapshot.data
                    ?.where((j) => j.status == 'completed')
                    .toList() ??
                [];
            if (completed.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  _EmptyCard(
                    message:
                        'Reviews for completed jobs will appear here once a job is marked complete.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: completed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final job = completed[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (job.isRatedByHousehold) ...[
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (s) => Icon(
                                s < (job.householdRating?.round() ?? 0)
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: AppColors.warmGold,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (job.selectedWorkerName?.isNotEmpty == true)
                              Text(
                                'with ${job.selectedWorkerName}',
                                style: const TextStyle(
                                  color: AppColors.inkMuted,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        if (job.householdReview?.isNotEmpty == true) ...[
                          const SizedBox(height: 6),
                          Text(
                            '"${job.householdReview}"',
                            style: const TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ] else
                        Text(
                          job.selectedWorkerName?.isNotEmpty == true
                              ? 'Completed with ${job.selectedWorkerName}'
                              : 'Completed',
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 12.5,
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
}
