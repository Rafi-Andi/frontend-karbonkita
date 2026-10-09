import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/bloc/admin_mission/admin_mission_bloc.dart';
import 'package:karbon_kita_app/bloc/admin_mission/admin_mission_event.dart';
import 'package:karbon_kita_app/bloc/admin_mission/admin_mission_state.dart';
import 'package:karbon_kita_app/core/network/dio_client.dart';
import 'package:karbon_kita_app/core/network/mission_exception.dart';
import 'package:karbon_kita_app/data/datasources/admin_mission_remote_datasource.dart';
import 'package:karbon_kita_app/data/repositories/admin_mission_repository.dart';
import 'package:karbon_kita_app/models/mission.dart';

class FakeAdminMissionRepository extends AdminMissionRepository {
  FakeAdminMissionRepository({
    this.missions = const [],
    this.createResult,
    this.updateResult,
    this.statusResult,
    this.error,
  }) : super(AdminMissionRemoteDatasource(DioClient()));

  List<Mission> missions;
  Map<String, dynamic>? createResult;
  Map<String, dynamic>? updateResult;
  Map<String, dynamic>? statusResult;
  Exception? error;

  @override
  Future<List<Mission>> getAdminMissions() async {
    if (error != null) throw error!;
    return missions;
  }

  @override
  Future<Map<String, dynamic>> createMission(
    Map<String, dynamic> fields,
  ) async {
    if (error != null) throw error!;
    return createResult ?? {'id': 9};
  }

  @override
  Future<Map<String, dynamic>> updateMission(
    int id,
    Map<String, dynamic> fields,
  ) async {
    if (error != null) throw error!;
    return updateResult ?? {'id': id};
  }

  @override
  Future<Map<String, dynamic>> setMissionStatus(int id, bool isActive) async {
    if (error != null) throw error!;
    return statusResult ?? {'id': id, 'is_active': isActive};
  }
}

Mission _mission({
  int id = 1,
  String category = 'mobility',
  String? activityType = 'cycling',
  bool isActive = true,
}) {
  return Mission(
    id: id,
    title: 'M $id',
    description: 'd',
    category: category,
    xpReward: 10,
    pointsReward: 5,
    icon: 'x',
    activityType: activityType,
    isActive: isActive,
  );
}

void main() {
  group('Mission admin fields (kontrak backend)', () {
    test('fromJson baca activity_type + is_active', () {
      final m = Mission.fromJson({
        'id': 1,
        'title': 'Pejuang Pedal 2Km',
        'description': 'd',
        'category': 'mobility',
        'xp_reward': 150,
        'points_reward': 50,
        'target_distance_km': 2,
        'activity_type': 'cycling',
        'icon': 'directions_bike',
        'is_active': false,
        'is_completed_today': false,
      });
      expect(m.activityType, 'cycling');
      expect(m.isActive, false);
      expect(m.targetDistanceKm, 2.0);
    });

    test('default aman untuk cache lama', () {
      final m = Mission.fromJson({
        'id': 2,
        'title': 'Lama',
        'description': 'd',
        'category': 'waste',
        'xp_reward': 0,
        'points_reward': 0,
        'icon': '',
      });
      expect(m.activityType, isNull);
      expect(m.isActive, true);
    });
  });

  group('AdminMissionBloc list & filter', () {
    test('loaded tampilkan semua + filter mobility', () async {
      final bloc = FakeAdminMissionRepository(
        missions: [
          _mission(id: 1),
          _mission(id: 2, category: 'waste'),
        ],
      );
      final b = AdminMissionBloc(bloc);
      b.add(const AdminMissionsLoaded());
      await expectLater(
        b.stream,
        emitsThrough(
          predicate<AdminMissionState>(
            (s) =>
                s.status == AdminMissionStatus.loaded && s.missions.length == 2,
          ),
        ),
      );
      b.add(const AdminMissionsFiltered('mobility'));
      await expectLater(
        b.stream,
        emitsThrough(
          predicate<AdminMissionState>(
            (s) => s.filter == 'mobility' && s.filteredMissions.length == 1,
          ),
        ),
      );
      await b.close();
    });
  });

  group('AdminMissionBloc submit', () {
    test('create sukses -> success + reload', () async {
      final repo = FakeAdminMissionRepository(
        missions: [_mission(id: 9)],
        createResult: {'id': 9},
      );
      final b = AdminMissionBloc(repo);
      final expectation = expectLater(
        b.stream,
        emitsInOrder([
          predicate<AdminMissionState>(
            (s) => s.submitStatus == AdminMissionSubmitStatus.submitting,
          ),
          predicate<AdminMissionState>(
            (s) => s.submitStatus == AdminMissionSubmitStatus.success,
          ),
          // Reload otomatis setelah sukses.
          predicate<AdminMissionState>(
            (s) => s.status == AdminMissionStatus.loading,
          ),
          predicate<AdminMissionState>(
            (s) =>
                s.status == AdminMissionStatus.loaded && s.missions.length == 1,
          ),
        ]),
      );
      b.add(const AdminMissionCreateSubmitted({'title': 'X'}));
      await expectation;
      await b.close();
    });

    test('422 -> failure + submitErrors utuh', () async {
      final repo = FakeAdminMissionRepository(
        error: const MissionException(
          'Validation failed.',
          errors: {
            'activity_type': ['Activity type wajib untuk misi mobility.'],
          },
          statusCode: 422,
        ),
      );
      final b = AdminMissionBloc(repo);
      b.add(const AdminMissionCreateSubmitted({'title': 'X'}));
      await expectLater(
        b.stream,
        emitsThrough(
          predicate<AdminMissionState>(
            (s) =>
                s.submitStatus == AdminMissionSubmitStatus.failure &&
                s.submitErrors['activity_type']?.isNotEmpty == true,
          ),
        ),
      );
      await b.close();
    });

    test('toggle status sukses', () async {
      final repo = FakeAdminMissionRepository(
        missions: [_mission(id: 1, isActive: true)],
      );
      final b = AdminMissionBloc(repo);
      b.add(const AdminMissionStatusSubmitted(id: 1, isActive: false));
      await expectLater(
        b.stream,
        emitsThrough(
          predicate<AdminMissionState>(
            (s) => s.submitStatus == AdminMissionSubmitStatus.success,
          ),
        ),
      );
      await b.close();
    });
  });
}
