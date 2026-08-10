/// Profile completion calculation — the single source of truth used by
/// both the Worker Profile screen (progress bar) and the job-application
/// gate (see `JobsRepository.applyForJob`). Extracted out of
/// `worker_profile_screen.dart` so neither call site has to duplicate it.
///
/// 10 equally-weighted fields. Phone number does NOT count.
/// When all 10 are filled, completion = 100%.
class ProfileCompletion {
  static const _weightedKeys = [
    'profilePhotoURL', // OR selectedAvatar is also ok
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

  static double compute(Map<String, dynamic> data) {
    if (data.isEmpty) return 0;
    var filled = 0;
    for (final key in _weightedKeys) {
      // profilePhotoURL: also check selectedAvatar as an alternative
      if (key == 'profilePhotoURL') {
        final hasPhoto = _isFilled(data['profilePhotoURL']);
        final hasAvatar = _isFilled(data['selectedAvatar']);
        if (hasPhoto || hasAvatar) filled++;
        continue;
      }
      if (_isFilled(data[key])) filled++;
    }
    return filled / _weightedKeys.length;
  }

  static bool _isFilled(dynamic value) => switch (value) {
        null => false,
        String s => s.trim().isNotEmpty,
        Iterable i => i.isNotEmpty,
        num n => n > 0,
        _ => true,
      };
}
