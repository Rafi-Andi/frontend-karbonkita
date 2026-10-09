import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/bloc/voucher/voucher_bloc.dart';
import 'package:karbon_kita_app/bloc/voucher/voucher_event.dart';
import 'package:karbon_kita_app/bloc/voucher/voucher_state.dart';
import 'package:karbon_kita_app/core/network/auth_exception.dart';
import 'package:karbon_kita_app/core/network/dio_client.dart';
import 'package:karbon_kita_app/core/network/voucher_exception.dart';
import 'package:karbon_kita_app/data/datasources/voucher_remote_datasource.dart';
import 'package:karbon_kita_app/data/repositories/voucher_repository.dart';
import 'package:karbon_kita_app/models/my_voucher.dart';
import 'package:karbon_kita_app/models/voucher.dart';

Map<String, dynamic> _claimJson({
  int claimId = 11,
  String status = 'claimed',
  String qrToken = 'KBK-ABC-DEF',
}) => {
  'claim_id': claimId,
  'qr_token': qrToken,
  'status': status,
  'claimed_at': '2026-09-10T10:00:00',
  'used_at': null,
  'voucher': {
    'id': 5,
    'title': 'Diskon Kopi 15rb',
    'description': 'Potongan Rp 15.000',
    'image_url': '',
    'rupiah_value': '15000.00',
    'expired_at': '2026-12-31',
  },
  'mitra': {'store_name': 'Kedai Kopi', 'name': 'Budi'},
};

Map<String, dynamic> _inventoryJson() => {
  'active': [_claimJson()],
  'used': [_claimJson(claimId: 12, status: 'used')],
  'expired': [_claimJson(claimId: 13, status: 'expired')],
};

const _voucherJson = {
  'id': 5,
  'title': 'Diskon Kopi 15rb',
  'description': 'Potongan Rp 15.000',
  'image_url': '',
  'points_cost': 300,
  'rupiah_value': '15000.00',
  'stock': 9,
  'claimed_count': 1,
  'expired_at': '2026-12-31',
  'is_active': true,
  'mitra': {'name': 'Budi', 'store_name': 'Kedai Kopi'},
};

class FakeVoucherRepository extends VoucherRepository {
  FakeVoucherRepository({this.inventory, this.claim, this.error})
    : super(VoucherRemoteDatasource(DioClient()));

  MyVoucherInventory? inventory;
  ClaimResult? claim;
  Exception? error;

  @override
  Future<List<Voucher>> getVouchers({String? category, String? city}) async {
    if (error != null) throw error!;
    return [Voucher.fromJson(_voucherJson)];
  }

  @override
  Future<int> getEcoPoints() async {
    if (error != null) throw error!;
    return 950;
  }

  @override
  Future<MyVoucherInventory> getMyVouchers() async {
    if (error != null) throw error!;
    return inventory!;
  }

  @override
  Future<ClaimResult> claimVoucher({required int voucherId}) async {
    if (error != null) throw error!;
    return claim!;
  }
}

void main() {
  group('MyVoucherInventory parsing (kontrak VoucherClaimResource)', () {
    test('fromJson baca active/used/expired', () {
      final inv = MyVoucherInventory.fromJson(_inventoryJson());

      expect(inv.active, hasLength(1));
      expect(inv.used, hasLength(1));
      expect(inv.expired, hasLength(1));

      final active = inv.active.first;
      expect(active.qrToken, 'KBK-ABC-DEF');
      expect(active.isActive, isTrue);
      expect(active.title, 'Diskon Kopi 15rb');
      // rupiah String tetap terparse.
      expect(active.rupiahValue, 15000.0);
      expect(active.storeName, 'Kedai Kopi');
      expect(inv.used.first.isUsed, isTrue);
    });

    test('ClaimResult parsing', () {
      final result = ClaimResult.fromJson({
        'claim_id': 11,
        'qr_token': 'KBK-ABC-DEF',
        'voucher_title': 'Diskon Kopi 15rb',
        'points_cost': 300,
        'remaining_points': 950,
      });
      expect(result.qrToken, 'KBK-ABC-DEF');
      expect(result.remainingPoints, 950);
    });
  });

  group('VoucherBloc dompet & klaim', () {
    test('MyVouchersLoaded -> inventory loaded', () async {
      final bloc = VoucherBloc(
        FakeVoucherRepository(
          inventory: MyVoucherInventory.fromJson(_inventoryJson()),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<VoucherState>(
            (s) =>
                s.inventoryStatus == InventoryStatus.loaded &&
                s.myVouchers?.active.length == 1,
          ),
        ),
      );
      bloc.add(const MyVouchersLoaded());
      await future;
      await bloc.close();
    });

    test('klaim sukses -> success + saldo & stok dimuat ulang', () async {
      final bloc = VoucherBloc(
        FakeVoucherRepository(
          inventory: MyVoucherInventory.fromJson(_inventoryJson()),
          claim: ClaimResult.fromJson({
            'claim_id': 11,
            'qr_token': 'KBK-ABC-DEF',
            'voucher_title': 'Diskon Kopi 15rb',
            'points_cost': 300,
            'remaining_points': 950,
          }),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<VoucherState>(
            (s) =>
                s.claimStatus == ClaimStatus.success &&
                s.lastClaim?.qrToken == 'KBK-ABC-DEF' &&
                s.ecoPoints == 950 &&
                s.myVouchers?.active.length == 1,
          ),
        ),
      );
      bloc.add(const VoucherClaimSubmitted(5));
      await future;
      await bloc.close();
    });

    test('klaim gagal (poin kurang) -> failure + pesan', () async {
      final bloc = VoucherBloc(
        FakeVoucherRepository(
          error: const VoucherException(
            'Insufficient eco points. You need 300 points.',
          ),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<VoucherState>(
            (s) =>
                s.claimStatus == ClaimStatus.failure &&
                s.claimErrorMessage != null &&
                s.claimErrorMessage!.contains('Insufficient'),
          ),
        ),
      );
      bloc.add(const VoucherClaimSubmitted(5));
      await future;
      await bloc.close();
    });

    test('VouchersLoaded(category) -> vouchers + selectedCategory', () async {
      final bloc = VoucherBloc(FakeVoucherRepository());
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<VoucherState>(
            (s) =>
                s.status == VoucherStatus.loaded &&
                s.selectedCategory == 'fashion' &&
                s.vouchers.length == 1,
          ),
        ),
      );
      bloc.add(const VouchersLoaded(category: 'fashion'));
      await future;
      await bloc.close();
    });

    test('Voucher.fromJson tanpa category -> default kuliner', () {
      final voucher = Voucher.fromJson(_voucherJson);
      expect(voucher.category, 'kuliner');
      final withCategory = Voucher.fromJson({
        ..._voucherJson,
        'category': 'donasi',
      });
      expect(withCategory.category, 'donasi');
    });

    test('401 dompet -> isUnauthorized (UI wajib logout)', () async {
      final bloc = VoucherBloc(
        FakeVoucherRepository(
          error: const AuthException('Unauthenticated.', statusCode: 401),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(predicate<VoucherState>((s) => s.isUnauthorized)),
      );
      bloc.add(const MyVouchersLoaded());
      await future;
      await bloc.close();
    });
  });
}
