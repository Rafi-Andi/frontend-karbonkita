import '../../core/network/auth_exception.dart';
import '../../core/network/voucher_exception.dart';
import '../../models/merchant_application.dart';
import '../datasources/admin_merchant_remote_datasource.dart';

/// Orkestrasi data validasi mitra untuk admin.
///
/// Data admin selalu fresh dari backend (tanpa cache Hive): keputusan
/// approve/reject harus berbasis antrean terkini, bukan snapshot offline.
class AdminMerchantRepository {
  AdminMerchantRepository(this._remote);

  final AdminMerchantRemoteDatasource _remote;

  Future<MerchantApplicationPage> getApplications({
    String status = 'pending',
  }) async {
    try {
      return await _remote.fetchApplications(status: status);
    } on VoucherException {
      rethrow;
    } on AuthException catch (e) {
      throw VoucherException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw VoucherException('Gagal memuat antrean mitra: $e');
    }
  }

  Future<MerchantApplicationDetail> getDetail(int id) async {
    try {
      return await _remote.fetchDetail(id);
    } on VoucherException {
      rethrow;
    } on AuthException catch (e) {
      throw VoucherException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw VoucherException('Gagal memuat detail mitra: $e');
    }
  }

  /// 403/404/409/422 backend diteruskan dengan statusCode asli.
  Future<MerchantVerifyResult> verify({
    required int id,
    required bool approve,
    String? reason,
  }) async {
    if (!approve && (reason == null || reason.trim().isEmpty)) {
      throw const VoucherException('Alasan penolakan wajib diisi.');
    }
    try {
      return await _remote.verify(id: id, approve: approve, reason: reason);
    } on VoucherException {
      rethrow;
    } on AuthException catch (e) {
      throw VoucherException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw VoucherException('Gagal memverifikasi mitra: $e');
    }
  }
}
