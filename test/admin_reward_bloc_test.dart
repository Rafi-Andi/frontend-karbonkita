import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/bloc/admin_reward/admin_reward_bloc.dart';
import 'package:karbon_kita_app/bloc/admin_reward/admin_reward_event.dart';
import 'package:karbon_kita_app/bloc/admin_reward/admin_reward_state.dart';
import 'package:karbon_kita_app/core/network/dio_client.dart';
import 'package:karbon_kita_app/core/network/voucher_exception.dart';
import 'package:karbon_kita_app/data/datasources/admin_reward_remote_datasource.dart';
import 'package:karbon_kita_app/data/repositories/admin_reward_repository.dart';
import 'package:karbon_kita_app/models/admin_reward.dart';

class FakeAdminRewardRepository extends AdminRewardRepository {
  FakeAdminRewardRepository({this.rewards = const [], this.error})
    : super(AdminRewardRemoteDatasource(DioClient()));

  List<AdminReward> rewards;
  final Map<int, AdminRewardClaimsPage> claimsByPage = {};
  Exception? error;

  @override
  Future<List<AdminReward>> getRewards() async {
    if (error != null) throw error!;
    return rewards;
  }

  @override
  Future<AdminReward> updateReward(
    int id, {
    int? stock,
    String? expiredAt,
  }) async {
    if (error != null) throw error!;
    final base = rewards.firstWhere((r) => r.id == id, orElse: () => _reward());
    return _reward(
      id: base.id,
      stock: stock ?? base.stock,
      expiredAt: expiredAt ?? base.expiredAt,
      isActive: base.isActive,
    );
  }

  @override
  Future<AdminReward> setRewardStatus(int id, bool isActive) async {
    if (error != null) throw error!;
    return _reward(id: id, isActive: isActive);
  }

  @override
  Future<AdminRewardClaimsPage> getRewardClaims(int id, {int page = 1}) async {
    if (error != null) throw error!;
    return claimsByPage[page] ?? const AdminRewardClaimsPage(items: []);
  }
}

AdminReward _reward({
  int id = 1,
  int stock = 5,
  bool isActive = true,
  String? expiredAt,
}) {
  return AdminReward(
    id: id,
    title: 'R $id',
    description: 'd',
    pointsCost: 100,
    rupiahValue: 20000,
    stock: stock,
    claimedCount: 0,
    claimsCount: 0,
    usedClaimsCount: 0,
    expiredAt: expiredAt ?? '2030-01-01',
    isActive: isActive,
    mitra: const AdminRewardMitra(id: 3, storeName: 'Warung A'),
  );
}

AdminRewardClaim _claim(String token) {
  return AdminRewardClaim(
    claimId: token.hashCode,
    qrToken: token,
    status: 'claimed',
    claimedAt: '2026-10-18T10:00:00',
    user: const AdminRewardClaimant(name: 'Ani', phone: '0812'),
  );
}

void main() {
  group('AdminReward (kontrak backend)', () {
    test('fromJson baca hitungan & label turunan', () {
      final r = AdminReward.fromJson({
        'id': 7,
        'title': 'Voucher Kopi',
        'description': 'Desc',
        'category': 'kuliner',
        'image_url': '',
        'points_cost': 500,
        'rupiah_value': '20000.00',
        'stock': 0,
        'claimed_count': 9,
        'claims_count': 12,
        'used_claims_count': 3,
        'expired_at': '2020-01-01',
        'is_active': false,
        'mitra': {
          'id': 2,
          'name': 'Budi',
          'store_name': 'Kopi Budi',
          'city': 'Bandung',
        },
      });

      expect(r.rupiahValue, 20000);
      expect(r.claimsCount, 12);
      expect(r.usedClaimsCount, 3);
      expect(r.isActive, false);
      expect(r.isExpired, true);
      expect(r.isSoldOut, true);
      expect(r.expiredAtLabel, '1 Jan 2020');
      expect(r.mitra.displayName, 'Kopi Budi');
    });

    test('claims_count null fallback ke claimed_count', () {
      final r = AdminReward.fromJson({
        'id': 1,
        'claimed_count': 4,
        'expired_at': '2030-01-01',
      });
      expect(r.claimsCount, 4);
      expect(r.isExpired, false);
    });

    test('claim: status & label kontak', () {
      final c = AdminRewardClaim.fromJson({
        'claim_id': 1,
        'qr_token': 'KBK-X',
        'status': 'used',
        'claimed_at': '2026-10-18T14:30:00',
        'used_at': '2026-10-18T15:00:00',
        'user': {
          'id': 9,
          'name': 'Ani',
          'phone': '0812',
          'rt': '03',
          'rw': '05',
        },
      });

      expect(c.statusLabel, 'Sudah dipakai');
      expect(c.user.regionLabel, 'RT 03 / RW 05');
      expect(c.claimedAtLabel, '18 Okt 2026 • 14:30');
      expect(c.usedAtLabel, '18 Okt 2026 • 15:00');
    });
  });

  group('AdminRewardBloc list & filter', () {
    test(
      'loaded tampilkan semua + filter aktif/nonaktif/kedaluwarsa',
      () async {
        final repo = FakeAdminRewardRepository(
          rewards: [
            _reward(id: 1),
            _reward(id: 2, isActive: false),
            _reward(id: 3, expiredAt: '2020-01-01'),
          ],
        );
        final b = AdminRewardBloc(repo);
        b.add(const AdminRewardsLoaded());
        await expectLater(
          b.stream,
          emitsThrough(
            predicate<AdminRewardState>(
              (s) =>
                  s.status == AdminRewardStatus.loaded && s.rewards.length == 3,
            ),
          ),
        );

        b.add(const AdminRewardsFiltered('active'));
        await expectLater(
          b.stream,
          emitsThrough(
            predicate<AdminRewardState>(
              (s) =>
                  s.filter == 'active' &&
                  s.filteredRewards.length == 1 &&
                  s.filteredRewards.first.id == 1,
            ),
          ),
        );

        b.add(const AdminRewardsFiltered('inactive'));
        await expectLater(
          b.stream,
          emitsThrough(
            predicate<AdminRewardState>(
              (s) => s.filteredRewards.single.id == 2,
            ),
          ),
        );

        b.add(const AdminRewardsFiltered('expired'));
        await expectLater(
          b.stream,
          emitsThrough(
            predicate<AdminRewardState>(
              (s) => s.filteredRewards.single.id == 3,
            ),
          ),
        );

        b.add(const AdminRewardsFiltered(null));
        await expectLater(
          b.stream,
          emitsThrough(
            predicate<AdminRewardState>(
              (s) => s.filter == null && s.filteredRewards.length == 3,
            ),
          ),
        );
        await b.close();
      },
    );
  });

  group('AdminRewardBloc submit', () {
    test('toggle status sukses -> success + reload', () async {
      final repo = FakeAdminRewardRepository(rewards: [_reward(id: 1)]);
      final b = AdminRewardBloc(repo);
      final expectation = expectLater(
        b.stream,
        emitsInOrder([
          predicate<AdminRewardState>(
            (s) => s.submitStatus == AdminRewardSubmitStatus.submitting,
          ),
          predicate<AdminRewardState>(
            (s) =>
                s.submitStatus == AdminRewardSubmitStatus.success &&
                s.submitMessage != null &&
                s.lastReward?.isActive == false,
          ),
          // Reload otomatis setelah sukses.
          predicate<AdminRewardState>(
            (s) => s.status == AdminRewardStatus.loading,
          ),
          predicate<AdminRewardState>(
            (s) => s.status == AdminRewardStatus.loaded,
          ),
        ]),
      );
      b.add(const AdminRewardStatusSubmitted(id: 1, isActive: false));
      await expectation;
      await b.close();
    });

    test('422 saat ubah stok -> failure + submitErrors utuh', () async {
      final repo = FakeAdminRewardRepository(
        error: const VoucherException(
          'Validation failed.',
          errors: {
            'stock': ['Stok maksimal 10000.'],
          },
          statusCode: 422,
        ),
      );
      final b = AdminRewardBloc(repo);
      b.add(const AdminRewardUpdateSubmitted(id: 1, stock: 99999));
      await expectLater(
        b.stream,
        emitsThrough(
          predicate<AdminRewardState>(
            (s) =>
                s.submitStatus == AdminRewardSubmitStatus.failure &&
                s.submitErrors['stock']?.isNotEmpty == true,
          ),
        ),
      );
      await b.close();
    });
  });

  group('AdminRewardBloc claims (paginasi)', () {
    test('halaman 1 lalu Muat lebih banyak append halaman 2', () async {
      final repo = FakeAdminRewardRepository(rewards: [_reward(id: 1)]);
      repo.claimsByPage[1] = AdminRewardClaimsPage(
        items: [_claim('KBK-1')],
        currentPage: 1,
        lastPage: 2,
        total: 2,
      );
      repo.claimsByPage[2] = AdminRewardClaimsPage(
        items: [_claim('KBK-2')],
        currentPage: 2,
        lastPage: 2,
        total: 2,
      );

      final b = AdminRewardBloc(repo);
      b.add(const AdminRewardClaimsLoaded(1));
      await expectLater(
        b.stream,
        emitsThrough(
          predicate<AdminRewardState>(
            (s) =>
                s.claimsStatus == AdminRewardClaimsStatus.loaded &&
                s.claims.length == 1 &&
                s.hasMoreClaims,
          ),
        ),
      );

      b.add(const AdminRewardClaimsNextPage());
      await expectLater(
        b.stream,
        emitsThrough(
          predicate<AdminRewardState>(
            (s) =>
                s.claimsStatus == AdminRewardClaimsStatus.loaded &&
                s.claims.length == 2 &&
                !s.hasMoreClaims &&
                s.claimsTotal == 2,
          ),
        ),
      );
      await b.close();
    });
  });
}
