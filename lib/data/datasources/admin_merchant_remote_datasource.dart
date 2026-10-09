import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../models/merchant_application.dart';

/// Akses mentah ke endpoint validasi mitra (role:admin).
class AdminMerchantRemoteDatasource {
  AdminMerchantRemoteDatasource(this._client);

  final DioClient _client;

  /// GET /api/admin/merchants?status=pending|verified|rejected
  Future<MerchantApplicationPage> fetchApplications({
    String status = 'pending',
  }) async {
    final envelope = await _client.get(
      ApiEndpoints.adminMerchantsQuery(status: status),
    );
    return MerchantApplicationPage.fromEnvelope(envelope);
  }

  /// GET /api/admin/merchants/{id}
  Future<MerchantApplicationDetail> fetchDetail(int id) async {
    final envelope = await _client.get(ApiEndpoints.adminMerchantDetail(id));
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return MerchantApplicationDetail.fromJson(data);
    }
    throw const FormatException('Format detail mitra tidak dikenali.');
  }

  /// POST /api/admin/merchants/{id}/verify {action, reason?}
  /// reason wajib bila action=reject (divalidasi backend juga).
  Future<MerchantVerifyResult> verify({
    required int id,
    required bool approve,
    String? reason,
  }) async {
    final envelope = await _client.post(ApiEndpoints.adminMerchantVerify(id), {
      'action': approve ? 'approve' : 'reject',
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return MerchantVerifyResult.fromJson(data);
    }
    throw const FormatException('Format hasil verifikasi tidak dikenali.');
  }
}
