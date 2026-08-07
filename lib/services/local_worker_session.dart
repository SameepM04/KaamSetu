/// Holds the worker's profile fields for the lifetime of the current app
/// run, for use whenever there is no signed-in Firebase user.
///
/// `WorkerAuthService` delegates to [FakeAuthService] while `kUseFakeOtp`
/// is `true` (see `lib/config/dev_config.dart`), and that implementation
/// never talks to Firebase — so nothing is ever written to `workers/{uid}`
/// in Firestore and `FirebaseAuth.currentUser` stays null. `WorkerHomeTab`
/// and `WorkerProfileScreen` normally read the signed-in worker's data from
/// that Firestore document; with no document and no user, they fall back
/// to this in-memory session instead.
///
/// [FakeAuthService] saves the entered profile fields here on successful
/// OTP verification (mirroring what it also persists to [SessionService]
/// for restart survival), and clears it on logout. It is intentionally
/// in-memory only for the current run — [SessionService] is what survives
/// an app restart; this class is rehydrated from it on launch (see
/// `SplashScreen`).
class LocalWorkerSession {
  LocalWorkerSession._();

  /// Stable identity for repositories when there is no real Firebase Auth
  /// user (i.e. the Fake OTP flow).
  static const String debugUid = 'fake-worker-kaamsetu';

  static Map<String, dynamic> _data = const {};

  /// Current session worker data, or an empty map if nothing has been
  /// saved yet (e.g. app just launched with no sign up/login this run).
  static Map<String, dynamic> get data => _data;

  /// Prefers a uid already associated with the local session, otherwise
  /// uses the stable fallback identity.
  static String get userId {
    final savedUid = _data['uid'];
    return savedUid is String && savedUid.trim().isNotEmpty
        ? savedUid
        : debugUid;
  }

  /// Stores/merges fields for the current session.
  static void save(Map<String, dynamic> fields) {
    _data = {..._data, ...fields};
  }

  static void clear() => _data = const {};
}
