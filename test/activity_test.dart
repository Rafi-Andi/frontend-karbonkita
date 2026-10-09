import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/bloc/activity/activity_bloc.dart';
import 'package:karbon_kita_app/bloc/activity/activity_event.dart';
import 'package:karbon_kita_app/bloc/activity/activity_state.dart';
import 'package:karbon_kita_app/core/network/dio_client.dart';
import 'package:karbon_kita_app/core/network/voucher_exception.dart';
import 'package:karbon_kita_app/data/datasources/profile_remote_datasource.dart';
import 'package:karbon_kita_app/data/repositories/profile_repository.dart';
import 'package:karbon_kita_app/models/activity.dart';

List<Map<String, dynamic>> _envelopeList() => [
  {
    'id': 'quiz-9',
    'kind': 'quiz',
    'title': 'Kuis Hijau Harian',
    'delta': 30,
    'created_at': '2026-09-19T08:45:00.000Z',
  },
  {
    'id': 'tx-7',
    'kind': 'voucher',
    'title': 'Tukar Voucher UMKM',
    'delta': -200,
    'created_at': '2026-09-18T07:45:00.000Z',
  },
];

class FakeProfileRepository extends ProfileRepository {
  FakeProfileRepository({this.result, this.error})
    : super(ProfileRemoteDatasource(DioClient()));

  final List<UserActivity>? result;
  final Exception? error;

  @override
  Future<List<UserActivity>> getActivities({int limit = 5}) async {
    if (error != null) throw error!;
    return result!;
  }
}

void main() {
  group('UserActivity parsing (kontrak ActivityController)', () {
    test('fromJson baca kind + delta bertanda + tanggal', () {
      final items = _envelopeList().map(UserActivity.fromJson).toList();

      expect(items, hasLength(2));
      expect(items[0].kind, 'quiz');
      expect(items[0].delta, 30);
      expect(items[0].createdAt?.hour, 8);
      expect(items[1].delta, -200);
    });

    test('field hilang tetap aman', () {
      final item = UserActivity.fromJson({});
      expect(item.kind, 'other');
      expect(item.delta, 0);
      expect(item.createdAt, isNull);
    });
  });

  group('ActivityBloc', () {
    test('loaded -> status loaded + items', () async {
      final fixture = _envelopeList().map(UserActivity.fromJson).toList();
      final bloc = ActivityBloc(FakeProfileRepository(result: fixture));
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ActivityState>(
            (s) => s.status == ActivityStatus.loaded && s.items.length == 2,
          ),
        ),
      );
      bloc.add(const ActivityLoaded());
      await future;
      await bloc.close();
    });

    test('gagal -> status error + pesan', () async {
      final bloc = ActivityBloc(
        FakeProfileRepository(
          error: const VoucherException('Gagal memuat aktivitas.'),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ActivityState>(
            (s) =>
                s.status == ActivityStatus.error &&
                s.errorMessage == 'Gagal memuat aktivitas.',
          ),
        ),
      );
      bloc.add(const ActivityLoaded());
      await future;
      await bloc.close();
    });
  });
}
