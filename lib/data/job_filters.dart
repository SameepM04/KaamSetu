import 'job_categories.dart';
import 'job_previews.dart';

/// Sort strategies available from the Jobs screen sort sheet.
enum SortOption {
  relevant,
  newest,
  nearest,
  highestSalary,
  lowestSalary,
  alphabetical,
}

abstract final class SortOptionMapper {
  static const _labels = <SortOption, String>{
    SortOption.relevant: 'Most Relevant',
    SortOption.newest: 'Newest',
    SortOption.nearest: 'Nearest',
    SortOption.highestSalary: 'Highest Salary',
    SortOption.lowestSalary: 'Lowest Salary',
    SortOption.alphabetical: 'Alphabetical',
  };

  static List<SortOption> get all => List.unmodifiable(SortOption.values);
  static String displayName(SortOption option) => _labels[option]!;
}

/// Bounds used by the salary and distance sliders in the filter sheet.
abstract final class JobFilterBounds {
  static const minSalary = 0;
  static const maxSalary = 3000;
  static const minDistance = 0.0;
  static const maxDistance = 10.0;
}

/// Immutable snapshot of every active filter, independent of search text and
/// sort order so each concern can change without touching the others.
class JobFilters {
  const JobFilters({
    this.category,
    this.salaryRange =
        const (JobFilterBounds.minSalary, JobFilterBounds.maxSalary),
    this.maxDistance = JobFilterBounds.maxDistance,
    this.experienceLevels = const <ExperienceLevel>{},
    this.jobTypes = const <JobType>{},
    this.todayOnly = false,
    this.nearbyOnly = false,
    this.verifiedOnly = false,
    this.availability = const <String>{},
    this.minRating = 0,
  });

  final JobCategory? category;
  final (int, int) salaryRange;
  final double maxDistance;
  final Set<ExperienceLevel> experienceLevels;
  final Set<JobType> jobTypes;
  final bool todayOnly;
  final bool nearbyOnly;
  final bool verifiedOnly;

  /// Worker-search-only filters (Household "Recommended Workers"). Unused
  /// — and never set — by the Jobs screen's own use of this same class.
  final Set<String> availability;
  final double minRating;

  /// True when at least one filter differs from the neutral default —
  /// drives the "active filters" badge on the Jobs screen filter button.
  bool get isActive =>
      category != null ||
      salaryRange.$1 != JobFilterBounds.minSalary ||
      salaryRange.$2 != JobFilterBounds.maxSalary ||
      maxDistance != JobFilterBounds.maxDistance ||
      experienceLevels.isNotEmpty ||
      jobTypes.isNotEmpty ||
      todayOnly ||
      nearbyOnly ||
      verifiedOnly ||
      availability.isNotEmpty ||
      minRating > 0;

  int get activeCount => [
        category != null,
        salaryRange.$1 != JobFilterBounds.minSalary ||
            salaryRange.$2 != JobFilterBounds.maxSalary,
        maxDistance != JobFilterBounds.maxDistance,
        experienceLevels.isNotEmpty,
        jobTypes.isNotEmpty,
        todayOnly,
        nearbyOnly,
        verifiedOnly,
        availability.isNotEmpty,
        minRating > 0,
      ].where((flag) => flag).length;

  JobFilters copyWith({
    JobCategory? category,
    bool clearCategory = false,
    (int, int)? salaryRange,
    double? maxDistance,
    Set<ExperienceLevel>? experienceLevels,
    Set<JobType>? jobTypes,
    bool? todayOnly,
    bool? nearbyOnly,
    bool? verifiedOnly,
    Set<String>? availability,
    double? minRating,
  }) {
    return JobFilters(
      category: clearCategory ? null : (category ?? this.category),
      salaryRange: salaryRange ?? this.salaryRange,
      maxDistance: maxDistance ?? this.maxDistance,
      experienceLevels: experienceLevels ?? this.experienceLevels,
      jobTypes: jobTypes ?? this.jobTypes,
      todayOnly: todayOnly ?? this.todayOnly,
      nearbyOnly: nearbyOnly ?? this.nearbyOnly,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      availability: availability ?? this.availability,
      minRating: minRating ?? this.minRating,
    );
  }
}

/// Fixed availability options offered in the Household worker-filter sheet
/// — mirrors the values `WorkerProfile.availability` is actually populated
/// with (see `demo_workers.dart` and the Worker Professional Info form).
const kWorkerAvailabilityOptions = <String>[
  'Full Week',
  'Weekdays',
  'Weekends',
  'Morning Shift',
  'Evening Shift',
];

/// The single place that turns (jobs, search text, filters, sort) into the
/// list the Jobs screen renders. Kept as pure static logic — no widget or
/// state concerns — so nothing else needs to reimplement matching, filtering
/// or ordering.
abstract final class JobFilterEngine {
  static List<JobPreview> apply(
    List<JobPreview> jobs, {
    String query = '',
    JobFilters filters = const JobFilters(),
    SortOption sort = SortOption.relevant,
  }) {
    final trimmedQuery = query.trim().toLowerCase();

    final results = jobs.where((job) {
      if (filters.category != null && job.category != filters.category) {
        return false;
      }
      if (job.salaryValue < filters.salaryRange.$1 ||
          job.salaryValue > filters.salaryRange.$2) {
        return false;
      }
      if (job.distanceValue > filters.maxDistance) return false;
      if (filters.experienceLevels.isNotEmpty &&
          !filters.experienceLevels.contains(job.experienceLevel)) {
        return false;
      }
      if (filters.jobTypes.isNotEmpty &&
          !filters.jobTypes.contains(job.jobType)) {
        return false;
      }
      if (filters.todayOnly && !job.isPostedToday) return false;
      if (filters.nearbyOnly && job.distanceValue > 3) return false;
      if (filters.verifiedOnly && !job.verifiedEmployer) return false;
      if (trimmedQuery.isNotEmpty && _relevance(job, trimmedQuery) == 0) {
        return false;
      }
      return true;
    }).toList();

    results.sort((a, b) => _compare(a, b, sort, trimmedQuery));
    return results;
  }

  static int _compare(
      JobPreview a, JobPreview b, SortOption sort, String query) {
    switch (sort) {
      case SortOption.newest:
        return a.recencyRank.compareTo(b.recencyRank);
      case SortOption.nearest:
        return a.distanceValue.compareTo(b.distanceValue);
      case SortOption.highestSalary:
        return b.salaryValue.compareTo(a.salaryValue);
      case SortOption.lowestSalary:
        return a.salaryValue.compareTo(b.salaryValue);
      case SortOption.alphabetical:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case SortOption.relevant:
        if (query.isEmpty) return 0;
        return _relevance(b, query).compareTo(_relevance(a, query));
    }
  }

  /// Weighted match score across title, employer, category, location and
  /// skills. Zero means no match at all.
  static int _relevance(JobPreview job, String query) {
    var score = 0;
    if (job.title.toLowerCase().contains(query)) score += 3;
    if (job.employer.toLowerCase().contains(query)) score += 2;
    if (JobCategoryMapper.displayName(job.category)
        .toLowerCase()
        .contains(query)) {
      score += 2;
    }
    if (job.location.toLowerCase().contains(query)) score += 1;
    if (job.skills.any((skill) => skill.toLowerCase().contains(query))) {
      score += 2;
    }
    return score;
  }
}
