import '../../core/network/auth_exception.dart';
import '../../core/network/voucher_exception.dart';
import '../../models/admin_reward.dart';
import '../datasources/admin_reward_remote_datasource.dart';

/// Orkestrasi data kelola reward untuk admin.
///
/// Tanpa cache: layar kelola harus selalu fresh dari backend (stok, tenggat,
/// dan daftar penukar cepat berubah). Error 422 membawa `errors` per-field
/// agar form ubah stok/tenggat bisa menampilkan rincian.
class AdminRewardRepository {
  AdminRewardRepository(this._remote);

  final AdminRewardRemoteDatasource _remote;

  Future<List<AdminReward>> getRewards() =>
      _guard(() => _remote.fetchAdminRewards(), 'Gagal memuat daftar reward');

  Future<AdminReward> updateReward(int id, {int? stock, String? expiredAt}) =>
      _guard(
        () => _remote.updateReward(id, stock: stock, expiredAt: expiredAt),
        'Gagal memperbarui reward',
      );

  Future<AdminReward> setRewardStatus(int id, bool isActive) => _guard(
    () => _remote.setRewardStatus(id, isActive),
    isActive ? 'Gagal mengaktifkan reward' : 'Gagal menonaktifkan reward',
  );

  Future<AdminRewardClaimsPage> getRewardClaims(int id, {int page = 1}) =>
      _guard(
        () => _remote.fetchRewardClaims(id, page: page),
        'Gagal memuat daftar penukar',
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
