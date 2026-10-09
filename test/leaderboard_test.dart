import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/bloc/leaderboard/leaderboard_bloc.dart';
import 'package:karbon_kita_app/bloc/leaderboard/leaderboard_event.dart';
import 'package:karbon_kita_app/bloc/leaderboard/leaderboard_state.dart';
import 'package:karbon_kita_app/core/network/auth_exception.dart';
import 'package:karbon_kita_app/core/network/dio_client.dart';
import 'package:karbon_kita_app/data/datasources/leaderboard_remote_datasource.dart';
import 'package:karbon_kita_app/data/repositories/leaderboard_repository.dart';
import 'package:karbon_kita_app/models/leaderboard.dart';

Map<String, dynamic> _envelopeData() => {
  'scope': 'rt',
  'timeframe': 'weekly',
  'rankings': [
    {
      'rank': 1,
      'user_id': 2,
      'name': 'Reza Rahardian',
      'rt': '005',
      'rw': '02',
      // SUM MySQL kadang terkirim sebagai String.
      'xp': '3450',
      'avatar': null,
      'level': 'Earth Warrior 8',
    },
    {
      'rank': 2,
      'user_id': 3,
      'name': 'Alya Nabila',
      'rt': '005',
      'rw': '02',
      'total_xp': 2890,
      'avatar': null,
      'level': 'Earth Warrior 7',
    },
  ],
  'current_user': {
    'rank': 3,
    'user_id': 7,
    'name': 'Dika',
    'rt': '005',
    'rw': '02',
    'xp': 2350,
    'level': 'Earth Warrior 7',
  },
};

class FakeLeaderboardRepository extends LeaderboardRepository {
  FakeLeaderboardRepository({this.result, this.error})
    : super(LeaderboardRemoteDatasource(DioClient()));

  final LeaderboardBoard? result;
  final Exception? error;

  @override
  Future<LeaderboardBoard> getLeaderboard({
    required LeaderboardScope scope,
    required LeaderboardTimeframe timeframe,
  }) async {
    if (error != null) throw error!;
    return result!;
  }
}

void main() {
  group('LeaderboardBoard parsing (kontrak LeaderboardResource)', () {
    test('fromJson baca rankings + current_user', () {
      final board = LeaderboardBoard.fromJson(_envelopeData());

      expect(board.scope, 'rt');
      expect(board.timeframe, 'weekly');
      expect(board.rankings, hasLength(2));
      // String "3450" tetap terparse.
      expect(board.rankings.first.xp, 3450);
      // Key alternatif total_xp juga terbaca.
      expect(board.rankings[1].xp, 2890);

      expect(board.currentUser?.rank, 3);
      expect(board.currentUser?.name, 'Dika');
      expect(board.currentUser?.avatar, isNull);
    });

    test('current_user null + rankings kosong tetap aman', () {
      final board = LeaderboardBoard.fromJson({
        'scope': 'rw',
        'timeframe': 'monthly',
      });
      expect(board.rankings, isEmpty);
      expect(board.currentUser, isNull);
    });
  });

  group('LeaderboardBloc', () {
    test('loaded default rt/weekly + data', () async {
      final fixture = LeaderboardBoard.fromJson(_envelopeData());
      final bloc = LeaderboardBloc(FakeLeaderboardRepository(result: fixture));
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LeaderboardState>(
            (s) =>
                s.status == LeaderboardStatus.loaded &&
                s.scope == LeaderboardScope.rt &&
                s.timeframe == LeaderboardTimeframe.weekly &&
                s.board?.rankings.length == 2,
          ),
        ),
      );
      bloc.add(const LeaderboardLoaded());
      await future;
      await bloc.close();
    });

    test('ganti scope/timeframe memuat ulang', () async {
      final fixture = LeaderboardBoard.fromJson(_envelopeData());
      final bloc = LeaderboardBloc(FakeLeaderboardRepository(result: fixture));
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LeaderboardState>(
            (s) =>
                s.status == LeaderboardStatus.loaded &&
                s.scope == LeaderboardScope.rw &&
                s.timeframe == LeaderboardTimeframe.monthly,
          ),
        ),
      );
      bloc.add(
        const LeaderboardLoaded(
          scope: LeaderboardScope.rw,
          timeframe: LeaderboardTimeframe.monthly,
        ),
      );
      await future;
      await bloc.close();
    });

    test('401 -> isUnauthorized (UI wajib logout)', () async {
      final bloc = LeaderboardBloc(
        FakeLeaderboardRepository(
          error: const AuthException('Unauthenticated.', statusCode: 401),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(predicate<LeaderboardState>((s) => s.isUnauthorized)),
      );
      bloc.add(const LeaderboardLoaded());
      await future;
      await bloc.close();
    });
  });
}
