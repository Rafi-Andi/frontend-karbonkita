import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../models/admin_reward.dart';

/// Akses mentah ke endpoint kelola reward/voucher marketplace (role:admin).
class AdminRewardRemoteDatasource {
  AdminRewardRemoteDatasource(this._client);

  final DioClient _client;

  /// GET /api/admin/vouchers — semua reward (termasuk nonaktif & kedaluwarsa).
  Future<List<AdminReward>> fetchAdminRewards() async {
    final envelope = await _client.get(ApiEndpoints.adminVouchers);
    final data = envelope['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(AdminReward.fromJson)
          .toList();
    }
    throw const FormatException('Format daftar reward tidak dikenali.');
  }

  /// PATCH /api/admin/vouchers/{id} — ubah stok & tenggat (partial).
  Future<AdminReward> updateReward(
    int id, {
    int? stock,
    String? expiredAt,
  }) async {
    final body = <String, dynamic>{};
    if (stock != null) body['stock'] = stock;
    if (expiredAt != null) body['expired_at'] = expiredAt;
    final envelope = await _client.patch(ApiEndpoints.adminVoucher(id), body);
    final data = envelope['data'];
    if (data is Map<String, dynamic>) return AdminReward.fromJson(data);
    throw const FormatException('Format hasil reward tidak dikenali.');
  }

  /// PATCH /api/admin/vouchers/{id}/status — {is_active: bool}.
  Future<AdminReward> setRewardStatus(int id, bool isActive) async {
    final envelope = await _client.patch(ApiEndpoints.adminVoucherStatus(id), {
      'is_active': isActive,
    });
    final data = envelope['data'];
    if (data is Map<String, dynamic>) return AdminReward.fromJson(data);
    throw const FormatException('Format hasil reward tidak dikenali.');
  }

  /// GET /api/admin/vouchers/{id}/claims?page=N — daftar penukar (20/halaman).
  Future<AdminRewardClaimsPage> fetchRewardClaims(
    int id, {
    int page = 1,
  }) async {
    final envelope = await _client.get(
      ApiEndpoints.adminVoucherClaims(id, page: page),
    );
    final data = envelope['data'];
    final meta = envelope['meta'];
    if (data is List) {
      final metaMap = meta is Map ? meta : const {};
      final items = data
          .whereType<Map<String, dynamic>>()
          .map(AdminRewardClaim.fromJson)
          .toList();
      return AdminRewardClaimsPage(
        items: items,
        currentPage: (metaMap['current_page'] as num? ?? 1).toInt(),
        lastPage: (metaMap['last_page'] as num? ?? 1).toInt(),
        total: (metaMap['total'] as num? ?? items.length).toInt(),
      );
    }
    throw const FormatException('Format daftar penukar tidak dikenali.');
  }
}
