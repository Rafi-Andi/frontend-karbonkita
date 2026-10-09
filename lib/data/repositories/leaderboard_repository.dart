import '../../core/network/voucher_exception.dart';
import '../../core/storage/cache_keys.dart';
import '../../core/storage/cache_service.dart';
import '../../models/leaderboard.dart';
import '../datasources/leaderboard_remote_datasource.dart';

/// Orkestrasi data papan peringkat + cache offline read-only.
class LeaderboardRepository {
  LeaderboardRepository(this._remote, {CacheService? cache}) : _cache = cache;

  final LeaderboardRemoteDatasource _remote;
  final CacheService? _cache;

  /// Ambil peringkat individu + posisi user dari backend.
  Future<LeaderboardBoard> getLeaderboard({
    required LeaderboardScope scope,
    required LeaderboardTimeframe timeframe,
  }) async {
    try {
      final result = await _remote.fetchLeaderboard(
        scope: scope,
        timeframe: timeframe,
      );
      final cache = _cache;
      if (cache != null) {
        await cache.writeJson(
          CacheKeys.leaderboard(scope.query, timeframe.query),
          result.toJson(),
        );
      }
      return result;
    } on VoucherException {
      rethrow;
    } catch (e) {
      throw VoucherException('Gagal memuat leaderboard: $e');
    }
  }

  Future<({LeaderboardBoard? board, DateTime? savedAt})> getCachedLeaderboard({
    required LeaderboardScope scope,
    required LeaderboardTimeframe timeframe,
  }) async {
    final cache = _cache;
    if (cache == null) return (board: null, savedAt: null);
    final key = CacheKeys.leaderboard(scope.query, timeframe.query);
    final map = cache.readMap(key);
    if (map == null) return (board: null, savedAt: null);
    try {
      return (
        board: LeaderboardBoard.fromJson(map),
        savedAt: cache.lastUpdated(key),
      );
    } catch (_) {
      return (board: null, savedAt: null);
    }
  }
}
