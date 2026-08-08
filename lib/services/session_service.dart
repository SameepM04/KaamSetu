import 'dart:convert';

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

  // Extended profile fields
  static const String _keyAddress = 'session_address';
  static const String _keySkills = 'session_skills';
  static const String _keyExperience = 'session_experience';
  static const String _keyPreferredCategories = 'session_preferredCategories';
  static const String _keyAvailability = 'session_availability';
  static const String _keyWorkingRadius = 'session_workingRadius';
  static const String _keyExpectedDailyWage = 'session_expectedDailyWage';
  static const String _keyLanguages = 'session_languages';

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
    // Extended profile fields (optional — only set when editing profile)
    String? address,
    List<String>? skills,
    String? experience,
    List<String>? preferredCategories,
    List<String>? availability,
    double? workingRadius,
    int? expectedDailyWage,
    List<String>? languages,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUid, uid);
    await prefs.setString(_keyFullName, fullName);
    await prefs.setString(_keyPhoneNumber, phoneNumber);
    await prefs.setString(_keyAvatar, avatar ?? '');
    await prefs.setString(_keyRole, role);

    // Only write extended fields if they were explicitly provided,
    // so a basic login call doesn't wipe previously saved profile data.
    if (address != null) await prefs.setString(_keyAddress, address);
    if (skills != null) await prefs.setString(_keySkills, jsonEncode(skills));
    if (experience != null) await prefs.setString(_keyExperience, experience);
    if (preferredCategories != null) {
      await prefs.setString(
          _keyPreferredCategories, jsonEncode(preferredCategories));
    }
    if (availability != null) {
      await prefs.setString(_keyAvailability, jsonEncode(availability));
    }
    if (workingRadius != null) {
      await prefs.setDouble(_keyWorkingRadius, workingRadius);
    }
    if (expectedDailyWage != null) {
      await prefs.setInt(_keyExpectedDailyWage, expectedDailyWage);
    }
    if (languages != null) {
      await prefs.setString(_keyLanguages, jsonEncode(languages));
    }
  }

  /// Reads back the persisted session fields, shaped the same way the
  /// Firestore `workers/{uid}` document / [LocalWorkerSession] would be, so
  /// callers can drop the result straight into [LocalWorkerSession.save].
  static Future<Map<String, dynamic>> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final avatar = prefs.getString(_keyAvatar);

    // Helper to safely decode a JSON-encoded string list.
    List<String> decodeList(String key) {
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return [];
      try {
        return List<String>.from(jsonDecode(raw) as List);
      } catch (_) {
        return [];
      }
    }

    return {
      'uid': prefs.getString(_keyUid),
      'fullName': prefs.getString(_keyFullName),
      'phoneNumber': prefs.getString(_keyPhoneNumber),
      'selectedAvatar': (avatar == null || avatar.isEmpty) ? null : avatar,
      'role': prefs.getString(_keyRole) ?? 'worker',
      // Extended profile fields
      'address': prefs.getString(_keyAddress) ?? '',
      'skills': decodeList(_keySkills),
      'experienceYears': prefs.getString(_keyExperience) ?? '',
      'preferredCategories': decodeList(_keyPreferredCategories),
      'availability': decodeList(_keyAvailability),
      'workingRadiusKm': prefs.getDouble(_keyWorkingRadius) ?? 5.0,
      'expectedDailyWage': prefs.getInt(_keyExpectedDailyWage) ?? 0,
      'languagesKnown': decodeList(_keyLanguages),
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
    await prefs.remove(_keyAddress);
    await prefs.remove(_keySkills);
    await prefs.remove(_keyExperience);
    await prefs.remove(_keyPreferredCategories);
    await prefs.remove(_keyAvailability);
    await prefs.remove(_keyWorkingRadius);
    await prefs.remove(_keyExpectedDailyWage);
    await prefs.remove(_keyLanguages);
  }
}