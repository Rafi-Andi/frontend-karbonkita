import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../models/dashboard.dart';
import '../../models/my_voucher.dart';
import '../../models/voucher.dart';
import '../../models/voucher_city.dart';

/// Akses mentah ke endpoint voucher & dashboard backend.
class VoucherRemoteDatasource {
  VoucherRemoteDatasource(this._client);

  final DioClient _client;

  /// GET /api/vouchers[?category=...&city=...]
  /// Return list voucher aktif, stok tersedia, belum kedaluwarsa.
  Future<List<Voucher>> fetchVouchers({String? category, String? city}) async {
    final envelope = await _client.get(
      ApiEndpoints.vouchersQuery(category: category, city: city),
    );
    final data = envelope['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Voucher.fromJson)
          .toList();
    }
    throw const FormatException('Format daftar voucher tidak dikenali.');
  }

  /// GET /api/vouchers/cities — kota yang punya voucher aktif.
  Future<List<VoucherCity>> fetchVoucherCities() async {
    final envelope = await _client.get(ApiEndpoints.voucherCities);
    final data = envelope['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(VoucherCity.fromJson)
          .toList();
    }
    throw const FormatException('Format daftar kota tidak dikenali.');
  }

  /// GET /api/user/dashboard
  /// Ambil paket dashboard Beranda: user, daily_missions, leaderboard_preview.
  Future<DashboardData> fetchDashboard() async {
    final envelope = await _client.get(ApiEndpoints.userDashboard);
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return DashboardData.fromJson(data);
    }
    throw const FormatException('Format dashboard tidak dikenali.');
  }

  /// GET /api/user/dashboard (delegasi)
  /// Saldo eco_points diambil dari paket dashboard agar 1 sumber.
  Future<int> fetchEcoPoints() async {
    final dashboard = await fetchDashboard();
    return dashboard.user.ecoPoints;
  }

  /// GET /api/user/my-vouchers
  /// Return inventaris dompet: active, used, expired.
  Future<MyVoucherInventory> fetchMyVouchers() async {
    final envelope = await _client.get(ApiEndpoints.myVouchers);
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return MyVoucherInventory.fromJson(data);
    }
    throw const FormatException('Format dompet voucher tidak dikenali.');
  }

  /// POST /api/vouchers/claim
  /// Tukar poin dengan voucher. 201 + QR token bila berhasil.
  Future<ClaimResult> claimVoucher({required int voucherId}) async {
    final envelope = await _client.post(ApiEndpoints.vouchersClaim, {
      'voucher_id': voucherId,
    });
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return ClaimResult.fromJson(data);
    }
    throw const FormatException('Format hasil klaim tidak dikenali.');
  }
}
