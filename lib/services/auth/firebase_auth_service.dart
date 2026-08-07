import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../widgets/profile_photo_sheet.dart';
import 'auth_service.dart';

/// Real Firebase Phone Authentication + Firestore worker-account creation.
///
/// This is the original, production implementation — unchanged in
/// behaviour from before the Fake OTP dev switch was introduced. It is
/// only used when `kUseFakeOtp == false` (see
/// `lib/config/dev_config.dart`), via the [WorkerAuthService] facade.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Stream<Map<String, dynamic>> workerProfileStream(String uid) => _firestore
      .collection('workers')
      .doc(uid)
      .snapshots()
      .map((snapshot) => snapshot.data() ?? const <String, dynamic>{});

  /// Streams the reviews subcollection for [uid], ordered newest-first.
  @override
  Stream<List<Map<String, dynamic>>> workerReviewsStream(String uid) {
    return _firestore
        .collection('workers')
        .doc(uid)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Starts phone-number verification. [phoneNumber] must be in full E.164
  /// form, e.g. `+919876543210`.
  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException error) onFailed,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailed,
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout ?? (_) {},
    );
  }

  /// Verifies the entered OTP and, on success, creates the Firebase Auth
  /// user + `workers/{uid}` Firestore document.
  ///
  /// [role] selects which Firestore collection the account document is
  /// written to (`workers/{uid}` for `'worker'`, `households/{uid}` for
  /// `'household'`) and is also stored as the `role` field. This is the
  /// only thing that differs between Worker and Household sign up — the
  /// Firebase Phone Auth verification itself is identical, so no separate
  /// implementation is created for Household.
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
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw FirebaseAuthException(
          code: 'user-null', message: 'Sign-in did not return a user.');
    }

    final collection = role == 'household' ? 'households' : 'workers';

    String? profilePhotoUrl;
    if (galleryImage != null) {
      profilePhotoUrl = await _uploadProfilePhoto(
          uid: user.uid, file: galleryImage, collection: collection);
    }

    await _firestore.collection(collection).doc(user.uid).set({
      'uid': user.uid,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'selectedAvatar': selectedAvatar?.name,
      'profilePhotoURL': profilePhotoUrl,
      'role': role,
      'profileCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return user;
  }

  Future<String> _uploadProfilePhoto(
      {required String uid,
      required File file,
      String collection = 'workers'}) async {
    final ref = _storage.ref('$collection/$uid/profile.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  /// Saves ALL editable worker-profile fields in a SINGLE Firestore write.
  ///
  /// Called once when the worker presses "Save Profile" in [EditProfileScreen].
  /// Uses `SetOptions(merge: true)` so unrelated fields (uid, phoneNumber,
  /// role, stats, createdAt, etc.) are never overwritten.
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
    final uid = currentUserId;
    if (uid == null) return;

    // Upload photo first if a new file was picked (the URL is needed for
    // the document write below). Avatar strings don't need uploading.
    String? profilePhotoUrl;
    if (newPhotoFile != null) {
      profilePhotoUrl = await _uploadProfilePhoto(uid: uid, file: newPhotoFile);
    }

    // ONE Firestore document update — all fields merged in a single call.
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
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (selectedAvatar != null) {
      fields['selectedAvatar'] = selectedAvatar;
      // When switching to an avatar, clear any previously-uploaded photo URL
      // so the avatar is displayed, not the old photo.
      fields['profilePhotoURL'] = null;
    }

    if (profilePhotoUrl != null) {
      fields['profilePhotoURL'] = profilePhotoUrl;
      // When uploading a real photo, clear the preset avatar selection.
      fields['selectedAvatar'] = null;
    }

    await _firestore
        .collection('workers')
        .doc(uid)
        .set(fields, SetOptions(merge: true));
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
