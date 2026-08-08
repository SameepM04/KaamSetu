import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Renders a worker's or household's profile photo exactly the way it was
/// chosen during sign up (see `ProfilePhotoAvatar` + `profile_photo_sheet
/// .dart`): a preset avatar, an uploaded gallery/camera image (stored in
/// Firebase Storage as `profilePhotoURL`), or — if nothing was ever
/// selected — a neutral fallback so the layout never breaks.
///
/// `selectedAvatar` accepts both the Worker preset keys (`'male'` /
/// `'female'`, from `ProfilePhotoAvatar.male` / `.female`) and the
/// Household preset keys (`'maleHousehold'` / `'femaleHousehold'` /
/// `'familyHousehold'`, from the enum values `HouseholdSignUpScreen`'s own
/// avatar picker offers) — mirroring `ProfilePhotoAvatar.name` exactly, so
/// whatever gets written to Firestore's `selectedAvatar` field always
/// renders as the actual image the person picked, not a Worker fallback.
class WorkerProfileAvatar extends StatelessWidget {
  const WorkerProfileAvatar({
    super.key,
    required this.selectedAvatar,
    required this.profilePhotoURL,
    this.size = 46,
  });

  /// Mirrors `ProfilePhotoAvatar.name` — `'male'`, `'female'`,
  /// `'maleHousehold'`, `'femaleHousehold'`, `'familyHousehold'` — or null.
  final String? selectedAvatar;

  /// Uploaded photo URL from Firebase Storage, or null.
  final String? profilePhotoURL;

  final double size;

  static const _assetByKey = <String, String>{
    'male': 'assets/avatars/male_avatar.png',
    'female': 'assets/avatars/female_avatar.png',
    'maleHousehold': 'assets/images/household/male_household.png',
    'femaleHousehold': 'assets/images/household/female_household.png',
    'familyHousehold': 'assets/images/household/family_avatar.png',
  };

  @override
  Widget build(BuildContext context) {
    Widget image;
    final assetPath = _assetByKey[selectedAvatar];
    if (profilePhotoURL != null && profilePhotoURL!.isNotEmpty) {
      image = Image.network(profilePhotoURL!,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackIcon());
    } else if (assetPath != null) {
      image = Image.asset(assetPath, fit: BoxFit.cover);
    } else {
      image = _fallbackIcon();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
              color: Color(0x22102A54), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: ClipOval(child: image),
    );
  }

  Widget _fallbackIcon() {
    return ColoredBox(
      color: AppColors.paleBlue,
      child:
          Icon(Icons.person_rounded, color: AppColors.blue, size: size * .58),
    );
  }
}
