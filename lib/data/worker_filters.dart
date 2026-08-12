import 'job_categories.dart';
import '../repositories/household_repository.dart';

/// Bounds used by the distance slider in the Household worker-filter sheet.
abstract final class WorkerFilterBounds {
  static const minDistance = 0.0;
  static const maxDistance = 20.0;
}

/// Minimum-experience tiers offered by the Household filter.
///
/// Backed by the *real* `experienceYears` field a worker fills in on
/// [ProfessionalInfoScreen]/`EditProfileScreen` (stored in Firestore as one
/// of: 'Fresher', 'Less than 1 year', '1–3 Years', '3–5 Years',
/// '5–10 Years', '10+ Years' — see `_experienceOptions` in
/// `edit_profile_screen.dart`). [ExperienceTierMapper.rankOf] turns those
/// buckets into a comparable integer so "3+ years" can match "3–5 Years",
/// "5–10 Years" and "10+ Years" alike.
enum ExperienceTier { any, oneYear, threeYears, fiveYears, tenYears }

abstract final class ExperienceTierMapper {
  static const _labels = <ExperienceTier, String>{
    ExperienceTier.any: 'Any',
    ExperienceTier.oneYear: '1+ Years',
    ExperienceTier.threeYears: '3+ Years',
    ExperienceTier.fiveYears: '5+ Years',
    ExperienceTier.tenYears: '10+ Years',
  };

  static const _minRank = <ExperienceTier, int>{
    ExperienceTier.any: -1,
    ExperienceTier.oneYear: 1,
    ExperienceTier.threeYears: 3,
    ExperienceTier.fiveYears: 5,
    ExperienceTier.tenYears: 10,
  };

  /// Rank assigned to each stored `experienceYears` bucket. Unknown/blank
  /// values return `null` — such a worker cannot be verified against an
  /// experience filter, so they're excluded rather than guessed at.
  static int? rankOf(String? storedExperience) {
    switch (storedExperience?.trim()) {
      case 'Fresher':
      case 'Less than 1 year':
        return 0;
      case '1–3 Years':
      case '1-3 Years':
        return 1;
      case '3–5 Years':
      case '3-5 Years':
        return 3;
      case '5–10 Years':
      case '5-10 Years':
        return 5;
      case '10+ Years':
        return 10;
      default:
        return null;
    }
  }

  static List<ExperienceTier> get all =>
      List.unmodifiable(ExperienceTier.values);
  static String displayName(ExperienceTier tier) => _labels[tier]!;
  static int minRank(ExperienceTier tier) => _minRank[tier]!;
}

/// Minimum-rating tiers offered by the Household filter — mirrors the
/// actual granularity of `WorkerProfile.rating`.
const kWorkerRatingOptions = <double>[0, 3.0, 3.5, 4.0, 4.5];

/// Immutable snapshot of every active Household → Worker filter. Entirely
/// independent from the Worker-side [JobFilters] used by the Jobs screen —
/// this class only ever describes *workers*, never job postings.
class WorkerFilters {
  const WorkerFilters({
    this.categories = const <JobCategory>{},
    this.experience = ExperienceTier.any,
    this.minRating = 0,
    this.maxDistance = WorkerFilterBounds.maxDistance,
    this.availability = const <String>{},
    this.verifiedOnly = false,
  });

  /// Work type / skill — OR logic between multiple selections.
  final Set<JobCategory> categories;
  final ExperienceTier experience;
  final double minRating;
  final double maxDistance;
  final Set<String> availability;
  final bool verifiedOnly;

  bool get isActive =>
      categories.isNotEmpty ||
      experience != ExperienceTier.any ||
      minRating > 0 ||
      maxDistance != WorkerFilterBounds.maxDistance ||
      availability.isNotEmpty ||
      verifiedOnly;

  int get activeCount => [
        categories.isNotEmpty,
        experience != ExperienceTier.any,
        minRating > 0,
        maxDistance != WorkerFilterBounds.maxDistance,
        availability.isNotEmpty,
        verifiedOnly,
      ].where((flag) => flag).length;

  WorkerFilters copyWith({
    Set<JobCategory>? categories,
    ExperienceTier? experience,
    double? minRating,
    double? maxDistance,
    Set<String>? availability,
    bool? verifiedOnly,
  }) {
    return WorkerFilters(
      categories: categories ?? this.categories,
      experience: experience ?? this.experience,
      minRating: minRating ?? this.minRating,
      maxDistance: maxDistance ?? this.maxDistance,
      availability: availability ?? this.availability,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    );
  }
}

/// The single place that turns (workers, search text, filters) into the
/// list a Household screen renders. Pure static logic — no widget or state
/// concerns — shared by the dashboard search and [RecommendedWorkersScreen]
/// so both filter identically.
abstract final class WorkerFilterEngine {
  static List<WorkerProfile> apply(
    List<WorkerProfile> workers, {
    String query = '',
    WorkerFilters filters = const WorkerFilters(),
  }) {
    final trimmedQuery = query.trim().toLowerCase();
    return workers.where((worker) => matches(worker, trimmedQuery, filters))
        .toList();
  }

  static bool matches(
      WorkerProfile worker, String trimmedQuery, WorkerFilters filters) {
    if (trimmedQuery.isNotEmpty) {
      final haystack =
          '${worker.name} ${worker.skills.join(' ')} ${worker.categories.join(' ')}'
              .toLowerCase();
      if (!haystack.contains(trimmedQuery)) return false;
    }

    // Work type / skill — OR within the selection.
    if (filters.categories.isNotEmpty) {
      final selected = filters.categories
          .map((c) => JobCategoryMapper.filterValue(c).toLowerCase())
          .toSet();
      final matchesAny =
          worker.categories.any((c) => selected.contains(c.toLowerCase()));
      if (!matchesAny) return false;
    }

    // Experience.
    if (filters.experience != ExperienceTier.any) {
      final rank = ExperienceTierMapper.rankOf(worker.experienceYears);
      if (rank == null) return false;
      if (rank < ExperienceTierMapper.minRank(filters.experience)) {
        return false;
      }
    }

    // Rating.
    if (filters.minRating > 0 && worker.rating < filters.minRating) {
      return false;
    }

    // Distance — only meaningful because WorkerProfile.distance is a real
    // computed km value (see HouseholdRepository), not a guess from text.
    if (filters.maxDistance < WorkerFilterBounds.maxDistance &&
        worker.distance > filters.maxDistance) {
      return false;
    }

    // Availability.
    if (filters.availability.isNotEmpty &&
        !worker.availability.any((a) => filters.availability.contains(a))) {
      return false;
    }

    // Verified only.
    if (filters.verifiedOnly && !worker.verified) return false;

    return true;
  }
}
