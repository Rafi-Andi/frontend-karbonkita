import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../models/merchant_dashboard.dart';

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
}
