import 'package:image_picker/image_picker.dart';

import '../../core/storage/cache_service.dart';
import '../../core/storage/token_storage.dart';
import '../../models/auth_response.dart';
import '../../models/mitra_register_result.dart';
import '../../models/user.dart';
import '../datasources/auth_remote_datasource.dart';

/// Orkestrasi login + sesi permanen (hapus hanya saat logout).
class AuthRepository {
  AuthRepository(this._remote, this._storage, {CacheService? cache})
    : _cache = cache;

  final AuthRemoteDatasource _remote;
  final TokenStorage _storage;
  final CacheService? _cache;

  Future<AuthResponse> login({
    required String phoneOrEmail,
    required String password,
  }) async {
    final result = await _remote.login(
      phoneOrEmail: phoneOrEmail,
      password: password,
    );
    if (result.token.isEmpty) {
      throw const FormatException('Token kosong dari server.');
    }
    await _storage.saveToken(result.token);
    await _storage.saveUser(
      id: result.user.id,
      name: result.user.name,
      role: result.user.role,
    );
    return result;
  }

  /// Register warga baru + simpan sesi seperti login.
  Future<AuthResponse> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String city,
    required String district,
    required String subDistrict,
    required String rt,
    required String rw,
  }) async {
    final result = await _remote.register(
      name: name,
      phone: phone,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      city: city,
      district: district,
      subDistrict: subDistrict,
      rt: rt,
      rw: rw,
    );
    if (result.token.isEmpty) {
      throw const FormatException('Token kosong dari server.');
    }
    await _storage.saveToken(result.token);
    await _storage.saveUser(
      id: result.user.id,
      name: result.user.name,
      role: result.user.role,
    );
    return result;
  }

  /// Cek sesi tersimpan: token ada + profil /me valid.
  /// Return null bila belum login / token basi.
  ///
  /// Offline: bila token + profil lokal ada tapi `/me` gagal karena
  /// jaringan, kembalikan profil lokal agar cache offline tetap tampil
  /// (bukan logout paksa). Cache dibersihkan hanya saat logout eksplisit.
  Future<User?> checkSession() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;
    try {
      final user = await _remote.me();
      await _storage.saveUser(id: user.id, name: user.name, role: user.role);
      return user;
    } catch (_) {
      final local = await _storage.readUser();
      if (local != null) {
        return User(id: local.id, name: local.name, role: local.role);
      }
      await _storage.clearAll();
      return null;
    }
  }

  Future<void> logout() async {
    await _remote.logout();
    await _storage.clearAll();
    // Ganti user = cache user lama tidak boleh terlihat.
    await _cache?.clearAll();
  }

  /// Daftar mitra baru (multipart + foto). Backend langsung mengembalikan
  /// token → sesi disimpan seperti login (auto-login, status pending).
  Future<MitraRegisterResult> registerMitra({
    required Map<String, dynamic> fields,
    required Map<String, XFile?> files,
  }) async {
    final result = await _remote.registerMitra(fields: fields, files: files);
    if (result.token.isEmpty) {
      throw const FormatException('Token kosong dari server.');
    }
    await _storage.saveToken(result.token);
    await _storage.saveUser(
      id: result.user.id,
      name: result.user.name,
      role: result.user.role,
    );
    return result;
  }
}
