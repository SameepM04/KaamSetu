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

/// ------------------------------------------------------------------------
/// IMAGEKIT — profile-photo storage
/// ------------------------------------------------------------------------
/// Profile photos are uploaded to ImageKit instead of Firebase Storage,
/// specifically because Firebase Storage requires the paid Blaze plan
/// (see the Spark-plan note above) — ImageKit does not. Everything else
/// (Auth, Firestore, jobs, applications, ratings) still goes through
/// Firebase unchanged.
///
/// [kImageKitPublicKey] and [kImageKitUrlEndpoint] are safe to ship in the
/// client — copy them from your ImageKit dashboard ("Developer options").
///
/// [kImageKitAuthEndpoint] must point at a server endpoint that returns
/// `{"token": ..., "expire": ..., "signature": ...}` for a new upload.
/// ImageKit's PRIVATE key signs that payload, so it must be generated on a
/// server you control — e.g. a Firebase Cloud Function such as:
///
///   exports.imagekitAuth = functions.https.onRequest((req, res) => {
///     const imagekit = new ImageKit({
///       publicKey: '...',
///       privateKey: functions.config().imagekit.private_key, // never client-side
///       urlEndpoint: '...',
///     });
///     res.set('Access-Control-Allow-Origin', '*'); // needed for Flutter Web
///     res.json(imagekit.getAuthenticationParameters());
///   });
///
/// Until all three constants below are filled in, profile-photo uploads
/// fail with a clear `ImageKitException` (see `imagekit_service.dart`)
/// rather than silently pretending to succeed.
const String kImageKitPublicKey = '';
const String kImageKitUrlEndpoint = '';
const String kImageKitAuthEndpoint = '';
