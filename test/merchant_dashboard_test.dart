import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/bloc/merchant/merchant_bloc.dart';
import 'package:karbon_kita_app/bloc/merchant/merchant_event.dart';
import 'package:karbon_kita_app/bloc/merchant/merchant_state.dart';
import 'package:karbon_kita_app/core/network/auth_exception.dart';
import 'package:karbon_kita_app/core/network/dio_client.dart';
import 'package:karbon_kita_app/core/network/voucher_exception.dart';
import 'package:karbon_kita_app/data/datasources/merchant_remote_datasource.dart';
import 'package:karbon_kita_app/data/repositories/merchant_repository.dart';
import 'package:karbon_kita_app/models/merchant_dashboard.dart';

Map<String, dynamic> _dashboardJson({bool isOpen = true}) => {
  'store_name': 'Bakery & Cafe Nusantara',
  'verification_status': 'verified',
  'is_open': isOpen,
  'can_redeem': isOpen,
  'balance': '1450000.00',
  'stats': {
    'total_vouchers': 5,
    'active_vouchers': 3,
    'total_redeemed': 12,
    'total_disbursed': '1450000.00',
  },
  'recent_disbursements': [
    {
      'id': 1,
      'voucher_claim_id': 11,
      'amount': '20000.00',
      'status': 'completed',
      'raw_status': 'SUCCEEDED',
      'payout_id': 'po-123',
      'reference_id': 'KBK-CLAIM-11',
      'xendit_disbursement_id': 'po-123',
      'failure_code': null,
      'processed_at': '2026-09-20T10:24:00',
    },
  ],
};

Map<String, dynamic> _redeemJson() => {
  'claim_id': 11,
  'qr_token': 'KBK-ABC-DEF',
  'voucher_title': 'Voucher Diskon Rp 20.000',
  'amount': '20000.00',
  'new_balance': '1470000.00',
  'xendit_payout_id': 'po-123',
  'reference_id': 'KBK-CLAIM-11',
  'disbursement_status': 'completed',
  'disbursement_id': 1,
};

class FakeMerchantRepository extends MerchantRepository {
  FakeMerchantRepository({
    this.dashboard,
    this.redeemResult,
    this.historyPage,
    this.error,
  }) : super(MerchantRemoteDatasource(DioClient()));

  MerchantDashboard? dashboard;
  RedeemResult? redeemResult;
  DisbursementHistoryPage? historyPage;
  Exception? error;

  @override
  Future<MerchantDashboard> getDashboard() async {
    if (error != null) throw error!;
    return dashboard!;
  }

  @override
  Future<({MerchantDashboard? dashboard, DateTime? savedAt})>
  getCachedDashboard() async {
    // BLoC cache-first: kosongkan agar alur online teruji deterministik.
    return (dashboard: null, savedAt: null);
  }

  @override
  Future<bool> updateStatus({required bool isOpen}) async {
    if (error != null) throw error!;
    return isOpen;
  }

  @override
  Future<RedeemResult> redeem({required String uniqueCode}) async {
    if (error != null) throw error!;
    if (uniqueCode.trim().isEmpty) {
      throw const VoucherException('Masukkan nomor token voucher.');
    }
    return redeemResult!;
  }

  @override
  Future<DisbursementHistoryPage> getDisbursements({
    String status = 'all',
    int page = 1,
  }) async {
    if (error != null) throw error!;
    return historyPage!;
  }
}

Map<String, dynamic> _historyItemJson({String status = 'completed'}) => {
  'id': 1,
  'voucher_claim_id': 11,
  'amount': '20000.00',
  'status': status,
  'raw_status': 'SUCCEEDED',
  'payout_id': 'po-123',
  'reference_id': 'KBK-CLAIM-11',
  'bank_name': 'Bank BCA',
  'bank_account_number': '1234567890',
  'bank_account_name': 'Warung Test',
  'failure_code': null,
  'failure_reason': null,
  'processed_at': '2026-09-20T10:24:00',
  'warga_name': 'Budi Warga',
  'warga_rt': '005',
  'warga_rw': '02',
  'voucher_title': 'Voucher Diskon Rp 20.000',
};

void main() {
  group('MerchantDashboard parsing (kontrak MerchantController)', () {
    test('fromJson baca store, balance String, stats, recent', () {
      final dashboard = MerchantDashboard.fromJson(_dashboardJson());

      expect(dashboard.storeName, 'Bakery & Cafe Nusantara');
      expect(dashboard.isVerified, isTrue);
      expect(dashboard.isOpen, isTrue);
      expect(dashboard.canRedeem, isTrue);
      expect(dashboard.balance, 1450000.0);
      expect(dashboard.stats.totalRedeemed, 12);
      expect(dashboard.stats.totalDisbursed, 1450000.0);
      expect(dashboard.recent, hasLength(1));
      expect(dashboard.recent.first.voucherClaimId, 11);
      expect(dashboard.redeemStatusSafe, isTrue);
    });

    test('toko tutup -> canRedeem false di model mentah', () {
      final dashboard = MerchantDashboard.fromJson(
        _dashboardJson(isOpen: false),
      );
      expect(dashboard.isOpen, isFalse);
      expect(dashboard.canRedeem, isFalse);
    });

    test('RedeemResult parsing + isCompleted', () {
      final result = RedeemResult.fromJson(_redeemJson());
      expect(result.qrToken, 'KBK-ABC-DEF');
      expect(result.amount, 20000.0);
      expect(result.isCompleted, isTrue);
      expect(result.referenceId, 'KBK-CLAIM-11');
    });

    test('RedeemResult pending -> isCompleted false', () {
      final result = RedeemResult.fromJson({
        ..._redeemJson(),
        'disbursement_status': 'pending',
      });
      expect(result.isCompleted, isFalse);
    });
  });

  group('MerchantBloc dashboard & toggle', () {
    test('MerchantLoaded -> loaded + dashboard', () async {
      final bloc = MerchantBloc(
        FakeMerchantRepository(
          dashboard: MerchantDashboard.fromJson(_dashboardJson()),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MerchantState>(
            (s) =>
                s.status == MerchantStatus.loaded &&
                s.dashboard?.storeName == 'Bakery & Cafe Nusantara',
          ),
        ),
      );
      bloc.add(const MerchantLoaded());
      await future;
      await bloc.close();
    });

    test('MerchantStatusToggled(false) -> toko tutup', () async {
      final bloc = MerchantBloc(
        FakeMerchantRepository(
          dashboard: MerchantDashboard.fromJson(_dashboardJson()),
        ),
      );
      final loaded = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MerchantState>(
            (s) => s.status == MerchantStatus.loaded && s.dashboard != null,
          ),
        ),
      );
      bloc.add(const MerchantLoaded());
      await loaded;

      final toggled = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MerchantState>(
            (s) =>
                s.dashboard?.isOpen == false &&
                s.dashboard?.canRedeem == false &&
                s.isToggling == false,
          ),
        ),
      );
      bloc.add(const MerchantStatusToggled(false));
      await toggled;
      await bloc.close();
    });

    test('401 dashboard -> isUnauthorized (UI wajib logout)', () async {
      final bloc = MerchantBloc(
        FakeMerchantRepository(
          error: const AuthException('Unauthenticated.', statusCode: 401),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(predicate<MerchantState>((s) => s.isUnauthorized)),
      );
      bloc.add(const MerchantLoaded());
      await future;
      await bloc.close();
    });
  });

  group('MerchantBloc redeem', () {
    test('redeem sukses -> success + lastRedeem', () async {
      final bloc = MerchantBloc(
        FakeMerchantRepository(
          dashboard: MerchantDashboard.fromJson(_dashboardJson()),
          redeemResult: RedeemResult.fromJson(_redeemJson()),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MerchantState>(
            (s) =>
                s.redeemStatus == MerchantRedeemStatus.success &&
                s.lastRedeem?.qrToken == 'KBK-ABC-DEF',
          ),
        ),
      );
      bloc.add(const MerchantRedeemSubmitted('KBK-ABC-DEF'));
      await future;
      await bloc.close();
    });

    test('redeem 409 (sudah dicairkan) -> failure + pesan', () async {
      final bloc = MerchantBloc(
        FakeMerchantRepository(
          error: const VoucherException(
            'Voucher has already been redeemed.',
            statusCode: 409,
          ),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MerchantState>(
            (s) =>
                s.redeemStatus == MerchantRedeemStatus.failure &&
                s.redeemErrorMessage != null &&
                s.redeemErrorMessage!.contains('sudah pernah dicairkan'),
          ),
        ),
      );
      bloc.add(const MerchantRedeemSubmitted('KBK-ABC-DEF'));
      await future;
      await bloc.close();
    });

    test('redeem 404 -> failure + pesan tidak ditemukan', () async {
      final bloc = MerchantBloc(
        FakeMerchantRepository(
          error: const VoucherException(
            'Voucher code not found.',
            statusCode: 404,
          ),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MerchantState>(
            (s) =>
                s.redeemStatus == MerchantRedeemStatus.failure &&
                s.redeemErrorMessage != null &&
                s.redeemErrorMessage!.contains('tidak ditemukan'),
          ),
        ),
      );
      bloc.add(const MerchantRedeemSubmitted('KBK-XXX-YYY'));
      await future;
      await bloc.close();
    });

    test('MerchantRedeemReset -> kembali idle', () async {
      final bloc = MerchantBloc(
        FakeMerchantRepository(
          dashboard: MerchantDashboard.fromJson(_dashboardJson()),
          redeemResult: RedeemResult.fromJson(_redeemJson()),
        ),
      );
      final success = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MerchantState>(
            (s) => s.redeemStatus == MerchantRedeemStatus.success,
          ),
        ),
      );
      bloc.add(const MerchantRedeemSubmitted('KBK-ABC-DEF'));
      await success;

      final reset = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MerchantState>(
            (s) =>
                s.redeemStatus == MerchantRedeemStatus.idle &&
                s.lastRedeem == null,
          ),
        ),
      );
      bloc.add(const MerchantRedeemReset());
      await reset;
      await bloc.close();
    });
  });

  group('Disbursement history (GET /merchant/disbursements)', () {
    test('page parsing baca item + meta', () {
      final page = DisbursementHistoryPage.fromJson(
        {
          'data': [_historyItemJson()],
        },
        {'current_page': 1, 'last_page': 3, 'total': 31},
      );

      expect(page.items, hasLength(1));
      expect(page.items.first.wargaName, 'Budi Warga');
      expect(page.items.first.wargaRt, '005');
      expect(page.items.first.voucherTitle, 'Voucher Diskon Rp 20.000');
      expect(page.items.first.amount, 20000.0);
      expect(page.items.first.isCompleted, isTrue);
      expect(page.total, 31);
      expect(page.hasMore, isTrue);
    });

    test('MerchantDisbursementsLoaded -> loaded + items', () async {
      final bloc = MerchantBloc(
        FakeMerchantRepository(
          historyPage: DisbursementHistoryPage.fromJson(
            {
              'data': [_historyItemJson()],
            },
            {'current_page': 1, 'last_page': 1, 'total': 1},
          ),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MerchantState>(
            (s) =>
                s.historyStatus == DisbursementHistoryStatus.loaded &&
                s.historyItems.length == 1 &&
                s.historyItems.first.isCompleted,
          ),
        ),
      );
      bloc.add(const MerchantDisbursementsLoaded());
      await future;
      await bloc.close();
    });

    test('loadMore menambahkan item, bukan menimpa', () async {
      final first = DisbursementHistoryPage.fromJson(
        {
          'data': [_historyItemJson()],
        },
        {'current_page': 1, 'last_page': 2, 'total': 2},
      );
      final repo = FakeMerchantRepository(historyPage: first);
      final bloc = MerchantBloc(repo);

      final loaded = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MerchantState>(
            (s) =>
                s.historyStatus == DisbursementHistoryStatus.loaded &&
                s.historyItems.length == 1,
          ),
        ),
      );
      bloc.add(const MerchantDisbursementsLoaded());
      await loaded;

      repo.historyPage = DisbursementHistoryPage.fromJson(
        {
          'data': [_historyItemJson(status: 'failed')],
        },
        {'current_page': 2, 'last_page': 2, 'total': 2},
      );

      final more = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MerchantState>(
            (s) =>
                s.historyStatus == DisbursementHistoryStatus.loaded &&
                s.historyItems.length == 2 &&
                s.historyPage == 2,
          ),
        ),
      );
      bloc.add(const MerchantDisbursementsLoaded(loadMore: true));
      await more;
      await bloc.close();
    });

    test('gagal muat riwayat -> status error + pesan', () async {
      final bloc = MerchantBloc(
        FakeMerchantRepository(
          error: const VoucherException('Gagal memuat riwayat pencairan: X'),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MerchantState>(
            (s) =>
                s.historyStatus == DisbursementHistoryStatus.error &&
                s.historyError != null,
          ),
        ),
      );
      bloc.add(const MerchantDisbursementsLoaded());
      await future;
      await bloc.close();
    });
  });
}

/// Helper khusus test: dashboard fresh selalu bisa redeem.
extension on MerchantDashboard {
  bool get redeemStatusSafe => canRedeem && isOpen && isVerified;
}
