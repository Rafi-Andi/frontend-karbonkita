import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../models/merchant_dashboard.dart';
import '../../models/mitra_product.dart';

/// Akses mentah ke endpoint merchant backend (role:mitra).
class MerchantRemoteDatasource {
  MerchantRemoteDatasource(this._client);

  final DioClient _client;

  /// GET /api/merchant/dashboard
  Future<MerchantDashboard> fetchDashboard() async {
    final envelope = await _client.get(ApiEndpoints.merchantDashboard);
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return MerchantDashboard.fromJson(data);
    }
    throw const FormatException('Format dashboard merchant tidak dikenali.');
  }

  /// PATCH /api/merchant/status {is_open: bool}
  /// Return {store_name, is_open}.
  Future<bool> updateStatus({required bool isOpen}) async {
    final envelope = await _client.patch(ApiEndpoints.merchantStatus, {
      'is_open': isOpen,
    });
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      final raw = data['is_open'];
      if (raw is bool) return raw;
      if (raw is num) return raw != 0;
    }
    return isOpen;
  }

  /// POST /api/vouchers/redeem {unique_code: qr_token}
  /// Token asli backend format KBK-XXX-XXX (lihat VoucherController).
  Future<RedeemResult> redeem({required String uniqueCode}) async {
    final envelope = await _client.post(ApiEndpoints.vouchersRedeem, {
      'unique_code': uniqueCode,
    });
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return RedeemResult.fromJson(data);
    }
    throw const FormatException('Format hasil redeem tidak dikenali.');
  }

  /// GET /api/merchant/disbursements?status=all|completed|...&page=N
  /// Return halaman riwayat pencairan (item + meta paginasi).
  Future<DisbursementHistoryPage> fetchDisbursements({
    String status = 'all',
    int page = 1,
  }) async {
    final envelope = await _client.get(
      '${ApiEndpoints.merchantDisbursements}?status=$status&page=$page',
    );
    final meta = envelope['meta'];
    return DisbursementHistoryPage.fromJson(
      envelope,
      meta is Map<String, dynamic> ? meta : const {},
    );
  }

  /// GET /api/merchant/products — katalog milik toko sendiri.
  Future<List<MitraProduct>> fetchProducts() async {
    final envelope = await _client.get(ApiEndpoints.merchantProducts);
    final data = envelope['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(MitraProduct.fromJson)
          .toList();
    }
    throw const FormatException('Format daftar produk tidak dikenali.');
  }

  /// POST /api/merchant/products {title, description, category, rupiah_value}.
  /// Bila [photo] ada, kirim multipart `foto_produk` (foto otomatis jadi
  /// foto voucher saat didanai admin).
  Future<MitraProduct> createProduct(
    Map<String, dynamic> fields, {
    XFile? photo,
  }) async {
    if (photo == null) {
      final envelope = await _client.post(
        ApiEndpoints.merchantProducts,
        fields,
      );
      final data = envelope['data'];
      if (data is Map<String, dynamic>) return MitraProduct.fromJson(data);
      throw const FormatException('Format hasil produk tidak dikenali.');
    }
    final envelope = await _client.postMultipartFiles(
      ApiEndpoints.merchantProducts,
      fields: fields.map((k, v) => MapEntry(k, v.toString())),
      files: {'foto_produk': await _part(photo)},
    );
    final data = envelope['data'];
    if (data is Map<String, dynamic>) return MitraProduct.fromJson(data);
    throw const FormatException('Format hasil produk tidak dikenali.');
  }

  /// POST /api/merchant/products/{id}/photo (multipart `foto_produk`).
  Future<MitraProduct> uploadProductPhoto(int id, XFile photo) async {
    final envelope = await _client.postMultipartFiles(
      ApiEndpoints.merchantProductPhoto(id),
      fields: const {},
      files: {'foto_produk': await _part(photo)},
    );
    final data = envelope['data'];
    if (data is Map<String, dynamic>) return MitraProduct.fromJson(data);
    throw const FormatException('Format hasil produk tidak dikenali.');
  }

  Future<MultipartFile> _part(XFile file) async {
    if (kIsWeb) {
      return MultipartFile.fromBytes(
        await file.readAsBytes(),
        filename: file.name,
      );
    }
    return MultipartFile.fromFile(file.path, filename: file.name);
  }

  /// PATCH /api/merchant/products/{id}.
  Future<MitraProduct> updateProduct(
    int id,
    Map<String, dynamic> fields,
  ) async {
    final envelope = await _client.patch(
      ApiEndpoints.merchantProduct(id),
      fields,
    );
    final data = envelope['data'];
    if (data is Map<String, dynamic>) return MitraProduct.fromJson(data);
    throw const FormatException('Format hasil produk tidak dikenali.');
  }

  /// DELETE /api/merchant/products/{id}.
  Future<void> deleteProduct(int id) async {
    await _client.delete(ApiEndpoints.merchantProduct(id));
  }
}
