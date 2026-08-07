/// Development-mode configuration.
///
/// KaamSetu's Firebase project is currently on the Spark (free) plan, which
/// does not support Firebase Phone Authentication — attempting to send a
/// real OTP fails with a `BILLING_NOT_ENABLED` error. Until the project is
/// upgraded to Blaze, [kUseFakeOtp] lets the whole app run end-to-end with a
/// local, fully offline "Fake OTP" flow instead.
///
/// -----------------------------------------------------------------------
/// HOW TO SWITCH BACK TO REAL FIREBASE PHONE AUTH
/// -----------------------------------------------------------------------
/// Set this single constant to `false`:
///
///   const bool kUseFakeOtp = false;
///
/// That's it — no other code changes are required. Every screen and every
/// service already talks to [WorkerAuthService], which picks the correct
/// implementation ([FakeAuthService] or [FirebaseAuthService]) based on
/// this flag alone. See lib/services/worker_auth_service.dart.
/// -----------------------------------------------------------------------
const bool kUseFakeOtp = true;

/// The only OTP code accepted by the Fake OTP flow.
const String kFakeOtpCode = '123456';
