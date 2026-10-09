import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../models/leaderboard.dart';

/// Akses mentah ke endpoint leaderboard backend.
class LeaderboardRemoteDatasource {
  LeaderboardRemoteDatasource(this._client);

  final DioClient _client;

  /// GET /api/leaderboard?scope=rt|rw&timeframe=weekly|monthly
  /// Return peringkat individu + posisi user saat ini.
  Future<LeaderboardBoard> fetchLeaderboard({
    required LeaderboardScope scope,
    required LeaderboardTimeframe timeframe,
  }) async {
    final envelope = await _client.get(
      ApiEndpoints.leaderboardQuery(
        scope: scope.query,
        timeframe: timeframe.query,
      ),
    );
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return LeaderboardBoard.fromJson(data);
    }
    throw const FormatException('Format leaderboard tidak dikenali.');
  }
}
