import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';

enum ProfilePhotoAvatar {
  male,
  female,
  // Premium Household avatars — used only by HouseholdSignUpScreen's own
  // avatar picker. Additive values; the Worker flow above is untouched.
  maleHousehold,
  femaleHousehold,
  familyHousehold,
}

/// Result of the profile-photo bottom sheet: either a preset avatar or a
/// picked image. Both null means the user cancelled / kept default.
///
/// [imageBytes] is used for BOTH preview and upload, on every platform —
/// `XFile.readAsBytes()` works identically on Web, Android and iOS, unlike
/// `dart:io.File`, which does not exist on Flutter Web and is what
/// previously caused a red assertion screen when running in the browser.
/// [imagePath] is only meaningful on non-web platforms (a real filesystem
/// path) and is kept solely so mobile-only tools such as `image_cropper`
/// can still be used there; it is always null on Web.
class ProfilePhotoSelection {
  const ProfilePhotoSelection({this.avatar, this.imageBytes, this.imagePath});

  final ProfilePhotoAvatar? avatar;
  final Uint8List? imageBytes;
  final String? imagePath;
}

/// Shows the photo-selection sheet.
///
/// [allowAvatarSelection] controls whether the Male/Female preset-avatar
/// options are offered alongside Gallery/Camera. Sign-up flows
/// (`WorkerSignUpScreen`, `HouseholdSignUpScreen`) want the full picker —
/// choosing an avatar is a legitimate first-time choice there. The Home
/// and Profile pencil/camera buttons (`ProfileAvatarEditor`,
/// `EditProfileScreen`) are specifically "change my *photo*" affordances,
/// so they pass `false` and only ever see Gallery + Take Photo — avatar
/// selection stays a separate, explicit feature (see KaamSetu profile-photo
/// spec, "DO NOT break existing avatar system").
Future<ProfilePhotoSelection?> showProfilePhotoSheet(
  BuildContext context, {
  bool allowAvatarSelection = true,
}) {
  return showModalBottomSheet<ProfilePhotoSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _ProfilePhotoSheet(allowAvatarSelection: allowAvatarSelection),
  );
}

class _ProfilePhotoSheet extends StatefulWidget {
  const _ProfilePhotoSheet({this.allowAvatarSelection = true});

  final bool allowAvatarSelection;

  @override
  State<_ProfilePhotoSheet> createState() => _ProfilePhotoSheetState();
}

class _ProfilePhotoSheetState extends State<_ProfilePhotoSheet> {
  final _picker = ImagePicker();
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    setState(() => _busy = true);
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      if (file != null && mounted) {
        // readAsBytes() is Web-safe (reads the picked Blob) as well as
        // native-safe (reads the picked file) — this is what makes the
        // rest of the photo pipeline (preview, crop, upload) work on both.
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        Navigator.of(context).pop(ProfilePhotoSelection(
          imageBytes: bytes,
          imagePath: kIsWeb ? null : file.path,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
                color: Color(0x22102A54), blurRadius: 30, offset: Offset(0, 12))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Choose Profile Photo',
                  style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.allowAvatarSelection) ...[
                  Expanded(
                    child: _AvatarOption(
                      label: 'Male Avatar',
                      assetPath: 'assets/avatars/male_avatar.png',
                      onTap: () => Navigator.of(context).pop(
                          const ProfilePhotoSelection(
                              avatar: ProfilePhotoAvatar.male)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AvatarOption(
                      label: 'Female Avatar',
                      assetPath: 'assets/avatars/female_avatar.png',
                      onTap: () => Navigator.of(context).pop(
                          const ProfilePhotoSelection(
                              avatar: ProfilePhotoAvatar.female)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: _ActionOption(
                    icon: Icons.image_rounded,
                    label: 'Choose from\nGallery',
                    busy: _busy,
                    onTap: _busy ? null : () => _pick(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(children: const [
              Expanded(child: Divider(color: AppColors.line)),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child:
                      Text('or', style: TextStyle(color: AppColors.inkMuted))),
              Expanded(child: Divider(color: AppColors.line)),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _pick(ImageSource.camera),
                icon:
                    const Icon(Icons.camera_alt_rounded, color: AppColors.blue),
                label: const Text('Take Photo',
                    style: TextStyle(
                        color: AppColors.navy, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.line, width: 1.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarOption extends StatelessWidget {
  const _AvatarOption(
      {required this.label, required this.assetPath, required this.onTap});

  final String label;
  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            ClipOval(
              child: Image.asset(assetPath,
                  width: 56, height: 56, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ActionOption extends StatelessWidget {
  const _ActionOption(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.busy = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(18),
          color: AppColors.paleBlue.withValues(alpha: .5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: busy
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(icon, color: AppColors.blue, size: 30),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
