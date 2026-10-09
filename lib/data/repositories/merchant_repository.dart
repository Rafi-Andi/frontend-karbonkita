import 'package:image_picker/image_picker.dart';

import '../../core/network/auth_exception.dart';
import '../../core/network/voucher_exception.dart';
import '../../core/storage/cache_keys.dart';
import '../../core/storage/cache_service.dart';
import '../../core/storage/token_storage.dart';
import '../../models/merchant_dashboard.dart';
import '../../models/mitra_product.dart';
import '../datasources/merchant_remote_datasource.dart';

/// Orkestrasi data dashboard merchant + cache offline read-only.
///
/// Mengikuti pola [VoucherRepository]: fetch sukses ditulis ke Hive,
/// BLoC memanggil `getCachedDashboard` dulu agar UI tampil instan offline.
class MerchantRepository {
  MerchantRepository(this._remote, {CacheService? cache, TokenStorage? storage})
    : _cache = cache,
      _storage = storage;

  final MerchantRemoteDatasource _remote;
  final CacheService? _cache;
  final TokenStorage? _storage;

  Future<String> _uid() async {
    try {
      final user = await _storage?.readUser();
      if (user != null) return user.id.toString();
    } catch (_) {}
    return 'guest';
  }

  /// Ambil dashboard toko sendiri dari backend + simpan cache.
  Future<MerchantDashboard> getDashboard() async {
    try {
      final result = await _remote.fetchDashboard();
      final cache = _cache;
      if (cache != null) {
        await cache.writeJson(
          CacheKeys.merchantDashboard(await _uid()),
          result.toJson(),
        );
      }
      return result;
    } on VoucherException {
      rethrow;
    } on AuthException catch (e) {
      throw VoucherException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw VoucherException('Gagal memuat dashboard merchant: $e');
    }
  }

  Future<({MerchantDashboard? dashboard, DateTime? savedAt})>
  getCachedDashboard() async {
    final cache = _cache;
    if (cache == null) return (dashboard: null, savedAt: null);
    final key = CacheKeys.merchantDashboard(await _uid());
    final map =
        cache.readMap(key) ??
        cache.readMap(CacheKeys.merchantDashboard('guest'));
    if (map == null) return (dashboard: null, savedAt: null);
    try {
      return (
        dashboard: MerchantDashboard.fromJson(map),
        savedAt: cache.lastUpdated(key),
      );
    } catch (_) {
      return (dashboard: null, savedAt: null);
    }
  }

  /// Toggle Buka/Tutup toko. Optimistic update dilakukan di BLoC,
  /// repository memastikan cache ikut diperbarui bila sukses.
  Future<bool> updateStatus({required bool isOpen}) async {
    try {
      final confirmed = await _remote.updateStatus(isOpen: isOpen);
      final cache = _cache;
      if (cache != null) {
        final cached = await getCachedDashboard();
        final current = cached.dashboard;
        if (current != null) {
          final updated = MerchantDashboard(
            storeName: current.storeName,
            verificationStatus: current.verificationStatus,
            isOpen: confirmed,
            canRedeem: current.isVerified && confirmed,
            balance: current.balance,
            stats: current.stats,
            recent: current.recent,
          );
          await cache.writeJson(
            CacheKeys.merchantDashboard(await _uid()),
            updated.toJson(),
          );
        }
      }
      return confirmed;
    } on VoucherException {
      rethrow;
    } on AuthException catch (e) {
      throw VoucherException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw VoucherException('Gagal mengubah status toko: $e');
    }
  }

  /// Ambil riwayat pencairan (paginated) untuk halaman Riwayat Pencairan.
  Future<DisbursementHistoryPage> getDisbursements({
    String status = 'all',
    int page = 1,
  }) async {
    try {
      return await _remote.fetchDisbursements(status: status, page: page);
    } on VoucherException {
      rethrow;
    } on AuthException catch (e) {
      throw VoucherException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw VoucherException('Gagal memuat riwayat pencairan: $e');
    }
  }

  /// Produk milik toko sendiri (master harga fix untuk funding admin).
  Future<List<MitraProduct>> getProducts() async {
    try {
      return await _remote.fetchProducts();
    } on VoucherException {
      rethrow;
    } on AuthException catch (e) {
      throw VoucherException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw VoucherException('Gagal memuat produk: $e');
    }
  }

  Future<MitraProduct> createProduct(
    Map<String, dynamic> fields, {
    XFile? photo,
  }) async {
    try {
      return await _remote.createProduct(fields, photo: photo);
    } on VoucherException {
      rethrow;
    } on AuthException catch (e) {
      throw VoucherException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw VoucherException('Gagal membuat produk: $e');
    }
  }

  Future<MitraProduct> uploadProductPhoto(int id, XFile photo) async {
    try {
      return await _remote.uploadProductPhoto(id, photo);
    } on VoucherException {
      rethrow;
    } on AuthException catch (e) {
      throw VoucherException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw VoucherException('Gagal mengunggah foto produk: $e');
    }
  }

  Future<MitraProduct> updateProduct(
    int id,
    Map<String, dynamic> fields,
  ) async {
    try {
      return await _remote.updateProduct(id, fields);
    } on VoucherException {
      rethrow;
    } on AuthException catch (e) {
      throw VoucherException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw VoucherException('Gagal memperbarui produk: $e');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _remote.deleteProduct(id);
    } on VoucherException {
      rethrow;
    } on AuthException catch (e) {
      throw VoucherException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw VoucherException('Gagal menghapus produk: $e');
    }
  }

  /// Redeem voucher warga (QR scan / input manual token).
  /// 403/404/409/422 dari backend diteruskan dengan statusCode asli
  /// agar UI bisa menampilkan pesan yang tepat.
  Future<RedeemResult> redeem({required String uniqueCode}) async {
    final code = uniqueCode.trim();
    if (code.isEmpty) {
      throw const VoucherException('Masukkan nomor token voucher.');
    }
    try {
      final result = await _remote.redeem(uniqueCode: code);
      // Saldo + riwayat berubah → refresh dashboard agar angka sinkron.
      try {
        await getDashboard();
      } catch (_) {}
      return result;
    } on VoucherException {
      rethrow;
    } on AuthException catch (e) {
      throw VoucherException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw VoucherException('Gagal verifikasi voucher: $e');
    }
  }
}
