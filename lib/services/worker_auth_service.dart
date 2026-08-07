import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../config/dev_config.dart';
import '../widgets/profile_photo_sheet.dart';
import 'auth/auth_service.dart';
import 'auth/fake_auth_service.dart';
import 'auth/firebase_auth_service.dart';

/// Facade every screen talks to for phone-auth + worker-account creation.
/// The UI layer never sees [FirebaseAuthService] or [FakeAuthService]
/// directly — this class alone decides which one runs, based on the single
/// `kUseFakeOtp` switch in `lib/config/dev_config.dart`.
///
/// DEVELOPMENT MODE — FAKE OTP
/// ----------------------------
/// Firebase Phone Authentication is currently unavailable on this
/// project's Spark billing plan (`BILLING_NOT_ENABLED`). While
/// `kUseFakeOtp == true`, every method below delegates to [FakeAuthService]:
/// no Firebase Phone Auth call is ever made, only the code `123456` is
/// accepted as a valid OTP, and the resulting session is persisted locally
/// (see [SessionService]) so it survives an app restart.
///
/// To switch back to real Firebase Phone Authentication once the project
/// is on the Blaze plan, change exactly one line in
/// `lib/config/dev_config.dart`:
///
///   const bool kUseFakeOtp = false;
///
/// No other code changes are required — this facade, and every screen that
/// uses it, stays exactly the same.
class WorkerAuthService implements AuthService {
  WorkerAuthService({
    FirebaseAuth? auth,
    AuthService? impl,
  }) : _impl = impl ??
            (kUseFakeOtp
                ? FakeAuthService()
                : FirebaseAuthService(auth: auth));

  final AuthService _impl;

  @override
  String? get currentUserId => _impl.currentUserId;

  @override
  Stream<Map<String, dynamic>> workerProfileStream(String uid) =>
      _impl.workerProfileStream(uid);

  @override
  Stream<List<Map<String, dynamic>>> workerReviewsStream(String uid) =>
      _impl.workerReviewsStream(uid);

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException error) onFailed,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
  }) {
    return _impl.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onFailed: onFailed,
      onAutoVerified: onAutoVerified,
      onCodeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
    );
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
  }) {
    return _impl.verifyOtpAndCreateWorker(
      verificationId: verificationId,
      smsCode: smsCode,
      fullName: fullName,
      phoneNumber: phoneNumber,
      selectedAvatar: selectedAvatar,
      galleryImage: galleryImage,
      role: role,
    );
  }

  /// Saves ALL editable worker-profile fields in a single repository call.
  ///
  /// The UI layer (EditProfileScreen) calls this ONCE when the worker
  /// presses "Save Profile". Internally this produces exactly ONE Firestore
  /// document update so no partial saves or race conditions occur between
  /// the basic-info and professional-info subsections.
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
  }) {
    return _impl.saveCompleteProfile(
      fullName: fullName,
      address: address,
      selectedAvatar: selectedAvatar,
      newPhotoFile: newPhotoFile,
      skills: skills,
      experience: experience,
      preferredCategories: preferredCategories,
      availability: availability,
      workingRadius: workingRadius,
      expectedDailyWage: expectedDailyWage,
      languages: languages,
    );
  }

  /// Signs the current user out (Fake OTP: clears the local persisted
  /// session; Firebase: `FirebaseAuth.instance.signOut()`) and returns the
  /// app to a logged-out state. Used by the Logout action.
  @override
  Future<void> signOut() => _impl.signOut();
}
