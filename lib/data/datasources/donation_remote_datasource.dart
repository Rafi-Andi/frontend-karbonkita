import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../models/donation.dart';
import '../../models/mitra_product.dart';

/// Akses mentah ke endpoint donasi & campaign backend.
///
/// Publik (tanpa login): katalog + detail campaign.
/// Login: buat/batal donasi + riwayat sendiri.
/// Admin: kelola campaign + buat voucher pendanaan.
class DonationRemoteDatasource {
  DonationRemoteDatasource(this._client);

  final DioClient _client;

  /// GET /api/donation-campaigns — hanya campaign terbuka.
  Future<List<DonationCampaign>> fetchCampaigns() async {
    final envelope = await _client.get(ApiEndpoints.donationCampaigns);
    final data = envelope['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(DonationCampaign.fromJson)
          .toList();
    }
    throw const FormatException('Format daftar campaign tidak dikenali.');
  }

  /// GET /api/donation-campaigns/{slug} — detail + leaderboard donatur.
  Future<DonationCampaign> fetchCampaignDetail(String slug) async {
    final envelope = await _client.get(
      ApiEndpoints.donationCampaignDetail(slug),
    );
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return DonationCampaign.fromJson(data);
    }
    throw const FormatException('Format detail campaign tidak dikenali.');
  }

  /// POST /api/donations — buat donasi + invoice Xendit (201).
  Future<CreateDonationResult> createDonation({
    required int campaignId,
    required int amount,
    String? payerName,
  }) async {
    final envelope = await _client.post(ApiEndpoints.donations, {
      'campaign_id': campaignId,
      'amount': amount,
      if (payerName != null && payerName.trim().isNotEmpty)
        'payer_name': payerName.trim(),
    });
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return CreateDonationResult.fromJson(data);
    }
    throw const FormatException('Format hasil donasi tidak dikenali.');
  }

  /// GET /api/user/my-donations — riwayat + total + tier.
  Future<MyDonationInventory> fetchMyDonations() async {
    final envelope = await _client.get(ApiEndpoints.myDonations);
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return MyDonationInventory.fromJson(data);
    }
    throw const FormatException('Format riwayat donasi tidak dikenali.');
  }

  /// POST /api/donations/{id}/cancel — batalkan pending (jadi expired).
  Future<void> cancelDonation(int id) async {
    await _client.post(ApiEndpoints.donationCancel(id), const {});
  }

  /// GET /api/admin/donation-campaigns — semua status (draft/active/closed).
  Future<List<DonationCampaign>> fetchAdminCampaigns() async {
    final envelope = await _client.get(ApiEndpoints.adminDonationCampaigns);
    final data = envelope['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(DonationCampaign.fromJson)
          .toList();
    }
    throw const FormatException('Format daftar campaign tidak dikenali.');
  }

  /// POST /api/admin/donation-campaigns (201 → {id, slug, status}).
  Future<Map<String, dynamic>> createCampaign(
    Map<String, dynamic> fields,
  ) async {
    final envelope = await _client.post(
      ApiEndpoints.adminDonationCampaigns,
      fields,
    );
    final data = envelope['data'];
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Format hasil campaign tidak dikenali.');
  }

  /// PATCH /api/admin/donation-campaigns/{id}.
  Future<Map<String, dynamic>> updateCampaign(
    int id,
    Map<String, dynamic> fields,
  ) async {
    final envelope = await _client.patch(
      ApiEndpoints.adminDonationCampaign(id),
      fields,
    );
    final data = envelope['data'];
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Format hasil campaign tidak dikenali.');
  }

  /// POST /api/admin/vouchers — voucher didanai campaign (201).
  /// Body baru: {campaign_id, mitra_product_id, stock, expired_at}.
  /// Harga snapshot dari produk, points auto ceil(rupiah/40).
  /// 422 bila dana campaign kurang / produk nonaktif.
  Future<FundedVoucherResult> createFundedVoucher(
    Map<String, dynamic> fields,
  ) async {
    final envelope = await _client.post(ApiEndpoints.adminVouchers, fields);
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return FundedVoucherResult.fromJson(data);
    }
    throw const FormatException('Format hasil voucher tidak dikenali.');
  }

  /// GET /api/admin/mitra-products — picker produk untuk funding.
  /// Mendukung ?mitra_profile_id=&is_active=&category=.
  Future<List<MitraProduct>> fetchAdminMitraProducts({
    int? mitraProfileId,
  }) async {
    var path = ApiEndpoints.adminMitraProducts;
    if (mitraProfileId != null) {
      path += '?mitra_profile_id=$mitraProfileId';
    }
    final envelope = await _client.get(path);
    final data = envelope['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(MitraProduct.fromJson)
          .toList();
    }
    throw const FormatException('Format daftar produk tidak dikenali.');
  }
}
