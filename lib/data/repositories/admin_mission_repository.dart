import '../../core/network/auth_exception.dart';
import '../../core/network/mission_exception.dart';
import '../../models/mission.dart';
import '../datasources/admin_mission_remote_datasource.dart';

/// Orkestrasi data kelola misi untuk admin.
///
/// Tanpa cache: daftar kelola harus selalu fresh dari backend.
/// Error 422 membawa `errors` per-field agar form menampilkan rincian.
class AdminMissionRepository {
  AdminMissionRepository(this._remote);

  final AdminMissionRemoteDatasource _remote;

  Future<List<Mission>> getAdminMissions() =>
      _guard(() => _remote.fetchAdminMissions(), 'Gagal memuat daftar misi');

  Future<Map<String, dynamic>> createMission(Map<String, dynamic> fields) =>
      _guard(() => _remote.createMission(fields), 'Gagal membuat misi');

  Future<Map<String, dynamic>> updateMission(
    int id,
    Map<String, dynamic> fields,
  ) =>
      _guard(() => _remote.updateMission(id, fields), 'Gagal memperbarui misi');

  Future<Map<String, dynamic>> setMissionStatus(int id, bool isActive) =>
      _guard(
        () => _remote.setMissionStatus(id, isActive),
        isActive ? 'Gagal mengaktifkan misi' : 'Gagal menonaktifkan misi',
      );

  Future<T> _guard<T>(Future<T> Function() call, String fallback) async {
    try {
      return await call();
    } on MissionException {
      rethrow;
    } on AuthException catch (e) {
      throw MissionException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
        data: e.data,
      );
    } catch (e) {
      throw MissionException('$fallback: $e');
    }
  }
}
