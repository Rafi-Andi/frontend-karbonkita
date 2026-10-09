import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan sesi login.
///
/// - Token Sanctum (`1|...`) HANYA di secure storage, permanen sampai logout.
/// - Profil ringan (id, name, role) di shared_preferences untuk auto-login UI.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? secure, SharedPreferences? prefs})
    : _secure = secure ?? const FlutterSecureStorage(),
      _prefs = prefs;

  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'auth_user_id';
  static const String userNameKey = 'auth_user_name';
  static const String userRoleKey = 'auth_user_role';

  final FlutterSecureStorage _secure;
  SharedPreferences? _prefs;

  Future<SharedPreferences> _prefsInstance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> saveToken(String token) =>
      _secure.write(key: tokenKey, value: token);

  Future<String?> readToken() => _secure.read(key: tokenKey);

  Future<void> deleteToken() => _secure.delete(key: tokenKey);

  Future<void> saveUser({
    required int id,
    required String name,
    required String role,
  }) async {
    final prefs = await _prefsInstance();
    await prefs.setInt(userIdKey, id);
    await prefs.setString(userNameKey, name);
    await prefs.setString(userRoleKey, role);
  }

  Future<({int id, String name, String role})?> readUser() async {
    final prefs = await _prefsInstance();
    final id = prefs.getInt(userIdKey);
    final name = prefs.getString(userNameKey);
    final role = prefs.getString(userRoleKey);
    if (id == null || name == null || role == null) return null;
    return (id: id, name: name, role: role);
  }

  Future<void> clearUser() async {
    final prefs = await _prefsInstance();
    await prefs.remove(userIdKey);
    await prefs.remove(userNameKey);
    await prefs.remove(userRoleKey);
  }

  Future<void> clearAll() async {
    await deleteToken();
    await clearUser();
  }
}
