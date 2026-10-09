import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../models/auth_response.dart';
import '../../models/mitra_register_result.dart';
import '../../models/user.dart';

/// Akses mentah ke endpoint auth backend.
class AuthRemoteDatasource {
  AuthRemoteDatasource(this._client);

  final DioClient _client;

  Future<AuthResponse> login({
    required String phoneOrEmail,
    required String password,
  }) async {
    final envelope = await _client.post(ApiEndpoints.login, {
      'phone_or_email': phoneOrEmail.trim(),
      'password': password,
    });
    return AuthResponse.fromEnvelope(envelope);
  }

  /// Register warga. Nama wilayah harus sudah kanonis dari dropdown
  /// (backend deploy-an hanya validasi string bebas).
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
    final envelope = await _client.post(ApiEndpoints.register, {
      'name': name.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
      'city': city.trim(),
      'district': district.trim(),
      'sub_district': subDistrict.trim(),
      'rt': rt.trim(),
      'rw': rw.trim(),
    });
    return AuthResponse.fromEnvelope(envelope);
  }

  /// Best-effort: kegagalan jaringan saat logout tidak boleh menghalangi
  /// hapus sesi lokal (repository selalu clear lokal).
  Future<void> logout() async {
    try {
      await _client.post(ApiEndpoints.logout, const {});
    } catch (_) {
      // abaikan, repository tetap hapus token lokal
    }
  }

  Future<User> me() async {
    final envelope = await _client.get(ApiEndpoints.me);
    final data = envelope['data'];
    if (data is Map<String, dynamic>) return User.fromJson(data);
    throw const FormatException('Format profil tidak dikenali.');
  }

  /// POST /api/auth/register-mitra (multipart: fields + file KTP/NIB/toko).
  /// Kunci [files]: foto_ktp, foto_nib, foto_toko (wajib),
  /// foto_toko_2, foto_toko_3 (opsional, null bila kosong).
  ///
  /// Mobile baca via path file; web baca via bytes karena path blob
  /// tidak bisa dibuka dengan dart:io.
  Future<MitraRegisterResult> registerMitra({
    required Map<String, dynamic> fields,
    required Map<String, XFile?> files,
  }) async {
    final parts = <String, MultipartFile>{};
    for (final entry in files.entries) {
      final file = entry.value;
      if (file == null) continue;
      if (kIsWeb) {
        parts[entry.key] = MultipartFile.fromBytes(
          await file.readAsBytes(),
          filename: file.name,
        );
      } else {
        parts[entry.key] = await MultipartFile.fromFile(
          file.path,
          filename: file.name,
        );
      }
    }
    final envelope = await _client.postMultipartFiles(
      ApiEndpoints.registerMitra,
      fields: fields,
      files: parts,
    );
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return MitraRegisterResult.fromJson(data);
    }
    throw const FormatException('Format hasil registrasi tidak dikenali.');
  }
}
