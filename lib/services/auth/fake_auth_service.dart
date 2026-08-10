import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';

import '../../config/dev_config.dart';
import '../../widgets/profile_photo_sheet.dart';
import '../imagekit_service.dart';
import '../local_worker_session.dart';
import '../session_service.dart';
import 'auth_service.dart';

/// Fully offline stand-in for Firebase Phone Authentication, used while the
/// Firebase project is on the Spark plan (no billing = no real Phone Auth,
/// which fails with `BILLING_NOT_ENABLED`).
///
/// Behaviour (see `lib/config/dev_config.dart` for how this is switched on):
///   * [sendOtp] never calls Firebase. It immediately reports success via
///     `onCodeSent` with a placeholder verification id, exactly as if an
///     SMS had just been sent.
///   * [verifyOtpAndCreateWorker] accepts only [kFakeOtpCode] ("123456").
///     Any other value throws a [FirebaseAuthException] with code
///     `invalid-verification-code`, which the existing OTP screen already
///     knows how to display as "Incorrect OTP. Please try again."
///   * On success, no Firebase Auth user exists (there's nothing to sign
///     in to), so the entered profile fields are persisted two ways:
///       - [SessionService] (SharedPreferences) so `isLoggedIn` survives an
///         app restart.
///       - [LocalWorkerSession] (in-memory) so the existing Worker Home /
///         Worker Profile screens — which already fall back to
///         [LocalWorkerSession] whenever there's no signed-in Firebase
///         user — keep working completely unchanged.
class FakeAuthService implements AuthService {
  FakeAuthService({ImageKitService? imageKit})
      : _imageKit = imageKit ?? ImageKitService();

  static const String _fakeVerificationId = 'fake-otp-verification-id';
  final ImageKitService _imageKit;

  @override
  String? get currentUserId => null;

  @override
  Stream<Map<String, dynamic>> workerProfileStream(String uid) =>
      Stream.value(LocalWorkerSession.data);

  @override
  Stream<List<Map<String, dynamic>>> workerReviewsStream(String uid) =>
      Stream.value(const []);

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException error) onFailed,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
  }) async {
    // No Firebase call, no real SMS — just report success right away so
    // the UI navigates to the OTP screen exactly as it would after a real
    // code was sent.
    onCodeSent(_fakeVerificationId);
  }

  @override
  Future<User?> verifyOtpAndCreateWorker({
    required String verificationId,
    required String smsCode,
    required String fullName,
    required String phoneNumber,
    ProfilePhotoAvatar? selectedAvatar,
    Uint8List? galleryImageBytes,
    String role = 'worker',
  }) async {
    if (smsCode != kFakeOtpCode) {
      throw FirebaseAuthException(
        code: 'invalid-verification-code',
        message: 'Incorrect OTP. Please try again.',
      );
    }

    const uid = 'fake-worker-kaamsetu';
    final profile = <String, dynamic>{
      'uid': uid,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'selectedAvatar': selectedAvatar?.name,
      'role': role,
      'profileCompleted': false,
    };

    // Persist for the current run (Home/Profile read this).
    LocalWorkerSession.save(profile);

    // Persist across app restarts (Splash reads this to skip Login).
    await SessionService.saveSession(
      uid: uid,
      fullName: fullName,
      phoneNumber: phoneNumber,
      avatar: selectedAvatar?.name,
      role: role,
    );

    // No real FirebaseAuth `User` exists in the Fake OTP flow; a `null`
    // return (with no exception thrown) is treated by the OTP screen as a
    // successful verification, same as the previous debug-mode behaviour.
    return null;
  }

  /// Saves ALL editable worker-profile fields to [LocalWorkerSession]
  /// in a single call — mirroring the production [FirebaseAuthService]
  /// which does a single Firestore write.
  @override
  Future<void> saveCompleteProfile({
    required String fullName,
    required String address,
    String? selectedAvatar,
    Uint8List? newPhotoBytes,
    required List<String> skills,
    required String experience,
    required List<String> preferredCategories,
    required List<String> availability,
    required double workingRadius,
    required int expectedDailyWage,
    required List<String> languages,
  }) async {
    final fields = <String, dynamic>{
      'fullName': fullName,
      'address': address,
      'skills': skills,
      'experienceYears': experience,
      'preferredCategories': preferredCategories,
      'availability': availability,
      'workingRadiusKm': workingRadius,
      'expectedDailyWage': expectedDailyWage,
      'languagesKnown': languages,
    };

    if (selectedAvatar != null) {
      fields['selectedAvatar'] = selectedAvatar;
      fields['profilePhotoURL'] = null;
    }

    String? uploadedPhotoUrl;
    if (newPhotoBytes != null) {
      // Uploads to ImageKit (not Firebase Storage — see
      // `imagekit_service.dart` for why). This throws ImageKitException on
      // failure; the caller (EditProfileScreen) already has a catch-all
      // around this call that surfaces a real error and keeps the
      // previously-saved photo, so we deliberately do NOT swallow it here.
      uploadedPhotoUrl = await _imageKit.uploadProfilePhoto(
        bytes: newPhotoBytes,
        fileName: '${LocalWorkerSession.userId}.jpg',
      );
      fields['profilePhotoURL'] = uploadedPhotoUrl;
      fields['selectedAvatar'] = null;
    }

    // Save in-memory for the current session.
    LocalWorkerSession.save(fields);

    // Also persist ALL fields to SharedPreferences so edits survive an app restart.
    await SessionService.saveSession(
      uid: LocalWorkerSession.userId,
      fullName: fullName,
      phoneNumber: LocalWorkerSession.data['phoneNumber'] as String? ?? '',
      avatar: selectedAvatar ?? LocalWorkerSession.data['selectedAvatar'] as String?,
      role: LocalWorkerSession.data['role'] as String? ?? 'worker',
      address: address,
      skills: skills,
      experience: experience,
      preferredCategories: preferredCategories,
      availability: availability,
      workingRadius: workingRadius,
      expectedDailyWage: expectedDailyWage,
      languages: languages,
      profilePhotoURL:
          uploadedPhotoUrl ?? LocalWorkerSession.data['profilePhotoURL'] as String?,
    );
  }

  @override
  Future<void> signOut() async {
    LocalWorkerSession.clear();
    await SessionService.clear();
  }

  /// Fake OTP / dev mode has no Firebase Storage available (Spark plan),
  /// so this uploads to ImageKit instead (see `imagekit_service.dart`) and
  /// persists the resulting URL to the in-memory session + SharedPreferences
  /// (there is no `workers/{uid}` Firestore document to write to in fake
  /// mode). On failure this rethrows [ImageKitException] — the caller
  /// (`ProfileAvatarEditor`) already surfaces upload failures as a
  /// friendly snackbar and keeps the previous avatar in place, never a
  /// fabricated local path. Once the project is switched to real Firebase
  /// (`kUseFakeOtp = false`), [FirebaseAuthService.updateProfilePhoto]
  /// takes over unchanged.
  @override
  Future<void> updateProfilePhoto(Uint8List bytes) async {
    final url = await _imageKit.uploadProfilePhoto(
      bytes: bytes,
      fileName: '${LocalWorkerSession.userId}.jpg',
    );

    LocalWorkerSession.save({'profilePhotoURL': url, 'selectedAvatar': null});

    await SessionService.saveSession(
      uid: LocalWorkerSession.userId,
      fullName: LocalWorkerSession.data['fullName'] as String? ?? '',
      phoneNumber: LocalWorkerSession.data['phoneNumber'] as String? ?? '',
      avatar: null,
      role: LocalWorkerSession.data['role'] as String? ?? 'worker',
      profilePhotoURL: url,
    );
  }
}