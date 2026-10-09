import 'package:shared_preferences/shared_preferences.dart';

/// Flag onboarding sekali-tampil (non-sensitif → shared_preferences).
class OnboardingStorage {
  OnboardingStorage({SharedPreferences? prefs}) : _prefs = prefs;

  static const String seenKey = 'onboarding_seen_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<bool> hasSeenOnboarding() async {
    final prefs = await _instance();
    return prefs.getBool(seenKey) ?? false;
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await _instance();
    await prefs.setBool(seenKey, true);
  }

  /// Untuk test: inject prefs tanpa instance asli.
  void setPrefsForTest(SharedPreferences prefs) => _prefs = prefs;
}
