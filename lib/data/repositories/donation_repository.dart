import '../../core/network/auth_exception.dart';
import '../../core/network/voucher_exception.dart';
import '../../models/donation.dart';
import '../../models/mitra_product.dart';
import '../datasources/donation_remote_datasource.dart';

/// Orkestrasi data donasi & campaign.
///
/// Tanpa cache Hive: nominal donasi, status invoice, dan sisa dana campaign
/// harus selalu fresh (uang asli). Pengecualian: daftar campaign publik
/// boleh tampil instan bila pola cache-first dibutuhkan nanti.
class DonationRepository {
  DonationRepository(this._remote);

  final DonationRemoteDatasource _remote;

  Future<List<DonationCampaign>> getCampaigns() =>
      _guard(() => _remote.fetchCampaigns(), 'Gagal memuat campaign');

  Future<DonationCampaign> getCampaignDetail(String slug) =>
      _guard(() => _remote.fetchCampaignDetail(slug), 'Gagal memuat detail');

  /// Minimal donasi backend DONATION_MIN_AMOUNT=10000 (dicek client juga).
  Future<CreateDonationResult> createDonation({
    required int campaignId,
    required int amount,
    String? payerName,
  }) async {
    if (amount < 10000) {
      throw const VoucherException('Nominal donasi minimal Rp 10.000.');
    }
    return _guard(
      () => _remote.createDonation(
        campaignId: campaignId,
        amount: amount,
        payerName: payerName,
      ),
      'Gagal membuat donasi',
    );
  }

  Future<MyDonationInventory> getMyDonations() =>
      _guard(() => _remote.fetchMyDonations(), 'Gagal memuat riwayat donasi');

  Future<void> cancelDonation(int id) =>
      _guard(() => _remote.cancelDonation(id), 'Gagal membatalkan donasi');

  Future<List<DonationCampaign>> getAdminCampaigns() =>
      _guard(() => _remote.fetchAdminCampaigns(), 'Gagal memuat campaign');

  Future<Map<String, dynamic>> createCampaign(Map<String, dynamic> fields) =>
      _guard(() => _remote.createCampaign(fields), 'Gagal membuat campaign');

  Future<Map<String, dynamic>> updateCampaign(
    int id,
    Map<String, dynamic> fields,
  ) => _guard(
    () => _remote.updateCampaign(id, fields),
    'Gagal memperbarui campaign',
  );

  /// 403 mitra belum verified / 422 dana kurang diteruskan dengan
  /// statusCode agar UI menampilkan pesan backend apa adanya.
  Future<FundedVoucherResult> createFundedVoucher(
    Map<String, dynamic> fields,
  ) => _guard(
    () => _remote.createFundedVoucher(fields),
    'Gagal membuat voucher',
  );

  /// Produk untuk picker admin (hanya verified+aktif yang fundable).
  Future<List<MitraProduct>> getAdminMitraProducts({int? mitraProfileId}) =>
      _guard(
        () => _remote.fetchAdminMitraProducts(mitraProfileId: mitraProfileId),
        'Gagal memuat produk mitra',
      );

  Future<T> _guard<T>(Future<T> Function() call, String fallback) async {
    try {
      return await call();
    } on VoucherException {
      rethrow;
    } on AuthException catch (e) {
      throw VoucherException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw VoucherException('$fallback: $e');
    }
  }
}
