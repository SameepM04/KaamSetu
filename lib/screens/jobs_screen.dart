import 'package:flutter/material.dart';

import '../animations/page_transition.dart';
import '../data/job_categories.dart';
import '../data/job_filters.dart';
import '../data/job_previews.dart';
import '../repositories/jobs_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/jobs/application_status_chip.dart';
import 'saved_jobs_screen.dart';
import 'job_details_screen.dart';
import '../widgets/home/category_icon.dart';
import '../widgets/jobs/bookmark_button.dart';
import '../widgets/jobs/job_filter_sheet.dart';
import '../widgets/jobs/job_search_bar.dart';
import '../widgets/jobs/job_sort_sheet.dart';

/// The existing Jobs destination, with an optional category selection, now
/// with search, filtering and sorting layered on top of the same job list
/// and card widgets.
class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key, this.selectedCategory});

  final JobCategory? selectedCategory;

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final _repo = JobsRepository.instance;
  JobCategory? _selectedCategory;
  JobFilters _filters = const JobFilters();
  SortOption _sort = SortOption.relevant;
  String _searchQuery = '';
  late final VoidCallback _jobsListener;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _filters = _filters.copyWith(category: _selectedCategory);
    _jobsListener = () {
      if (mounted) setState(() {});
    };
    _repo.jobs.addListener(_jobsListener);
    _repo.ensureJobsListening();
  }

  @override
  void dispose() {
    _repo.jobs.removeListener(_jobsListener);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant JobsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _setCategory(widget.selectedCategory);
    }
  }

  /// Single place that keeps the category chip row (Task 4's existing
  /// navigation-driven selection) and the filter sheet's own category
  /// picker in sync — both ultimately just call this.
  void _setCategory(JobCategory? category) {
    setState(() {
      _selectedCategory = category;
      _filters = _filters.copyWith(
          category: category, clearCategory: category == null);
    });
  }

  Future<void> _openFilterSheet() async {
    final result = await showJobFilterSheet(context, _filters);
    if (result == null) return;
    setState(() {
      _filters = result;
      _selectedCategory = result.category;
    });
  }

  Future<void> _openSortSheet() async {
    final result = await showJobSortSheet(context, _sort);
    if (result == null) return;
    setState(() => _sort = result);
  }

  @override
  Widget build(BuildContext context) {
    final jobs = JobFilterEngine.apply(
      _repo.jobs.value,
      query: _searchQuery,
      filters: _filters,
      sort: _sort,
    );
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Jobs',
                              style: TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context)
                              .push(premiumPageRoute(const SavedJobsScreen())),
                          icon: const Icon(Icons.bookmark_rounded,
                              color: AppColors.blue),
                          tooltip: 'Saved Jobs',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                        _selectedCategory == null
                            ? 'Find work near you'
                            : '${JobCategoryMapper.displayName(_selectedCategory!)} jobs near you',
                        style: const TextStyle(
                            color: AppColors.inkMuted, fontSize: 13)),
                    const SizedBox(height: 16),
                    JobSearchBar(
                      onChanged: (query) =>
                          setState(() => _searchQuery = query),
                    ),
                    const SizedBox(height: 10),
                    _FilterSortRow(
                      activeFilterCount: _filters.activeCount,
                      sort: _sort,
                      onFilterTap: _openFilterSheet,
                      onSortTap: _openSortSheet,
                    ),
                  ]),
            ),
          ),
          SliverToBoxAdapter(
              child: _CategoryFilters(
                  selected: _selectedCategory, onChanged: _setCategory)),
          if (jobs.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyJobsState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              sliver: SliverList.separated(
                itemCount: jobs.length,
                itemBuilder: (_, index) => JobPreviewCard(
                  job: jobs[index],
                  heroTag: 'jobs-list-${jobs[index].id}',
                ),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// Filter and sort entry points, sitting between the search bar and the
/// category chip row. Wrapped in [Flexible]/[Expanded] throughout so labels
/// never overflow down to 320dp-wide devices.
class _FilterSortRow extends StatelessWidget {
  const _FilterSortRow({
    required this.activeFilterCount,
    required this.sort,
    required this.onFilterTap,
    required this.onSortTap,
  });

  final int activeFilterCount;
  final SortOption sort;
  final VoidCallback onFilterTap;
  final VoidCallback onSortTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PillButton(
            icon: Icons.tune_rounded,
            label: activeFilterCount == 0
                ? 'Filters'
                : 'Filters ($activeFilterCount)',
            highlighted: activeFilterCount > 0,
            onTap: onFilterTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PillButton(
            icon: Icons.swap_vert_rounded,
            label: SortOptionMapper.displayName(sort),
            highlighted: sort != SortOption.relevant,
            onTap: onSortTap,
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.highlighted,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.blue : AppColors.inkMuted;
    return Material(
      color: highlighted ? AppColors.blue.withValues(alpha: .1) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: highlighted ? Colors.transparent : AppColors.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: color,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyJobsState extends StatelessWidget {
  const _EmptyJobsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                color: AppColors.line, size: 46),
            const SizedBox(height: 12),
            const Text('No jobs match your search',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Try adjusting your filters or search terms.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({required this.selected, required this.onChanged});
  final JobCategory? selected;
  final ValueChanged<JobCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: JobCategoryMapper.all.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final category = index == 0 ? null : JobCategoryMapper.all[index - 1];
          final isSelected = category == selected;
          final label = category == null
              ? 'All'
              : JobCategoryMapper.displayName(category);
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onChanged(category),
            selectedColor: category == null
                ? AppColors.blue.withValues(alpha: .14)
                : JobCategoryMapper.backgroundColor(category),
            labelStyle: TextStyle(
                color: isSelected
                    ? (category == null
                        ? AppColors.blue
                        : JobCategoryMapper.accentColor(category))
                    : AppColors.inkMuted,
                fontWeight: FontWeight.w700),
            side: BorderSide(
                color: isSelected ? Colors.transparent : AppColors.line),
          );
        },
      ),
    );
  }
}

/// Shared, responsive card for job feed entries. The category visual always
/// comes from [JobCategoryMapper] through [JobCategoryIcon].
class JobPreviewCard extends StatelessWidget {
  const JobPreviewCard(
      {super.key,
      required this.job,
      this.heroTag,
      this.actionLabel,
      this.onAction,
      this.onTap,
      this.bottomContent});

  final JobPreview job;
  final String? heroTag;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onTap;
  final Widget? bottomContent;

  @override
  Widget build(BuildContext context) {
    final category = job.category;
    final resolvedHeroTag = heroTag ?? 'job-preview-${job.id}';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap ??
            () => Navigator.of(context).push(
                  premiumPageRoute(
                      JobDetailsScreen(job: job, heroTag: resolvedHeroTag)),
                ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Hero(
                tag: resolvedHeroTag,
                child: JobCategoryIcon(
                    category: category,
                    size: 52,
                    borderRadius: 14,
                    iconSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(job.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(job.employer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    _MetaLine(
                        icon: Icons.place_rounded,
                        text: '${job.location} · ${job.distanceKm}'),
                    const SizedBox(height: 3),
                    _MetaLine(
                        icon: Icons.schedule_rounded, text: job.postedAgo),
                  ])),
              BookmarkButton(job: job),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _PayChip(pay: job.pay),
              const Spacer(),
              ValueListenableBuilder<Map<String, ApplicationEntry>>(
                valueListenable: JobsRepository.instance.applications,
                builder: (context, applications, _) {
                  final status = applications[job.id]?.status;
                  return status == null
                      ? const SizedBox.shrink()
                      : ApplicationStatusChip(status: status);
                },
              ),
              if (actionLabel != null) const SizedBox(width: 4),
              if (actionLabel != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ]),
            if (bottomContent != null) ...[
              const SizedBox(height: 8),
              bottomContent!,
            ],
          ]),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: AppColors.inkMuted, size: 13),
        const SizedBox(width: 3),
        Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500))),
      ]);
}

class _PayChip extends StatelessWidget {
  const _PayChip({required this.pay});
  final String pay;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(9)),
        child: Text(pay,
            style: const TextStyle(
                color: AppColors.green,
                fontSize: 11.5,
                fontWeight: FontWeight.w800)),
      );
}
