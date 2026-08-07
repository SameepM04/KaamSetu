import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../../config/dev_config.dart';
import '../../widgets/profile_photo_sheet.dart';
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
  static const String _fakeVerificationId = 'fake-otp-verification-id';

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
    File? galleryImage,
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
    File? newPhotoFile,
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
    // Note: newPhotoFile is ignored in fake mode (no Storage available).

    LocalWorkerSession.save(fields);
  }

  @override
  Future<void> signOut() async {
    LocalWorkerSession.clear();
    await SessionService.clear();
  }
}
