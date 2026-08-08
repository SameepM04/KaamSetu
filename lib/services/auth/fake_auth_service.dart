import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  FakeAuthService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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

    // Role-scoped fake uid + collection — mirrors FirebaseAuthService's
    // `role == 'household' ? 'households' : 'workers'` split. Previously
    // this was a single hardcoded 'fake-worker-kaamsetu' id shared by both
    // roles, so a household sign-up and a worker sign-up would collide in
    // [LocalWorkerSession]/[SessionService], and — because nothing was ever
    // written to Firestore here — HouseholdRepository.profileStream()
    // always found an empty `households/{uid}` doc and fell back to the
    // demo household, no matter what name was actually entered at sign up.
    final uid =
        role == 'household' ? 'fake-household-kaamsetu' : 'fake-worker-kaamsetu';
    final collection = role == 'household' ? 'households' : 'workers';
    final profile = <String, dynamic>{
      'uid': uid,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'selectedAvatar': selectedAvatar?.name,
      'role': role,
      'profileCompleted': false,
    };

    // Persist for the current run (Home/Profile read this immediately —
    // don't wait on Firestore below, so sign-in is never blocked by it).
    LocalWorkerSession.save(profile);

    // Persist across app restarts (Splash reads this to skip Login).
    await SessionService.saveSession(
      uid: uid,
      fullName: fullName,
      phoneNumber: phoneNumber,
      avatar: selectedAvatar?.name,
      role: role,
    );

    // Best-effort mirror to Firestore so HouseholdRepository.profileStream()
    // / WorkerAuthService.workerProfileStream() find a real document instead
    // of falling back to demo data. Deliberately NOT awaited and wrapped in
    // its own timeout + catch: Fake OTP mode exists specifically to work
    // fully offline (see class doc — Spark plan has no billing, and network
    // conditions during dev are unreliable), so sign-in must never hang or
    // fail just because this write is slow, blocked by security rules, or
    // unreachable. LocalWorkerSession/SessionService above are the source
    // of truth the UI can always rely on; this is a nice-to-have on top.
    unawaited(
      _firestore.collection(collection).doc(uid).set({
        ...profile,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 8)).catchError(
        (Object error, StackTrace _) {
          // ignore: avoid_print
          print('FakeAuthService: Firestore mirror write skipped — $error');
        },
      ),
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
