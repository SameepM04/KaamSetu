import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
///   * On success, this signs in with Firebase Anonymous Authentication
///     (see [_ensureFirebaseUid]) so `FirebaseAuth.instance.currentUser` is
///     real and Firestore reads/writes that require `request.auth != null`
///     work. The resulting real uid is then persisted two ways, keyed by
///     that uid rather than a hardcoded fake id:
///       - [SessionService] (SharedPreferences) so `isLoggedIn` survives an
///         app restart.
///       - [LocalWorkerSession] (in-memory) so the existing Worker Home /
///         Worker Profile screens, which read from [LocalWorkerSession],
///         keep working completely unchanged.
class FakeAuthService implements AuthService {
  FakeAuthService({ImageKitService? imageKit, FirebaseAuth? auth})
      : _imageKit = imageKit ?? ImageKitService(),
        _auth = auth ?? FirebaseAuth.instance;

  static const String _fakeVerificationId = 'fake-otp-verification-id';
  final ImageKitService _imageKit;
  final FirebaseAuth _auth;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  /// Ensures there is a signed-in Firebase user and returns its uid.
  ///
  /// The Fake OTP flow never had a real Firebase Auth user before, so
  /// every Firestore rule requiring `request.auth != null` failed and
  /// repositories silently fell back to [DemoRepositoryState]. This signs
  /// in anonymously (once per session) so `FirebaseAuth.instance.currentUser`
  /// is real, while the OTP UI/UX (still gated behind [kFakeOtpCode])
  /// stays completely unchanged.
  Future<String> _ensureFirebaseUid() async {
    var user = _auth.currentUser;
    if (user == null) {
      try {
        // Bounded so a stuck/slow network call can never leave the OTP
        // screen's spinner running forever — it surfaces as a normal
        // exception instead, which the OTP screen's existing try/catch
        // already resets `_verifying` for. This is the fix for the
        // Household-signup regression: nothing here previously reset the
        // spinner if this Future simply never completed.
        final credential = await _auth
            .signInAnonymously()
            .timeout(const Duration(seconds: 12));
        user = credential.user;
      } on FirebaseAuthException catch (e, st) {
        // Log the exact exception rather than swallowing it — per Firebase
        // Console, this is what fires with code `admin-restricted-operation`
        // / `operation-not-allowed` if Anonymous Authentication is disabled
        // for this project (Firebase Console → Authentication → Sign-in
        // method → Anonymous → Enable).
        debugPrint('signInAnonymously() failed: ${e.code} — ${e.message}');
        debugPrint('$st');
        rethrow;
      } on TimeoutException catch (_, st) {
        debugPrint('signInAnonymously() timed out after 12s');
        debugPrint('$st');
        throw FirebaseAuthException(
          code: 'anonymous-sign-in-timeout',
          message:
              'Could not reach Firebase. Please check your connection and try again.',
        );
      }
    }

    if (user == null) {
      // Should not happen — signInAnonymously() either throws or returns a
      // user — but fail loudly rather than silently reverting to a fake id.
      throw FirebaseAuthException(
        code: 'anonymous-sign-in-failed',
        message: 'Could not establish a Firebase session for Fake OTP.',
      );
    }

    // TEMP (for testing only — not shown anywhere in the UI): confirm we
    // now hold a real Firebase UID instead of the old hardcoded fake one.
    debugPrint('Firebase Auth anonymous sign-in successful');
    debugPrint('UID: ${user.uid}');

    return user.uid;
  }

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

    // Fake OTP still stands in for real Phone Auth (Spark plan has no
    // billing, so Phone Auth is unavailable) — but the resulting session
    // now gets a *real* Firebase identity via Anonymous Auth, so Firestore
    // reads/writes (which require `request.auth != null`) work instead of
    // silently falling back to DemoRepositoryState.
    final uid = await _ensureFirebaseUid();

    // Root cause of the household Profile screen showing a hardcoded demo
    // name: this Fake-OTP flow previously never wrote a `households/{uid}`
    // Firestore document at all (only [FirebaseAuthService] — the real
    // Phone Auth path — did), so `HouseholdRepository.profileStream()`
    // always read back an empty doc and fell back to
    // `kDemoHouseholdProfile`. Now that Fake OTP has a real (anonymous)
    // Firebase uid, mirror [FirebaseAuthService.verifyOtpAndCreateWorker]
    // and write the same initial document to the same collection the real
    // flow uses — no new/duplicate collection, no change to the Worker
    // path (worker profile in Fake-OTP mode still reads from
    // [LocalWorkerSession], unchanged).
    if (role == 'household') {
      try {
        // Also bounded (see [_ensureFirebaseUid]) — this write is new as of
        // the Household-profile fix, and an unbounded Firestore call here
        // was the actual Household-signup regression: it's wrapped in
        // try/catch already, but try/catch cannot unblock a Future that
        // never completes (e.g. Firestore rules not yet updated for
        // anonymous auth causing the request to hang rather than reject
        // quickly). The timeout guarantees this always resolves.
        await FirebaseFirestore.instance
            .collection('households')
            .doc(uid)
            .set({
          'uid': uid,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'selectedAvatar': selectedAvatar?.name,
          'role': role,
          'profileCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 12));
      } catch (e, st) {
        // Don't block sign up on a Firestore write failure (e.g. rules not
        // yet updated for anonymous auth, or PERMISSION_DENIED) —
        // LocalWorkerSession/SessionService below still let the household
        // use the app, same as before this Firestore write existed;
        // HouseholdRepository.profileStream()'s existing
        // kDemoHouseholdProfile fallback covers the rest.
        debugPrint('households/$uid initial profile write failed: $e');
        debugPrint('$st');
      }
    }

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
    // Also end the anonymous Firebase session so the next Fake OTP login
    // (possibly a different role/person on the same device) gets a fresh
    // uid instead of reusing this one.
    if (_auth.currentUser != null) {
      await _auth.signOut();
    }
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