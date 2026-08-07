import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/profile_photo_sheet.dart';

/// Common contract for KaamSetu's phone-auth + worker-account flow.
///
/// [WorkerAuthService] (the facade every screen already talks to) delegates
/// every call to exactly one implementation of this interface, chosen once
/// via the `kUseFakeOtp` switch in `lib/config/dev_config.dart`:
///
///   * [FirebaseAuthService] — the real, unchanged Firebase Phone
///     Authentication + Firestore/Storage implementation.
///   * [FakeAuthService] — a fully offline stand-in used while Firebase
///     Phone Auth is unavailable on the Spark billing plan.
///
/// Keeping both behind this one interface is what lets the UI layer
/// (screens) stay completely unaware of which implementation is active.
abstract class AuthService {
  /// Currently signed-in user's uid, or `null` if nobody is signed in.
  String? get currentUserId;

  /// Live worker-profile document for [uid].
  Stream<Map<String, dynamic>> workerProfileStream(String uid);

  /// Live stream of reviews for [uid] from `workers/{uid}/reviews`.
  Stream<List<Map<String, dynamic>>> workerReviewsStream(String uid);

  /// Starts phone-number verification. On success, [onCodeSent] fires with
  /// a verification id (real, for Firebase; a placeholder, for Fake OTP).
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException error) onFailed,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
  });

  /// Verifies the entered OTP and, on success, creates the account
  /// (Firebase Auth user + Firestore doc for the real flow; a persisted
  /// local session for the Fake OTP flow).
  Future<User?> verifyOtpAndCreateWorker({
    required String verificationId,
    required String smsCode,
    required String fullName,
    required String phoneNumber,
    ProfilePhotoAvatar? selectedAvatar,
    File? galleryImage,
    String role = 'worker',
  });

  /// Saves ALL editable worker-profile fields in a single repository call.
  ///
  /// The UI layer calls this ONCE when the worker presses "Save Profile".
  /// Internally this results in exactly ONE Firestore document update so
  /// no partial saves or race conditions occur between the basic-info and
  /// professional-info subsections.
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
  });

  /// Signs the current user out and clears whatever session state this
  /// implementation keeps, returning the app to a logged-out state.
  Future<void> signOut();
}
