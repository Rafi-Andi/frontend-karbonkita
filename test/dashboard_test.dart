import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/bloc/dashboard/dashboard_bloc.dart';
import 'package:karbon_kita_app/bloc/dashboard/dashboard_event.dart';
import 'package:karbon_kita_app/bloc/dashboard/dashboard_state.dart';
import 'package:karbon_kita_app/core/network/dio_client.dart';
import 'package:karbon_kita_app/core/network/voucher_exception.dart';
import 'package:karbon_kita_app/data/datasources/voucher_remote_datasource.dart';
import 'package:karbon_kita_app/data/repositories/voucher_repository.dart';
import 'package:karbon_kita_app/models/dashboard.dart';

Map<String, dynamic> _envelopeData() => {
  'user': {
    'name': 'Moch. Rafi Andi',
    'level': 'Earth Warrior 7',
    'xp': 2350,
    'xp_max': 3500,
    'xp_percentage': 67.14,
    'eco_points': 1250,
    'streak_days': 7,
    'rank_percentage': 8.0,
    'total_distance_km': '12.50',
    'total_waste_kg': 3,
    'total_carbon_saved_kg': 5.25,
  },
  'daily_missions': [
    {
      'id': 1,
      'title': 'Pejuang Pedal 2 km',
      'description': 'Bersepeda 2 km',
      'category': 'mobility',
      'xp_reward': 250,
      'points_reward': 150,
      'icon': 'bike',
    },
  ],
  'leaderboard_preview': [
    {
      'rank': 1,
      'user_id': 2,
      'name': 'Reza Rahardian',
      'rt': '005',
      'rw': '02',
      'xp': 3450,
      'avatar': null,
      'level': 'Earth Warrior 8',
    },
  ],
};

class FakeVoucherRepository extends VoucherRepository {
  FakeVoucherRepository({this.result, this.error})
    : super(VoucherRemoteDatasource(DioClient()));

  final DashboardData? result;
  final Exception? error;

  @override
  Future<DashboardData> getDashboard() async {
    if (error != null) throw error!;
    return result!;
  }
}

void main() {
  group('DashboardData parsing (kontrak DashboardResource)', () {
    test('fromJson baca user + misi + preview', () {
      final data = DashboardData.fromJson(_envelopeData());

      expect(data.user.name, 'Moch. Rafi Andi');
      expect(data.user.level, 'Earth Warrior 7');
      expect(data.user.xp, 2350);
      expect(data.user.xpMax, 3500);
      expect(data.user.xpPercentage, 67.14);
      expect(data.user.ecoPoints, 1250);
      expect(data.user.streakDays, 7);
      expect(data.user.rankPercentage, 8.0);
      // decimal backend terkirim sebagai String tetap terparse.
      expect(data.user.totalDistanceKm, 12.50);

      expect(data.dailyMissions, hasLength(1));
      expect(data.dailyMissions.first.category, 'mobility');

      expect(data.leaderboardPreview, hasLength(1));
      expect(data.leaderboardPreview.first.rank, 1);
      expect(data.leaderboardPreview.first.xp, 3450);
    });

    test('list kosong/null tetap aman', () {
      final data = DashboardData.fromJson({
        'user': {'name': 'X'},
      });
      expect(data.dailyMissions, isEmpty);
      expect(data.leaderboardPreview, isEmpty);
    });
  });

  group('DashboardBloc', () {
    test('loaded -> status loaded + data', () async {
      final fixture = DashboardData.fromJson(_envelopeData());
      final bloc = DashboardBloc(FakeVoucherRepository(result: fixture));
      // Subscribe dulu sebelum add (broadcast stream tidak buffer).
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DashboardState>(
            (s) =>
                s.status == DashboardStatus.loaded &&
                s.dashboard?.user.ecoPoints == 1250,
          ),
        ),
      );
      bloc.add(const DashboardLoaded());
      await future;
      await bloc.close();
    });

    test('gagal -> status error + pesan', () async {
      final bloc = DashboardBloc(
        FakeVoucherRepository(
          error: const VoucherException('Gagal memuat dashboard.'),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DashboardState>(
            (s) =>
                s.status == DashboardStatus.error &&
                s.errorMessage == 'Gagal memuat dashboard.',
          ),
        ),
      );
      bloc.add(const DashboardLoaded());
      await future;
      await bloc.close();
    });
  });
}
