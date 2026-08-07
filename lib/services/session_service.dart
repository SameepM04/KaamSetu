import 'package:shared_preferences/shared_preferences.dart';

/// Persists the Fake-OTP-flow session across app restarts using
/// [SharedPreferences] — the app's chosen persistence mechanism for this
/// dev-mode auth flow (see `lib/config/dev_config.dart`).
///
/// This is intentionally only used by [FakeAuthService]. The real
/// [FirebaseAuthService] flow keeps relying on Firebase Auth's own built-in
/// session persistence (`FirebaseAuth.instance.currentUser`), exactly as it
/// did before this change — nothing about the production auth path is
/// altered.
class SessionService {
  SessionService._();

  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUid = 'session_uid';
  static const String _keyFullName = 'session_fullName';
  static const String _keyPhoneNumber = 'session_phoneNumber';
  static const String _keyAvatar = 'session_avatar';
  static const String _keyRole = 'session_role';

  /// Whether a Fake-OTP session is currently active. Read on app start
  /// (see [SplashScreen]) to decide whether to skip straight to Home.
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Saves a new authenticated session after a successful Fake OTP
  /// verification. Mirrors the fields the real Firebase flow would have
  /// written to the `workers/{uid}` Firestore document.
  static Future<void> saveSession({
    required String uid,
    required String fullName,
    required String phoneNumber,
    String? avatar,
    String role = 'worker',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUid, uid);
    await prefs.setString(_keyFullName, fullName);
    await prefs.setString(_keyPhoneNumber, phoneNumber);
    await prefs.setString(_keyAvatar, avatar ?? '');
    await prefs.setString(_keyRole, role);
  }

  /// Reads back the persisted session fields, shaped the same way the
  /// Firestore `workers/{uid}` document / [LocalWorkerSession] would be, so
  /// callers can drop the result straight into [LocalWorkerSession.save].
  static Future<Map<String, dynamic>> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final avatar = prefs.getString(_keyAvatar);
    return {
      'uid': prefs.getString(_keyUid),
      'fullName': prefs.getString(_keyFullName),
      'phoneNumber': prefs.getString(_keyPhoneNumber),
      'selectedAvatar': (avatar == null || avatar.isEmpty) ? null : avatar,
      'role': prefs.getString(_keyRole) ?? 'worker',
    };
  }

  /// Clears the persisted session on logout.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUid);
    await prefs.remove(_keyFullName);
    await prefs.remove(_keyPhoneNumber);
    await prefs.remove(_keyAvatar);
    await prefs.remove(_keyRole);
  }
}
