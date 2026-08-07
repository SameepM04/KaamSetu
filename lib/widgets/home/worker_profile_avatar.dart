import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Renders a worker's profile photo exactly the way it was chosen during
/// sign up (see `ProfilePhotoAvatar` + `profile_photo_sheet.dart`):
/// male/female preset avatar, an uploaded gallery/camera image (stored in
/// Firebase Storage as `profilePhotoURL`), or — if nothing was ever
/// selected — a neutral fallback so the layout never breaks.
class WorkerProfileAvatar extends StatelessWidget {
  const WorkerProfileAvatar({
    super.key,
    required this.selectedAvatar,
    required this.profilePhotoURL,
    this.size = 46,
  });

  /// `'male'` / `'female'` (mirrors `ProfilePhotoAvatar.name`), or null.
  final String? selectedAvatar;

  /// Uploaded photo URL from Firebase Storage, or null.
  final String? profilePhotoURL;

  final double size;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (profilePhotoURL != null && profilePhotoURL!.isNotEmpty) {
      image = Image.network(profilePhotoURL!,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackIcon());
    } else if (selectedAvatar == 'male') {
      image = Image.asset('assets/avatars/male_avatar.png', fit: BoxFit.cover);
    } else if (selectedAvatar == 'female') {
      image =
          Image.asset('assets/avatars/female_avatar.png', fit: BoxFit.cover);
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
