import '../../core/network/auth_exception.dart';
import '../../core/network/voucher_exception.dart';
import '../../core/storage/cache_keys.dart';
import '../../core/storage/cache_service.dart';
import '../../core/storage/token_storage.dart';
import '../datasources/voucher_remote_datasource.dart';
import '../../models/dashboard.dart';
import '../../models/my_voucher.dart';
import '../../models/voucher.dart';
import '../../models/voucher_city.dart';

/// Orkestrasi data marketplace voucher + cache offline read-only.
///
/// Setiap fetch sukses langsung ditulis ke [CacheService]; saat offline
/// BLoC memanggil `getCached*` dulu agar UI tampil instan tanpa loading.
class VoucherRepository {
  VoucherRepository(this._remote, {CacheService? cache, TokenStorage? storage})
    : _cache = cache,
      _storage = storage;

  final VoucherRemoteDatasource _remote;
  final CacheService? _cache;
  final TokenStorage? _storage;

  Future<String> _uid() async {
    try {
      final user = await _storage?.readUser();
      if (user != null) return user.id.toString();
    } catch (_) {}
    return 'guest';
  }

  // ---------- vouchers ----------

  /// Ambil daftar voucher yang bisa diklaim dari backend.
  /// [category] null = semua kategori, [city] null/kosong = semua kota.
  Future<List<Voucher>> getVouchers({String? category, String? city}) async {
    try {
      final result = await _remote.fetchVouchers(
        category: category,
        city: city,
      );
      final cache = _cache;
      if (cache != null) {
        await cache.writeJson(
          CacheKeys.vouchers(category, city),
          result.map((v) => v.toJson()).toList(),
        );
      }
      return result;
    } on VoucherException {
      rethrow;
    } catch (e) {
      throw VoucherException('Gagal memuat voucher: $e');
    }
  }

  Future<({List<Voucher> vouchers, DateTime? savedAt})> getCachedVouchers({
    String? category,
    String? city,
  }) async {
    final cache = _cache;
    if (cache == null) {
      return (vouchers: const <Voucher>[], savedAt: null);
    }
    final key = CacheKeys.vouchers(category, city);
    final raw = cache.readList(key);
    if (raw == null) return (vouchers: const <Voucher>[], savedAt: null);
    try {
      final list = raw
          .whereType<Map<String, dynamic>>()
          .map(Voucher.fromJson)
          .toList();
      return (vouchers: list, savedAt: cache.lastUpdated(key));
    } catch (_) {
      return (vouchers: const <Voucher>[], savedAt: null);
    }
  }

  // ---------- dashboard ----------

  /// Ambil paket dashboard Beranda dari backend.
  Future<DashboardData> getDashboard() async {
    try {
      final result = await _remote.fetchDashboard();
      final cache = _cache;
      if (cache != null) {
        await cache.writeJson(
          CacheKeys.dashboard(await _uid()),
          result.toJson(),
        );
      }
      return result;
    } on VoucherException {
      rethrow;
    } catch (e) {
      throw VoucherException('Gagal memuat dashboard: $e');
    }
  }

  Future<({DashboardData? dashboard, DateTime? savedAt})>
  getCachedDashboard() async {
    final cache = _cache;
    if (cache == null) return (dashboard: null, savedAt: null);
    final key = CacheKeys.dashboard(await _uid());
    final map = cache.readMap(key);
    if (map == null) {
      // Fallback guest (data tersimpan sebelum uid dikenal).
      final guest = cache.readMap(CacheKeys.dashboard('guest'));
      if (guest == null) return (dashboard: null, savedAt: null);
      try {
        return (
          dashboard: DashboardData.fromJson(guest),
          savedAt: cache.lastUpdated(CacheKeys.dashboard('guest')),
        );
      } catch (_) {
        return (dashboard: null, savedAt: null);
      }
    }
    try {
      return (
        dashboard: DashboardData.fromJson(map),
        savedAt: cache.lastUpdated(key),
      );
    } catch (_) {
      return (dashboard: null, savedAt: null);
    }
  }

  // ---------- eco points ----------

  /// Ambil saldo eco_points user dari backend.
  Future<int> getEcoPoints() async {
    try {
      final result = await _remote.fetchEcoPoints();
      final cache = _cache;
      if (cache != null) {
        await cache.writeJson(CacheKeys.ecoPoints(await _uid()), {
          'value': result,
        });
      }
      return result;
    } on VoucherException {
      rethrow;
    } catch (e) {
      throw VoucherException('Gagal memuat saldo poin: $e');
    }
  }

  Future<int?> getCachedEcoPoints() async {
    final map = _cache?.readMap(CacheKeys.ecoPoints(await _uid()));
    final raw = map?['value'];
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  // ---------- dompet ----------

  /// Ambil inventaris dompet voucher dari backend.
  Future<MyVoucherInventory> getMyVouchers() async {
    try {
      final result = await _remote.fetchMyVouchers();
      final cache = _cache;
      if (cache != null) {
        await cache.writeJson(
          CacheKeys.myVouchers(await _uid()),
          result.toJson(),
        );
      }
      return result;
    } on VoucherException {
      rethrow;
    } on AuthException catch (e) {
      // Dio melempar AuthException langsung — pertahankan statusCode (401).
      throw VoucherException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw VoucherException('Gagal memuat dompet voucher: $e');
    }
  }

  Future<({MyVoucherInventory? inventory, DateTime? savedAt})>
  getCachedMyVouchers() async {
    final cache = _cache;
    if (cache == null) return (inventory: null, savedAt: null);
    final key = CacheKeys.myVouchers(await _uid());
    final map =
        cache.readMap(key) ?? cache.readMap(CacheKeys.myVouchers('guest'));
    if (map == null) return (inventory: null, savedAt: null);
    try {
      return (
        inventory: MyVoucherInventory.fromJson(map),
        savedAt: cache.lastUpdated(key),
      );
    } catch (_) {
      return (inventory: null, savedAt: null);
    }
  }

  /// Daftar kota yang punya voucher aktif (opsi filter).
  Future<List<VoucherCity>> getVoucherCities() async {
    try {
      final result = await _remote.fetchVoucherCities();
      final cache = _cache;
      if (cache != null) {
        await cache.writeJson(
          CacheKeys.voucherCities,
          result
              .map((c) => {'city': c.city, 'voucher_count': c.voucherCount})
              .toList(),
        );
      }
      return result;
    } on VoucherException {
      rethrow;
    } catch (e) {
      throw VoucherException('Gagal memuat daftar kota: $e');
    }
  }

  Future<List<VoucherCity>> getCachedVoucherCities() async {
    final raw = _cache?.readList(CacheKeys.voucherCities);
    if (raw == null) return const [];
    try {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(VoucherCity.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Klaim voucher dengan poin. 401/422/500 diteruskan dengan statusCode.
  Future<ClaimResult> claimVoucher({required int voucherId}) async {
    try {
      return await _remote.claimVoucher(voucherId: voucherId);
    } on VoucherException {
      rethrow;
    } on AuthException catch (e) {
      throw VoucherException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw VoucherException('Gagal klaim voucher: $e');
    }
  }
}
