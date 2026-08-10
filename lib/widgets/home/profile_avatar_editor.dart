import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../profile_photo_sheet.dart';
import 'photo_viewer_screen.dart';
import 'worker_profile_avatar.dart';

/// Wraps [WorkerProfileAvatar] with a subtle premium ring and a small
/// pencil/edit button, and wires up two SEPARATE interactions:
///
///   * Tapping the photo itself opens a full-screen [PhotoViewerScreen] —
///     but ONLY once a real photo exists (a newly-picked image, or a
///     persisted `profilePhotoURL`). It never opens the male/female preset
///     picker.
///   * Tapping the pencil button opens the existing photo picker (see
///     `profile_photo_sheet.dart`) to change the photo.
///
/// Used identically by both `WorkerProfileScreen` and
/// `HouseholdProfileScreen` — the only thing that differs between the two
/// is which repository/service [onPhotoPicked] saves to.
///
/// Images are handled as [Uint8List] bytes end to end (never `dart:io
/// File`/`FileImage`), so preview + upload both work unchanged on Flutter
/// Web as well as Android/iOS.
class ProfileAvatarEditor extends StatefulWidget {
  const ProfileAvatarEditor({
    super.key,
    required this.selectedAvatar,
    required this.profilePhotoURL,
    required this.onPhotoPicked,
    this.size = 72,
  });

  /// Mirrors `ProfilePhotoAvatar.name`, or null — see [WorkerProfileAvatar].
  final String? selectedAvatar;

  /// Currently persisted photo URL, or null.
  final String? profilePhotoURL;

  /// Called with the newly-picked image's bytes. The caller is responsible
  /// for uploading them to the existing storage/profile architecture; any
  /// error it throws is caught here and shown as a snackbar, leaving the
  /// previous avatar in place.
  final Future<void> Function(Uint8List bytes) onPhotoPicked;

  final double size;

  @override
  State<ProfileAvatarEditor> createState() => _ProfileAvatarEditorState();
}

class _ProfileAvatarEditorState extends State<ProfileAvatarEditor> {
  Uint8List? _pendingBytes;
  bool _busy = false;

  @override
  void didUpdateWidget(covariant ProfileAvatarEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Once the persisted URL catches up with what we optimistically
    // showed, drop the local override so we go back to the normal
    // (cacheable, cross-screen) network image path.
    if (_pendingBytes != null &&
        widget.profilePhotoURL != oldWidget.profilePhotoURL &&
        widget.profilePhotoURL != null &&
        widget.profilePhotoURL!.isNotEmpty) {
      _pendingBytes = null;
    }
  }

  bool get _hasRealPhoto =>
      _pendingBytes != null ||
      (widget.profilePhotoURL != null && widget.profilePhotoURL!.isNotEmpty);

  Future<void> _handlePencilTap() async {
    if (_busy) return; // no simultaneous uploads from repeated taps
    // Pencil = "change my photo", never the male/female avatar picker.
    final selection =
        await showProfilePhotoSheet(context, allowAvatarSelection: false);
    if (selection == null || selection.imageBytes == null) return;

    final bytes = selection.imageBytes!;
    setState(() {
      _pendingBytes = bytes;
      _busy = true;
    });
    try {
      await widget.onPhotoPicked(bytes);
    } catch (_) {
      if (!mounted) return;
      // Upload failed — keep the previous image, don't leave a broken one.
      setState(() => _pendingBytes = null);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.navy,
          content: Text("Couldn't update your photo. Please try again.",
              style: TextStyle(fontWeight: FontWeight.w600)),
        ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _handlePhotoTap() {
    if (!_hasRealPhoto) return; // nothing real to view yet
    PhotoViewerScreen.show(
      context,
      imageBytes: _pendingBytes,
      imageUrl: _pendingBytes == null ? widget.profilePhotoURL : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    const ringWidth = 2.0;
    const ringGap = 3.0;
    final outer = widget.size + 2 * (ringWidth + ringGap);

    return SizedBox(
      width: outer + 6,
      height: outer + 6,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: _handlePhotoTap,
            child: Container(
              width: outer,
              height: outer,
              padding: const EdgeInsets.all(ringGap),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.blue.withValues(alpha: .55),
                    width: ringWidth),
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x22102A54),
                      blurRadius: 14,
                      offset: Offset(0, 6)),
                ],
              ),
              child: _pendingBytes != null
                  ? ClipOval(
                      child: Image.memory(_pendingBytes!,
                          width: widget.size,
                          height: widget.size,
                          fit: BoxFit.cover),
                    )
                  : WorkerProfileAvatar(
                      selectedAvatar: widget.selectedAvatar,
                      profilePhotoURL: widget.profilePhotoURL,
                      size: widget.size,
                    ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            // Scales with the avatar so the same widget stays proportionate
            // both as the small (~40-46px) Home app-bar avatar and the
            // larger (~72px) Profile-screen avatar, while staying inside
            // the spec's 24-30px suggested pencil-button range.
            child: _PencilButton(
              busy: _busy,
              onTap: _handlePencilTap,
              diameter: (widget.size * .42).clamp(24.0, 30.0),
            ),
          ),
        ],
      ),
    );
  }
}

class _PencilButton extends StatefulWidget {
  const _PencilButton({
    required this.busy,
    required this.onTap,
    this.diameter = 32,
  });
  final bool busy;
  final VoidCallback onTap;
  final double diameter;

  @override
  State<_PencilButton> createState() => _PencilButtonState();
}

class _PencilButtonState extends State<_PencilButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? .92 : 1,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: widget.diameter,
          height: widget.diameter,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line, width: 1.2),
            boxShadow: [
              BoxShadow(
                  color: const Color(0x22102A54)
                      .withValues(alpha: _pressed ? .12 : .2),
                  blurRadius: 8,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: widget.busy
              ? Padding(
                  padding: EdgeInsets.all(widget.diameter * .25),
                  child: const CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.blue),
                )
              : Icon(Icons.edit_rounded,
                  color: AppColors.blue, size: widget.diameter * .47),
        ),
      ),
    );
  }
}
