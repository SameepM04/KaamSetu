import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Stable categories available to worker job listings.
enum JobCategory {
  painting,
  plumbing,
  electrical,
  cleaning,
  gardening,
  carpentry,
  acRepair,
  delivery,
  cook
}

/// The single source of truth for category display, filtering, assets, and colors.
abstract final class JobCategoryMapper {
  static const _details = <JobCategory, _JobCategoryDetails>{
    JobCategory.painting: _JobCategoryDetails('Painting', 'painting',
        'assets/icons/jobs/painting.png', Color(0xFFE1EBFF), AppColors.blue),
    JobCategory.plumbing: _JobCategoryDetails('Plumbing', 'plumbing',
        'assets/icons/jobs/plumbing.png', Color(0xFFDDF3E4), AppColors.green),
    JobCategory.electrical: _JobCategoryDetails(
        'Electrical',
        'electrical',
        'assets/icons/jobs/electrical.png',
        Color(0xFFFFF0D6),
        AppColors.orange),
    JobCategory.cleaning: _JobCategoryDetails('Cleaning', 'cleaning',
        'assets/icons/jobs/cleaning.png', Color(0xFFEAE3FA), Color(0xFF7C5CE0)),
    JobCategory.gardening: _JobCategoryDetails(
        'Gardening',
        'gardening',
        'assets/icons/jobs/gardening.png',
        Color(0xFFDCEEDD),
        Color(0xFF2E7D46)),
    JobCategory.carpentry: _JobCategoryDetails(
        'Carpentry',
        'carpentry',
        'assets/icons/jobs/carpentry.png',
        Color(0xFFF3E6DA),
        Color(0xFF8B5E3C)),
    JobCategory.acRepair: _JobCategoryDetails(
        'AC Repair',
        'ac_repair',
        'assets/icons/jobs/ac_repair.png',
        Color(0xFFDCF3F5),
        Color(0xFF17A2B8)),
    JobCategory.delivery: _JobCategoryDetails('Delivery', 'delivery',
        'assets/icons/jobs/delivery.png', Color(0xFFE3E6FA), Color(0xFF4B5FD1)),
    JobCategory.cook: _JobCategoryDetails('Cook', 'cook',
        'assets/icons/jobs/cook.png', Color(0xFFFFE9D6), AppColors.orange),
  };

  static const _titleAliases = <String, JobCategory>{
    'house painting': JobCategory.painting,
    'painting': JobCategory.painting,
    'bathroom plumbing': JobCategory.plumbing,
    'plumbing': JobCategory.plumbing,
    'tube light installation': JobCategory.electrical,
    'switch board repair': JobCategory.electrical,
    'electrical': JobCategory.electrical,
    'home cleaning': JobCategory.cleaning,
    'sofa cleaning': JobCategory.cleaning,
    'cleaning': JobCategory.cleaning,
    'garden maintenance': JobCategory.gardening,
    'gardening': JobCategory.gardening,
    'carpentry': JobCategory.carpentry,
    'ac repair': JobCategory.acRepair,
    'delivery': JobCategory.delivery,
    'cook': JobCategory.cook,
  };

  static List<JobCategory> get all => List.unmodifiable(JobCategory.values);
  static JobCategory? fromJobTitle(String title) =>
      _titleAliases[title.trim().toLowerCase()];
  static JobCategory? fromStorage(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    for (final category in JobCategory.values) {
      if (normalized == category.name.toLowerCase() ||
          normalized == filterValue(category) ||
          normalized == displayName(category).toLowerCase()) {
        return category;
      }
    }
    return fromJobTitle(value);
  }
  static String displayName(JobCategory category) =>
      _details[category]!.displayName;
  static String filterValue(JobCategory category) =>
      _details[category]!.filterValue;
  static String assetPath(JobCategory category) =>
      _details[category]!.assetPath;
  static Color backgroundColor(JobCategory category) =>
      _details[category]!.backgroundColor;
  static Color accentColor(JobCategory category) =>
      _details[category]!.accentColor;
}

class _JobCategoryDetails {
  const _JobCategoryDetails(this.displayName, this.filterValue, this.assetPath,
      this.backgroundColor, this.accentColor);
  final String displayName;
  final String filterValue;
  final String assetPath;
  final Color backgroundColor;
  final Color accentColor;
}
