import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../models/activity.dart';
import '../../models/level_tier.dart';

/// Akses mentah ke endpoint profil backend.
class ProfileRemoteDatasource {
  ProfileRemoteDatasource(this._client);

  final DioClient _client;

  /// GET /api/user/levels
  /// Return XP + 3 tier (newbie/keeper/warrior) + status unlock.
  Future<LevelTiersData> fetchLevels() async {
    final envelope = await _client.get(ApiEndpoints.userLevels);
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return LevelTiersData.fromJson(data);
    }
    throw const FormatException('Format level tiers tidak dikenali.');
  }

  /// GET /api/user/activities
  /// Return aktivitas terbaru (poin masuk/keluar + XP kuis).
  Future<List<UserActivity>> fetchActivities({int limit = 5}) async {
    final envelope = await _client.get(
      '${ApiEndpoints.userActivities}?limit=$limit',
    );
    final data = envelope['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(UserActivity.fromJson)
          .toList();
    }
    throw const FormatException('Format aktivitas tidak dikenali.');
  }
}
