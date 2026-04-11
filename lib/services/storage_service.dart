import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _authTokenKey = 'auth_token';
  static const String _localeCodeKey = 'locale_code';
  static const String _rememberedEmailKey = 'remembered_email';
  static const String _rememberedPasswordKey = 'remembered_password';

  /// Save authentication token
  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  /// Get authentication token
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  /// Remove authentication token
  static Future<void> removeAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> saveLocaleCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeCodeKey, code);
  }

  static Future<String?> getLocaleCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeCodeKey);
  }

  static Future<void> saveRememberedCredentials({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rememberedEmailKey, email);
    await prefs.setString(_rememberedPasswordKey, password);
  }

  static Future<Map<String, String>?> getRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_rememberedEmailKey);
    final password = prefs.getString(_rememberedPasswordKey);

    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }

    return {'email': email, 'password': password};
  }

  static Future<void> clearRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberedEmailKey);
    await prefs.remove(_rememberedPasswordKey);
  }
}
