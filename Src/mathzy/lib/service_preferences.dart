import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyIsFirstRun = 'mathzy_is_first_run_v2'; // Updated key
  static const String _keyUserName = 'mathzy_user_name';
  static const String _keyAvatarIndex = 'mathzy_avatar_index';
  static const String _keyCountryCode = 'mathzy_country_code_iso'; // e.g., "US", "IN"

  Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsFirstRun) ?? true; // Default to true
  }

  Future<void> setFirstRunCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsFirstRun, false);
  }

  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  Future<void> saveAvatarIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAvatarIndex, index);
  }

  Future<int?> getAvatarIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAvatarIndex);
  }

  Future<void> saveCountryCode(String code) async { // Takes ISO code string
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCountryCode, code);
  }

  Future<String?> getCountryCode() async { // Returns ISO code string
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCountryCode);
  }

    // New method to clear the country code
  Future<void> clearCountryCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCountryCode); // Use the public/consistent key
  }

  // For testing purposes
  Future<void> resetFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsFirstRun, true);
    // Optionally clear other welcome screen prefs
    // await prefs.remove(_keyUserName);
    // await prefs.remove(_keyAvatarIndex);
    // await prefs.remove(_keyCountryCode);
  }
}