import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const _userIdKey = "user_id";
  static const _emailKey = "email";
  static const _usernameKey = "username";
  static const _interestsKey = "interests";
  static const _emotionsKey = "preferred_emotions";
  static const _firstLoginKey = "is_first_login";

  // -------------------------
  // SAVE USER (LOGIN)
  // -------------------------
  static Future<void> saveUser({
    required String userId,
    required String email,
    required String username,
    required List<String> interests,
    required List<String> emotions,
    required bool isFirstLogin,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_userIdKey, userId.trim());
    await prefs.setString(_emailKey, email.trim());
    await prefs.setString(_usernameKey, username.trim());
    await prefs.setStringList(_interestsKey, interests);
    await prefs.setStringList(_emotionsKey, emotions);
    await prefs.setBool(_firstLoginKey, isFirstLogin);
  }

  // -------------------------
  // FIRST LOGIN CHECK
  // -------------------------
  static Future<bool> isFirstLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLoginKey) ?? true;
  }

  static Future<void> markVisited() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLoginKey, false);
  }

  // -------------------------
  // AUTH HELPERS
  // -------------------------
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_userIdKey);
    return uid != null && uid.trim().isNotEmpty;
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_userIdKey);
    if (uid == null) return null;
    final trimmed = uid.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  static Future<List<String>> getInterests() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_interestsKey) ?? [];
  }

  static Future<List<String>> getEmotions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_emotionsKey) ?? [];
  }

  // -------------------------
  // LOGOUT
  // -------------------------
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
