import 'job_categories.dart';

/// Employment arrangement for a [JobPreview]. Backs the "Job Type" filter.
enum JobType { fullTime, partTime, temporary }

/// Display helpers for [JobType], mirroring the pattern used by
/// [JobCategoryMapper] so every screen reads labels from one place.
abstract final class JobTypeMapper {
  static const _labels = <JobType, String>{
    JobType.fullTime: 'Full Time',
    JobType.partTime: 'Part Time',
    JobType.temporary: 'Temporary',
  };

  static List<JobType> get all => List.unmodifiable(JobType.values);
  static String displayName(JobType type) => _labels[type]!;
}

/// Experience band required for a [JobPreview]. Backs the "Experience" filter.
enum ExperienceLevel { entry, intermediate, experienced }

abstract final class ExperienceLevelMapper {
  static const _labels = <ExperienceLevel, String>{
    ExperienceLevel.entry: 'Entry Level',
    ExperienceLevel.intermediate: 'Intermediate',
    ExperienceLevel.experienced: 'Experienced',
  };

  static List<ExperienceLevel> get all =>
      List.unmodifiable(ExperienceLevel.values);
  static String displayName(ExperienceLevel level) => _labels[level]!;
}

/// Temporary presentation data for Phase 1. This is not a Firestore model.
class JobPreview {
  const JobPreview({
    required this.id,
    required this.title,
    required this.employer,
    required this.location,
    required this.distanceKm,
    required this.postedAgo,
    required this.pay,
    this.skills = const [],
    this.jobType = JobType.fullTime,
    this.experienceLevel = ExperienceLevel.entry,
    this.verifiedEmployer = false,
    this.description,
    this.workingHours,
    this.duration,
    this.status = 'open',
    this.categoryOverride,
    this.postedAt,
    this.latitude,
    this.longitude,
  });

  /// Stable, explicit identifier — never derived from title/employer/
  /// location. Used as the Firestore document id for saved jobs, and is
  /// the single id this app uses for Wishlist, Applications, Job Details,
  /// category filtering, navigation, and any future backend integration.
  final String id;
  final String title;
  final String employer;
  final String location;
  final String distanceKm;
  final String postedAgo;
  final String pay;
  final List<String> skills;
  final JobType jobType;
  final ExperienceLevel experienceLevel;
  final bool verifiedEmployer;
  final String? description;
  final String? workingHours;
  final String? duration;
  final String status;
  final JobCategory? categoryOverride;
  final DateTime? postedAt;

  /// Destination coordinates for "open in Google Maps" directions (see
  /// MapNavigationService). Optional — only present where known, never
  /// invented. When null, the location text still displays as-is but the
  /// row does not offer map navigation.
  final double? latitude;
  final double? longitude;

  /// True when this job has a real destination to hand to Google Maps.
  bool get hasNavigableLocation => latitude != null && longitude != null;

  JobCategory get category =>
      categoryOverride ?? JobCategoryMapper.fromJobTitle(title) ?? JobCategory.cleaning;

  /// Distance parsed out of [distanceKm] (e.g. "1.2 km" -> 1.2). Kept as a
  /// derived getter rather than a second stored field so there is only one
  /// source of truth for distance.
  double get distanceValue =>
      double.tryParse(RegExp(r'[\d.]+').firstMatch(distanceKm)?.group(0) ??
          '') ??
      0;

  /// Daily pay parsed out of [pay] (e.g. "₹1,500 / day" -> 1500). Derived the
  /// same way as [distanceValue].
  int get salaryValue => int.tryParse(
          (RegExp(r'[\d,]+').firstMatch(pay)?.group(0) ?? '0')
              .replaceAll(',', '')) ??
      0;

  /// Lower is more recent. Derived from [postedAgo] so recency has a single
  /// source of truth instead of a duplicated timestamp field.
  int get recencyRank {
    final text = postedAgo.trim().toLowerCase();
    if (text == 'today') return 0;
    if (text == 'yesterday') return 24;
    final hours = RegExp(r'(\d+)\s*hour').firstMatch(text);
    if (hours != null) return int.parse(hours.group(1)!);
    final days = RegExp(r'(\d+)\s*day').firstMatch(text);
    if (days != null) return int.parse(days.group(1)!) * 24;
    return 1 << 30;
  }

  /// True when [postedAgo] reads as posted within the current day.
  bool get isPostedToday =>
      postedAgo.trim().toLowerCase() == 'today' || recencyRank < 24;
}

const kJobPreviews = <JobPreview>[
  JobPreview(
      id: 'job_house_painting',
      title: 'House Painting',
      employer: 'Sharma Family',
      location: 'Kothrud, Pune',
      // Approximate neighborhood-center coordinates (demo data only).
      latitude: 18.5074,
      longitude: 73.8077,
      distanceKm: '1.2 km',
      postedAgo: '2 hours ago',
      pay: '₹1,500 / day',
      skills: ['Painting', 'Wall Prep', 'Spray Finish'],
      jobType: JobType.fullTime,
      experienceLevel: ExperienceLevel.intermediate,
      verifiedEmployer: true),
  JobPreview(
      id: 'job_bathroom_plumbing',
      title: 'Bathroom Plumbing',
      employer: 'Patil Family',
      location: 'Erandwane, Pune',
      // Approximate neighborhood-center coordinates (demo data only).
      latitude: 18.5089,
      longitude: 73.8237,
      distanceKm: '1.8 km',
      postedAgo: '3 hours ago',
      pay: '₹1,200 / day',
      skills: ['Plumbing', 'Pipe Fitting', 'Leak Repair'],
      jobType: JobType.temporary,
      experienceLevel: ExperienceLevel.experienced,
      verifiedEmployer: true),
  JobPreview(
      id: 'job_tube_light_installation',
      title: 'Tube Light Installation',
      employer: 'Joshi Residence',
      location: 'Karve Nagar, Pune',
      // Approximate neighborhood-center coordinates (demo data only).
      latitude: 18.489,
      longitude: 73.808,
      distanceKm: '2.1 km',
      postedAgo: '5 hours ago',
      pay: '₹800 / day',
      skills: ['Electrical', 'Wiring'],
      jobType: JobType.partTime,
      experienceLevel: ExperienceLevel.entry,
      verifiedEmployer: false),
  JobPreview(
      id: 'job_home_cleaning',
      title: 'Home Cleaning',
      employer: 'Kulkarni Household',
      location: 'Baner, Pune',
      // Approximate neighborhood-center coordinates (demo data only).
      latitude: 18.559,
      longitude: 73.7868,
      distanceKm: '1.4 km',
      postedAgo: 'Today',
      pay: '₹900 / day',
      skills: ['Cleaning', 'Housekeeping'],
      jobType: JobType.partTime,
      experienceLevel: ExperienceLevel.entry,
      verifiedEmployer: true),
  JobPreview(
      id: 'job_sofa_cleaning',
      title: 'Sofa Cleaning',
      employer: 'Kulkarni Household',
      location: 'Aundh, Pune',
      // Approximate neighborhood-center coordinates (demo data only).
      latitude: 18.5643,
      longitude: 73.8077,
      distanceKm: '2.3 km',
      postedAgo: 'Today',
      pay: '₹1,100 / day',
      skills: ['Cleaning', 'Upholstery Care'],
      jobType: JobType.temporary,
      experienceLevel: ExperienceLevel.intermediate,
      verifiedEmployer: true),
  JobPreview(
      id: 'job_switch_board_repair',
      title: 'Switch Board Repair',
      employer: 'Joshi Residence',
      location: 'Pashan, Pune',
      // Approximate neighborhood-center coordinates (demo data only).
      latitude: 18.537,
      longitude: 73.797,
      distanceKm: '3.2 km',
      postedAgo: 'Today',
      pay: '₹700 / day',
      skills: ['Electrical', 'Wiring', 'Safety Checks'],
      jobType: JobType.temporary,
      experienceLevel: ExperienceLevel.entry,
      verifiedEmployer: false),
  JobPreview(
      id: 'job_garden_maintenance',
      title: 'Garden Maintenance',
      employer: 'Rao Family',
      location: 'Wakad, Pune',
      // Approximate neighborhood-center coordinates (demo data only).
      latitude: 18.598,
      longitude: 73.761,
      distanceKm: '2.8 km',
      postedAgo: 'Yesterday',
      pay: '₹950 / day',
      skills: ['Gardening', 'Landscaping'],
      jobType: JobType.partTime,
      experienceLevel: ExperienceLevel.entry,
      verifiedEmployer: false),
  JobPreview(
      id: 'job_carpentry',
      title: 'Carpentry',
      employer: 'Iyer Household',
      location: 'Deccan, Pune',
      // Approximate neighborhood-center coordinates (demo data only).
      latitude: 18.5158,
      longitude: 73.8412,
      distanceKm: '3.7 km',
      postedAgo: 'Yesterday',
      pay: '₹1,300 / day',
      skills: ['Carpentry', 'Furniture Repair'],
      jobType: JobType.fullTime,
      experienceLevel: ExperienceLevel.experienced,
      verifiedEmployer: true),
  JobPreview(
      id: 'job_ac_repair',
      title: 'AC Repair',
      employer: 'Gupta Family',
      location: 'Shivajinagar, Pune',
      // Approximate neighborhood-center coordinates (demo data only).
      latitude: 18.5308,
      longitude: 73.8475,
      distanceKm: '4.1 km',
      postedAgo: 'Yesterday',
      pay: '₹1,000 / day',
      skills: ['AC Repair', 'Refrigerant Handling'],
      jobType: JobType.fullTime,
      experienceLevel: ExperienceLevel.intermediate,
      verifiedEmployer: true),
  JobPreview(
      id: 'job_delivery',
      title: 'Delivery',
      employer: 'Khan Residence',
      location: 'Viman Nagar, Pune',
      // Approximate neighborhood-center coordinates (demo data only).
      latitude: 18.5679,
      longitude: 73.9143,
      distanceKm: '4.8 km',
      postedAgo: 'Yesterday',
      pay: '₹850 / day',
      skills: ['Delivery', 'Two Wheeler'],
      jobType: JobType.partTime,
      experienceLevel: ExperienceLevel.entry,
      verifiedEmployer: false),
  JobPreview(
      id: 'job_cook',
      title: 'Cook',
      employer: 'Mehta Family',
      location: 'Koregaon Park, Pune',
      // Approximate neighborhood-center coordinates (demo data only).
      latitude: 18.5362,
      longitude: 73.8938,
      distanceKm: '5.2 km',
      postedAgo: '2 days ago',
      pay: '₹1,400 / day',
      skills: ['Cooking', 'Meal Prep'],
      jobType: JobType.fullTime,
      experienceLevel: ExperienceLevel.experienced,
      verifiedEmployer: true),
];
