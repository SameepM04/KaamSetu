import 'package:flutter/material.dart';

import '../../animations/page_transition.dart';
import 'edit_profile_screen.dart';

/// Backward-compatibility redirect for [ProfessionalInfoScreen].
///
/// Phase 4 merged all editing (Basic Information + Professional Information)
/// into a single [EditProfileScreen]. Any existing push to
/// [ProfessionalInfoScreen] is now silently forwarded to [EditProfileScreen]
/// so the app continues to compile and no navigation entry-point is broken.
///
/// The incoming [data] map is used to prefill [EditProfileScreen] in exactly
/// the same way as the Profile header card does, ensuring the worker always
/// sees their existing data rather than an empty form.
class ProfessionalInfoScreen extends StatelessWidget {
  const ProfessionalInfoScreen({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    // Immediately replace this route with the unified Edit Profile screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(premiumPageRoute(
        EditProfileScreen(
          initialFullName: (data['fullName'] as String?)?.trim() ?? '',
          initialAddress: (data['address'] as String?)?.trim() ?? '',
          initialPhoneNumber:
              (data['phoneNumber'] as String?)?.trim() ?? '',
          initialSelectedAvatar: data['selectedAvatar'] as String?,
          initialProfilePhotoURL: data['profilePhotoURL'] as String?,
          initialSkills:
              (data['skills'] as List?)?.cast<String>() ?? const [],
          initialExperience: data['experienceYears'] as String?,
          initialCategories:
              (data['preferredCategories'] as List?)?.cast<String>() ??
                  const [],
          initialAvailability:
              (data['availability'] as List?)?.cast<String>() ?? const [],
          initialWorkingRadius:
              ((data['workingRadiusKm'] as num?)?.toDouble() ?? 5)
                  .clamp(5.0, 50.0),
          initialDailyWage:
              (data['expectedDailyWage'] as num?)?.toInt(),
          initialLanguages:
              (data['languagesKnown'] as List?)?.cast<String>() ?? const [],
        ),
      ));
    });

    // Momentary transparent scaffold while the redirect fires — avoids any
    // flash of placeholder content.
    return const Scaffold(backgroundColor: Colors.transparent);
  }
}
