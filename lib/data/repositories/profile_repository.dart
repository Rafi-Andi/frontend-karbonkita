import '../../core/network/voucher_exception.dart';
import '../../core/storage/cache_keys.dart';
import '../../core/storage/cache_service.dart';
import '../../core/storage/token_storage.dart';
import '../../models/activity.dart';
import '../../models/level_tier.dart';
import '../datasources/profile_remote_datasource.dart';

/// Orkestrasi data profil / level tiers / aktivitas + cache offline.
class ProfileRepository {
  ProfileRepository(this._remote, {CacheService? cache, TokenStorage? storage})
    : _cache = cache,
      _storage = storage;

  final ProfileRemoteDatasource _remote;
  final CacheService? _cache;
  final TokenStorage? _storage;

  Future<String> _uid() async {
    try {
      final user = await _storage?.readUser();
      if (user != null) return user.id.toString();
    } catch (_) {}
    return 'guest';
  }

  /// Ambil 3 tier lencana level + status unlock dari backend.
  Future<LevelTiersData> getLevels() async {
    try {
      final result = await _remote.fetchLevels();
      final cache = _cache;
      if (cache != null) {
        await cache.writeJson(CacheKeys.levels(await _uid()), result.toJson());
      }
      return result;
    } on VoucherException {
      rethrow;
    } catch (e) {
      throw VoucherException('Gagal memuat level: $e');
    }
  }

  Future<({LevelTiersData? data, DateTime? savedAt})> getCachedLevels() async {
    final cache = _cache;
    if (cache == null) return (data: null, savedAt: null);
    final key = CacheKeys.levels(await _uid());
    final map = cache.readMap(key) ?? cache.readMap(CacheKeys.levels('guest'));
    if (map == null) return (data: null, savedAt: null);
    try {
      return (
        data: LevelTiersData.fromJson(map),
        savedAt: cache.lastUpdated(key),
      );
    } catch (_) {
      return (data: null, savedAt: null);
    }
  }

  /// Ambil aktivitas terbaru user dari backend.
  Future<List<UserActivity>> getActivities({int limit = 5}) async {
    try {
      final result = await _remote.fetchActivities(limit: limit);
      final cache = _cache;
      if (cache != null) {
        await cache.writeJson(
          CacheKeys.activities(await _uid(), limit),
          result.map((a) => a.toJson()).toList(),
        );
      }
      return result;
    } on VoucherException {
      rethrow;
    } catch (e) {
      throw VoucherException('Gagal memuat aktivitas: $e');
    }
  }

  Future<({List<UserActivity> items, DateTime? savedAt})> getCachedActivities({
    int limit = 5,
  }) async {
    final cache = _cache;
    if (cache == null) return (items: const <UserActivity>[], savedAt: null);
    final key = CacheKeys.activities(await _uid(), limit);
    final raw =
        cache.readList(key) ??
        cache.readList(CacheKeys.activities('guest', limit));
    if (raw == null) return (items: const <UserActivity>[], savedAt: null);
    try {
      return (
        items: raw
            .whereType<Map<String, dynamic>>()
            .map(UserActivity.fromJson)
            .toList(),
        savedAt: cache.lastUpdated(key),
      );
    } catch (_) {
      return (items: const <UserActivity>[], savedAt: null);
    }
  }
}
