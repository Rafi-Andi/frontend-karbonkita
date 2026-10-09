import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/bloc/level/level_bloc.dart';
import 'package:karbon_kita_app/bloc/level/level_event.dart';
import 'package:karbon_kita_app/bloc/level/level_state.dart';
import 'package:karbon_kita_app/core/network/dio_client.dart';
import 'package:karbon_kita_app/core/network/voucher_exception.dart';
import 'package:karbon_kita_app/data/datasources/profile_remote_datasource.dart';
import 'package:karbon_kita_app/data/repositories/profile_repository.dart';
import 'package:karbon_kita_app/models/level_tier.dart';

Map<String, dynamic> _envelopeData() => {
  'xp': 1080,
  'level': 'Earth Warrior 7',
  'current_tier': 'keeper',
  'tiers': [
    {
      'key': 'newbie',
      'label': 'Earth Newbie',
      'min_xp': 0,
      'max_xp': 499,
      'is_unlocked': true,
      'is_current': false,
      'asset': 'assets/images/level_newbie.png',
    },
    {
      'key': 'keeper',
      'label': 'Earth Keeper',
      'min_xp': 500,
      'max_xp': 1699,
      'is_unlocked': true,
      'is_current': true,
      'asset': 'assets/images/level_keeper.png',
    },
    {
      'key': 'warrior',
      'label': 'Earth Warrior',
      'min_xp': 1700,
      'max_xp': null,
      'is_unlocked': false,
      'is_current': false,
      'asset': 'assets/images/level_warrior.png',
    },
  ],
};

class FakeProfileRepository extends ProfileRepository {
  FakeProfileRepository({this.result, this.error})
    : super(ProfileRemoteDatasource(DioClient()));

  final LevelTiersData? result;
  final Exception? error;

  @override
  Future<LevelTiersData> getLevels() async {
    if (error != null) throw error!;
    return result!;
  }
}

void main() {
  group('LevelTiersData parsing (kontrak LevelController)', () {
    test('fromJson baca 3 tier + keeper current', () {
      final data = LevelTiersData.fromJson(_envelopeData());

      expect(data.xp, 1080);
      expect(data.currentTier, 'keeper');
      expect(data.tiers, hasLength(3));
      expect(data.tiers[1].isCurrent, isTrue);
      expect(data.tiers[2].isUnlocked, isFalse);
      expect(data.tiers[2].maxXp, isNull);
    });

    test('tiers kosong tetap aman', () {
      final data = LevelTiersData.fromJson({'xp': 0});
      expect(data.tiers, isEmpty);
    });
  });

  group('LevelBloc', () {
    test('loaded -> status loaded + data', () async {
      final fixture = LevelTiersData.fromJson(_envelopeData());
      final bloc = LevelBloc(FakeProfileRepository(result: fixture));
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LevelState>(
            (s) =>
                s.status == LevelStatus.loaded &&
                s.data?.currentTier == 'keeper',
          ),
        ),
      );
      bloc.add(const LevelLoaded());
      await future;
      await bloc.close();
    });

    test('gagal -> status error + pesan', () async {
      final bloc = LevelBloc(
        FakeProfileRepository(
          error: const VoucherException('Gagal memuat level.'),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LevelState>(
            (s) =>
                s.status == LevelStatus.error &&
                s.errorMessage == 'Gagal memuat level.',
          ),
        ),
      );
      bloc.add(const LevelLoaded());
      await future;
      await bloc.close();
    });
  });
}
