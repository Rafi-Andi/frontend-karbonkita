import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/bloc/admin_campaign/admin_campaign_bloc.dart';
import 'package:karbon_kita_app/bloc/admin_campaign/admin_campaign_event.dart';
import 'package:karbon_kita_app/bloc/admin_campaign/admin_campaign_state.dart';
import 'package:karbon_kita_app/bloc/donation/donation_bloc.dart';
import 'package:karbon_kita_app/bloc/donation/donation_event.dart';
import 'package:karbon_kita_app/bloc/donation/donation_state.dart';
import 'package:karbon_kita_app/core/network/auth_exception.dart';
import 'package:karbon_kita_app/core/network/dio_client.dart';
import 'package:karbon_kita_app/core/network/voucher_exception.dart';
import 'package:karbon_kita_app/data/datasources/donation_remote_datasource.dart';
import 'package:karbon_kita_app/data/repositories/donation_repository.dart';
import 'package:karbon_kita_app/models/donation.dart';

Map<String, dynamic> _campaignJson({int id = 3, String status = 'active'}) => {
  'id': id,
  'title': 'Sembako Gratis Warga',
  'slug': 'sembako-gratis-warga-abc123',
  'image_url': '',
  'target_amount': '5000000.00',
  'collected_amount': '2500000.00',
  'available_amount': '2000000.00',
  'progress_percent': 50.0,
  'status': status,
  'is_open': true,
  'ended_at': '2027-01-01T00:00:00',
};

Map<String, dynamic> _detailJson() => {
  ..._campaignJson(),
  'description': 'Bagi sembako untuk warga terdampak.',
  'donor_count': 2,
  'top_donors': [
    {'payer_name': 'Hendra', 'total': '300000.00', 'tier': 'Donatur Perak'},
  ],
  'recent_donations': [
    {
      'payer_name': 'Hendra',
      'amount': '100000.00',
      'paid_at': '2026-09-20T10:00:00',
    },
  ],
};

Map<String, dynamic> _inventoryJson() => {
  'donations': [
    {
      'id': 11,
      'campaign': {'id': 3, 'title': 'Sembako', 'slug': 'sembako-x'},
      'amount': '50000.00',
      'status': 'pending',
      'invoice_url': 'https://pay.xendit.co/inv-1',
      'paid_at': null,
      'payment_channel': null,
    },
    {
      'id': 10,
      'campaign': {'id': 3, 'title': 'Sembako', 'slug': 'sembako-x'},
      'amount': '60000.00',
      'status': 'paid',
      'invoice_url': null,
      'paid_at': '2026-09-19T10:00:00',
      'payment_channel': 'QRIS',
    },
  ],
  'lifetime_total': '60000.00',
  'tier': 'Donatur Perunggu',
};

class FakeDonationRepository extends DonationRepository {
  FakeDonationRepository({
    this.campaigns,
    this.detail,
    this.create,
    this.inventory,
    this.error,
  }) : super(DonationRemoteDatasource(DioClient()));

  List<DonationCampaign>? campaigns;
  DonationCampaign? detail;
  CreateDonationResult? create;
  MyDonationInventory? inventory;
  Exception? error;

  @override
  Future<List<DonationCampaign>> getCampaigns() async {
    if (error != null) throw error!;
    return campaigns!;
  }

  @override
  Future<DonationCampaign> getCampaignDetail(String slug) async {
    if (error != null) throw error!;
    return detail!;
  }

  @override
  Future<CreateDonationResult> createDonation({
    required int campaignId,
    required int amount,
    String? payerName,
  }) async {
    if (error != null) throw error!;
    return create!;
  }

  @override
  Future<MyDonationInventory> getMyDonations() async {
    if (error != null) throw error!;
    return inventory!;
  }

  @override
  Future<void> cancelDonation(int id) async {
    if (error != null) throw error!;
  }

  @override
  Future<List<DonationCampaign>> getAdminCampaigns() async {
    if (error != null) throw error!;
    return campaigns!;
  }

  @override
  Future<Map<String, dynamic>> createCampaign(
    Map<String, dynamic> fields,
  ) async {
    if (error != null) throw error!;
    return {'id': 9, 'slug': 'baru-x', 'status': 'draft'};
  }

  @override
  Future<Map<String, dynamic>> updateCampaign(
    int id,
    Map<String, dynamic> fields,
  ) async {
    if (error != null) throw error!;
    return {'id': id, 'slug': 'x', 'status': fields['status'] ?? 'active'};
  }

  @override
  Future<FundedVoucherResult> createFundedVoucher(
    Map<String, dynamic> fields,
  ) async {
    if (error != null) throw error!;
    return FundedVoucherResult.fromJson({
      'voucher_id': 42,
      'campaign_id': 3,
      'allocated_amount': '200000.00',
      'campaign_available': '1800000.00',
    });
  }
}

void main() {
  group('DonationCampaign parsing (kontrak DonationController)', () {
    test('fromJson baca summary + angka String', () {
      final campaign = DonationCampaign.fromJson(_campaignJson());

      expect(campaign.title, 'Sembako Gratis Warga');
      expect(campaign.targetAmount, 5000000.0);
      expect(campaign.collectedAmount, 2500000.0);
      expect(campaign.availableAmount, 2000000.0);
      expect(campaign.progressPercent, 50.0);
      expect(campaign.isOpen, isTrue);
    });

    test('detail parsing baca donors + recent', () {
      final detail = DonationCampaign.fromJson(_detailJson());

      expect(detail.description, contains('sembako'));
      expect(detail.donorCount, 2);
      expect(detail.topDonors.first.tier, 'Donatur Perak');
      expect(detail.recentDonations.first.amount, 100000.0);
    });

    test('inventory parsing + status helper', () {
      final inventory = MyDonationInventory.fromJson(_inventoryJson());

      expect(inventory.donations, hasLength(2));
      expect(inventory.lifetimeTotal, 60000.0);
      expect(inventory.tier, 'Donatur Perunggu');
      expect(inventory.donations.first.isPending, isTrue);
      expect(inventory.donations.first.invoiceUrl, contains('xendit'));
      expect(inventory.donations.last.isPaid, isTrue);
    });

    test('CreateDonationResult parsing invoice', () {
      final result = CreateDonationResult.fromJson({
        'donation_id': 11,
        'external_id': 'KBK-DON-11',
        'amount': '50000.00',
        'invoice_url': 'https://pay.xendit.co/inv-1',
        'expires_at': '2026-09-21T10:00:00',
      });
      expect(result.invoiceUrl, contains('xendit'));
      expect(result.amount, 50000.0);
    });
  });

  group('DonationBloc katalog & donasi', () {
    test('CampaignsLoaded -> loaded', () async {
      final bloc = DonationBloc(
        FakeDonationRepository(
          campaigns: [DonationCampaign.fromJson(_campaignJson())],
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DonationState>(
            (s) => s.status == DonationStatus.loaded && s.campaigns.length == 1,
          ),
        ),
      );
      bloc.add(const DonationCampaignsLoaded());
      await future;
      await bloc.close();
    });

    test('tanpa force tidak muat ulang; force muat ulang', () async {
      final bloc = DonationBloc(
        FakeDonationRepository(
          campaigns: [DonationCampaign.fromJson(_campaignJson())],
        ),
      );
      final loaded = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DonationState>((s) => s.status == DonationStatus.loaded),
        ),
      );
      bloc.add(const DonationCampaignsLoaded());
      await loaded;

      // Tanpa force: tidak ada state loading baru (early return).
      var sawLoading = false;
      final sub = bloc.stream.listen((s) {
        if (s.status == DonationStatus.loading) sawLoading = true;
      });
      bloc.add(const DonationCampaignsLoaded());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await sub.cancel();
      expect(sawLoading, isFalse);

      // Dengan force: loading + loaded lagi.
      final reloaded = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DonationState>(
            (s) => s.status == DonationStatus.loaded && s.campaigns.length == 1,
          ),
        ),
      );
      bloc.add(const DonationCampaignsLoaded(force: true));
      await reloaded;
      await bloc.close();
    });

    test('create sukses -> success + invoice', () async {
      final bloc = DonationBloc(
        FakeDonationRepository(
          create: CreateDonationResult.fromJson({
            'donation_id': 11,
            'external_id': 'KBK-DON-11',
            'amount': '50000.00',
            'invoice_url': 'https://pay.xendit.co/inv-1',
            'expires_at': '2026-09-21T10:00:00',
          }),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DonationState>(
            (s) =>
                s.createStatus == DonationCreateStatus.success &&
                s.lastCreate?.invoiceUrl.contains('xendit') == true,
          ),
        ),
      );
      bloc.add(const DonationCreateSubmitted(campaignId: 3, amount: 50000));
      await future;
      await bloc.close();
    });

    test('create campaign tutup (422) -> failure + pesan', () async {
      final bloc = DonationBloc(
        FakeDonationRepository(
          error: const VoucherException(
            'Campaign is not open for donations.',
            statusCode: 422,
          ),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DonationState>(
            (s) =>
                s.createStatus == DonationCreateStatus.failure &&
                s.createErrorMessage!.contains('not open'),
          ),
        ),
      );
      bloc.add(const DonationCreateSubmitted(campaignId: 3, amount: 50000));
      await future;
      await bloc.close();
    });

    test('MyLoaded -> inventory + cancel refresh', () async {
      final bloc = DonationBloc(
        FakeDonationRepository(
          inventory: MyDonationInventory.fromJson(_inventoryJson()),
        ),
      );
      final loaded = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DonationState>(
            (s) =>
                s.inventoryStatus == DonationStatus.loaded &&
                s.inventory?.donations.length == 2,
          ),
        ),
      );
      bloc.add(const MyDonationsLoaded());
      await loaded;

      final cancelled = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<DonationState>(
            (s) => s.cancelStatus == DonationCancelStatus.success,
          ),
        ),
      );
      bloc.add(const DonationCancelSubmitted(11));
      await cancelled;
      await bloc.close();
    });

    test('401 -> isUnauthorized', () async {
      final bloc = DonationBloc(
        FakeDonationRepository(
          error: const AuthException('Unauthenticated.', statusCode: 401),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(predicate<DonationState>((s) => s.isUnauthorized)),
      );
      bloc.add(const MyDonationsLoaded());
      await future;
      await bloc.close();
    });
  });

  group('AdminCampaignBloc campaign & voucher', () {
    test('Loaded -> loaded semua status', () async {
      final bloc = AdminCampaignBloc(
        FakeDonationRepository(
          campaigns: [
            DonationCampaign.fromJson(_campaignJson(status: 'draft')),
            DonationCampaign.fromJson(_campaignJson(id: 4)),
          ],
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AdminCampaignState>(
            (s) =>
                s.status == AdminCampaignStatus.loaded &&
                s.campaigns.length == 2,
          ),
        ),
      );
      bloc.add(const AdminCampaignsLoaded());
      await future;
      await bloc.close();
    });

    test('create campaign sukses -> success + reload', () async {
      final bloc = AdminCampaignBloc(
        FakeDonationRepository(
          campaigns: [DonationCampaign.fromJson(_campaignJson())],
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AdminCampaignState>(
            (s) =>
                s.submitStatus == AdminCampaignSubmitStatus.success &&
                s.lastCampaign?['id'] == 9,
          ),
        ),
      );
      bloc.add(
        const AdminCampaignCreateSubmitted({
          'title': 'Baru',
          'description': 'Desc',
          'target_amount': 1000000,
        }),
      );
      await future;
      await bloc.close();
    });

    test('voucher dana kurang diterjemahkan ke rupiah Indonesia', () async {
      final bloc = AdminCampaignBloc(
        FakeDonationRepository(
          error: const VoucherException(
            'Insufficient campaign funds. Needed 2000000.00, available 50000.00.',
            statusCode: 422,
          ),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AdminCampaignState>(
            (s) =>
                s.submitStatus == AdminCampaignSubmitStatus.failure &&
                s.submitErrorMessage!.contains('Rp 2.000.000') &&
                s.submitErrorMessage!.contains('Rp 50.000'),
          ),
        ),
      );
      bloc.add(const AdminVoucherCreateSubmitted({'campaign_id': 3}));
      await future;
      await bloc.close();
    });

    test('voucher sukses -> FundedVoucherResult', () async {
      final bloc = AdminCampaignBloc(
        FakeDonationRepository(
          campaigns: [DonationCampaign.fromJson(_campaignJson())],
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AdminCampaignState>(
            (s) =>
                s.submitStatus == AdminCampaignSubmitStatus.success &&
                s.lastVoucher?.voucherId == 42,
          ),
        ),
      );
      bloc.add(const AdminVoucherCreateSubmitted({'campaign_id': 3}));
      await future;
      await bloc.close();
    });

    test('403 non-admin -> isUnauthorized', () async {
      final bloc = AdminCampaignBloc(
        FakeDonationRepository(
          error: const AuthException('Forbidden.', statusCode: 403),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(predicate<AdminCampaignState>((s) => s.isUnauthorized)),
      );
      bloc.add(const AdminCampaignsLoaded());
      await future;
      await bloc.close();
    });
  });
}
