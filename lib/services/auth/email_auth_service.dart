import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Result of a successful Email/Password signup or login.
class EmailAuthResult {
  const EmailAuthResult({required this.uid, required this.isNewAccount});

  /// The canonical Firebase Auth uid — always
  /// `FirebaseAuth.instance.currentUser!.uid`, never a synthesized id.
  final String uid;

  /// Whether this call created a brand-new Firebase Auth account (signup)
  /// as opposed to reauthenticating an existing one (login).
  final bool isNewAccount;
}

/// User-friendly error surfaced by [EmailAuthService] instead of a raw
/// [FirebaseAuthException].
class EmailAuthError implements Exception {
  const EmailAuthError(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Firebase Email + Password authentication — the new, separate
/// authentication path introduced in the Phase 2 auth migration.
///
/// This is intentionally **independent** of [WorkerAuthService] / the
/// `kUseFakeOtp` switch (`lib/config/dev_config.dart`): Email/Password
/// accounts always talk to the real `FirebaseAuth.instance` and always
/// resolve their uid as `FirebaseAuth.instance.currentUser!.uid`. They
/// never fall through to [LocalWorkerSession]'s `fake-worker-kaamsetu`
/// id or any other synthesized identity — that OTP-era fallback logic is
/// left completely untouched (see `fake_auth_service.dart`,
/// `jobs_repository.dart`, `household_repository.dart`) so the existing
/// Phone-OTP flow keeps working exactly as before while this new path is
/// developed alongside it.
///
/// Firestore schema is unchanged: profiles are still written to
/// `workers/{uid}` / `households/{uid}` using the same field names
/// [FirebaseAuthService.verifyOtpAndCreateWorker] already uses, keyed by
/// the Firebase Auth uid.
class EmailAuthService {
  EmailAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// The canonical uid for the signed-in Email/Password user, or `null` if
  /// nobody is signed in. Always `FirebaseAuth.instance.currentUser?.uid`
  /// — never a phone number, an email address, or a synthesized id.
  String? get currentUserId => _auth.currentUser?.uid;

  /// Creates a brand-new Firebase Email/Password account and writes its
  /// initial profile document (`workers/{uid}` or `households/{uid}`,
  /// matching the existing Firestore schema and the fields
  /// [FirebaseAuthService.verifyOtpAndCreateWorker] already writes for the
  /// Phone-OTP path).
  ///
  /// Deliberately NOT built on top of `verifyOtpAndCreateWorker()` — that
  /// method is scoped to the OTP verification step and shouldn't grow an
  /// unrelated email/password branch. This is its own, clearly separated
  /// method.
  ///
  /// [role] must be `'worker'` or `'household'`.
  Future<EmailAuthResult> createAccountWithEmail({
    required String email,
    required String password,
    required String role,
    String fullName = '',
    String phoneNumber = '',
    String address = '',
  }) async {
    assert(role == 'worker' || role == 'household');
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const EmailAuthError(
          'Something went wrong creating your account. Please try again.',
        );
      }

      // Canonical UID — never LocalWorkerSession, never a custom id.
      final uid = user.uid;
      final collection = role == 'household' ? 'households' : 'workers';

      // Explicit profile-document creation. Fake-OTP/dev mode never wrote
      // workers/{uid} the way the real Phone-OTP path does (see
      // fake_auth_service.dart), so this is written unconditionally here
      // rather than assumed to already happen somewhere else.
      await _firestore.collection(collection).doc(uid).set({
        'uid': uid,
        'email': email.trim(),
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        if (role == 'household') 'address': address,
        'role': role,
        'profileCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return EmailAuthResult(uid: uid, isNewAccount: true);
    } on FirebaseAuthException catch (e) {
      throw EmailAuthError(_mapSignupError(e), code: e.code);
    }
  }

  /// Signs an existing Email/Password account back in. Kept entirely
  /// separate from [createAccountWithEmail] so signup/login can never be
  /// conflated into one ambiguous method (and so their error handling can
  /// stay separate — see [_mapSignupError] vs [_mapLoginError]).
  Future<EmailAuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const EmailAuthError(
          'Something went wrong signing you in. Please try again.',
        );
      }
      return EmailAuthResult(uid: user.uid, isNewAccount: false);
    } on FirebaseAuthException catch (e) {
      throw EmailAuthError(_mapLoginError(e), code: e.code);
    }
  }

  /// Signs out the current Email/Password user.
  /// `FirebaseAuth.instance.currentUser` is `null` immediately after this
  /// resolves.
  Future<void> signOut() => _auth.signOut();

  String _mapSignupError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email. Try logging in instead.';
      case 'invalid-email':
        return 'That email address doesn\'t look right. Please check it and try again.';
      case 'weak-password':
        return 'That password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      default:
        return 'Could not create your account right now. Please try again.';
    }
  }

  String _mapLoginError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No KaamSetu account found for this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'invalid-email':
        return 'That email address doesn\'t look right. Please check it and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      default:
        return 'Could not sign you in right now. Please try again.';
    }
  }
}
