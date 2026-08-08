import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../widgets/profile_photo_sheet.dart';

/// Wraps Firebase Phone Authentication + Firestore worker-account creation
/// so the UI layer stays free of Firebase plumbing.
class WorkerAuthService {
  WorkerAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  /// Starts real Firebase phone-number verification. [phoneNumber] must be
  /// in full E.164 form, e.g. `+919876543210`.
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
  Future<User> verifyOtpAndCreateWorker({
    required String verificationId,
    required String smsCode,
    required String fullName,
    required String phoneNumber,
    ProfilePhotoAvatar? selectedAvatar,
    File? galleryImage,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-null', message: 'Sign-in did not return a user.');
    }

    String? profilePhotoUrl;
    if (galleryImage != null) {
      profilePhotoUrl = await _uploadProfilePhoto(uid: user.uid, file: galleryImage);
    }

    await _firestore.collection('workers').doc(user.uid).set({
      'uid': user.uid,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'selectedAvatar': selectedAvatar?.name,
      'profilePhotoURL': profilePhotoUrl,
      'role': 'worker',
      'profileCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return user;
  }

  Future<String> _uploadProfilePhoto({required String uid, required File file}) async {
    final ref = _storage.ref('workers/$uid/profile.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
