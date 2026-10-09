import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../models/mission.dart';

/// Akses mentah ke endpoint kelola misi (role:admin).
class AdminMissionRemoteDatasource {
  AdminMissionRemoteDatasource(this._client);

  final DioClient _client;

  /// GET /api/admin/missions — semua misi mobility & waste (semua status).
  Future<List<Mission>> fetchAdminMissions() async {
    final envelope = await _client.get(ApiEndpoints.adminMissions);
    final data = envelope['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Mission.fromJson)
          .toList();
    }
    throw const FormatException('Format daftar misi tidak dikenali.');
  }

  /// POST /api/admin/missions (201).
  Future<Map<String, dynamic>> createMission(
    Map<String, dynamic> fields,
  ) async {
    final envelope = await _client.post(ApiEndpoints.adminMissions, fields);
    final data = envelope['data'];
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Format hasil misi tidak dikenali.');
  }

  /// PATCH /api/admin/missions/{id}.
  Future<Map<String, dynamic>> updateMission(
    int id,
    Map<String, dynamic> fields,
  ) async {
    final envelope = await _client.patch(ApiEndpoints.adminMission(id), fields);
    final data = envelope['data'];
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Format hasil misi tidak dikenali.');
  }

  /// PATCH /api/admin/missions/{id}/status — {is_active: bool}.
  Future<Map<String, dynamic>> setMissionStatus(int id, bool isActive) async {
    final envelope = await _client.patch(ApiEndpoints.adminMissionStatus(id), {
      'is_active': isActive,
    });
    final data = envelope['data'];
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Format hasil misi tidak dikenali.');
  }
}
