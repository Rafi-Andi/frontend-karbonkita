import 'package:dio/dio.dart';

import 'api_endpoints.dart';
import 'auth_exception.dart';

typedef TokenReader = Future<String?> Function();

/// Dio terpusat untuk KarbonKita.
///
/// - Base URL dari [ApiEndpoints].
/// - Attach `Authorization: Bearer` bila token tersedia.
/// - Mapping status backend ke [AuthException] yang ramah UI.
class DioClient {
  DioClient({Dio? dio, TokenReader? tokenReader})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiEndpoints.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          ),
      _tokenReader = tokenReader {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenReader?.call();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenReader? _tokenReader;

  Dio get dio => _dio;

  /// POST helper yang melempar [AuthException] dengan pesan siap tampil.
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.post(path, data: body);
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      return <String, dynamic>{'data': data};
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final res = await _dio.get(path);
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      return <String, dynamic>{'data': data};
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// PATCH helper untuk toggle status toko. Error mapping sama dengan post.
  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.patch(path, data: body);
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      return <String, dynamic>{'data': data};
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// POST multipart untuk upload file (mis. verifikasi sampah).
  ///
  /// [fields] dikirim sebagai form fields, [filePath] sebagai single file
  /// di [fileField]. Timeout 60 detik karena upload + antre AI Gemini
  /// di backend bisa >20 detik.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, dynamic> fields,
    required String filePath,
    required String fileField,
    String? fileName,
  }) async {
    try {
      final resolvedName = fileName ?? filePath.split(RegExp(r'[\\/]')).last;
      final formData = FormData.fromMap({
        ...fields,
        fileField: await MultipartFile.fromFile(
          filePath,
          filename: resolvedName,
        ),
      });
      final res = await _dio.post(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      return <String, dynamic>{'data': data};
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// POST multipart multi-file (mis. register mitra: KTP/NIB/foto toko).
  ///
  /// Terima [files] yang sudah berupa [MultipartFile] jadi caller
  /// (datasource) yang memilih cara bangun per platform: `fromFile` di
  /// mobile, `fromBytes` di web (path blob tidak bisa dibaca via dart:io).
  Future<Map<String, dynamic>> postMultipartFiles(
    String path, {
    required Map<String, dynamic> fields,
    required Map<String, MultipartFile> files,
  }) async {
    try {
      final formData = FormData.fromMap({...fields, ...files});
      final res = await _dio.post(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      return <String, dynamic>{'data': data};
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  AuthException _map(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;

    String message = 'Terjadi kesalahan jaringan. Coba lagi.';
    var errors = const <String, List<String>>{};
    Map<String, dynamic>? data;

    if (body is Map) {
      final rawMsg = body['message'];
      if (rawMsg is String && rawMsg.isNotEmpty) message = rawMsg;
      final rawErrors = body['errors'];
      if (rawErrors is Map) {
        final parsed = <String, List<String>>{};
        rawErrors.forEach((key, value) {
          if (value is List) {
            parsed[key.toString()] = value.map((v) => v.toString()).toList();
          } else if (value != null) {
            parsed[key.toString()] = [value.toString()];
          }
        });
        errors = parsed;
      }
      final rawData = body['data'];
      if (rawData is Map<String, dynamic>) {
        data = rawData;
      } else if (rawData is Map) {
        data = rawData.map((k, v) => MapEntry(k.toString(), v));
      }
    }

    switch (status) {
      case 401:
        // Login gagal punya pesan ramah khusus; endpoint lain (mis.
        // verify-waste tanpa token) pakai pesan backend apa adanya.
        final unauthorizedMsg =
            message == 'Terjadi kesalahan jaringan. Coba lagi.'
            ? 'No HP/Email atau kata sandi salah.'
            : message;
        return AuthException(
          unauthorizedMsg,
          errors: errors,
          statusCode: status,
          data: data,
        );
      case 403:
        return AuthException(
          message.isNotEmpty
              ? message
              : 'Akun dinonaktifkan. Hubungi dukungan.',
          errors: errors,
          statusCode: status,
          data: data,
        );
      case 422:
        // Backend mengirim message generik "Validation failed." dengan detail
        // di `errors`. Pakai pesan field pertama agar user tahu penyebabnya.
        final fieldMessage = errors.values
            .expand((e) => e)
            .firstWhere((m) => m.trim().isNotEmpty, orElse: () => '');
        return AuthException(
          fieldMessage.isNotEmpty
              ? fieldMessage
              : (message.isNotEmpty
                    ? message
                    : 'Data belum valid. Periksa kembali.'),
          errors: errors,
          statusCode: status,
          data: data,
        );
      case 429:
        return AuthException(
          'Terlalu sering mencoba. Tunggu 1 menit lalu coba lagi.',
          errors: errors,
          statusCode: status,
          data: data,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        // Error server (mis. exception backend): body biasanya HTML debug,
        // bukan JSON — jangan tampilkan pesan jaringan yang menyesatkan.
        return AuthException(
          'Server bermasalah (kode $status). Coba lagi nanti.',
          errors: errors,
          statusCode: status,
          data: data,
        );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const AuthException(
        'Tidak dapat terhubung ke server. Periksa koneksi.',
      );
    }

    return AuthException(
      message,
      errors: errors,
      statusCode: status,
      data: data,
    );
  }
}
