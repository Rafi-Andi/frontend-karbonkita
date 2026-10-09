import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:karbon_kita_app/bloc/admin_merchant/admin_merchant_bloc.dart';
import 'package:karbon_kita_app/bloc/admin_merchant/admin_merchant_event.dart';
import 'package:karbon_kita_app/bloc/admin_merchant/admin_merchant_state.dart';
import 'package:karbon_kita_app/bloc/auth/auth_bloc.dart';
import 'package:karbon_kita_app/bloc/auth/auth_event.dart';
import 'package:karbon_kita_app/bloc/auth/auth_state.dart';
import 'package:karbon_kita_app/core/network/auth_exception.dart';
import 'package:karbon_kita_app/core/network/dio_client.dart';
import 'package:karbon_kita_app/core/network/voucher_exception.dart';
import 'package:karbon_kita_app/core/storage/token_storage.dart';
import 'package:karbon_kita_app/data/datasources/admin_merchant_remote_datasource.dart';
import 'package:karbon_kita_app/data/datasources/auth_remote_datasource.dart';
import 'package:karbon_kita_app/data/repositories/admin_merchant_repository.dart';
import 'package:karbon_kita_app/data/repositories/auth_repository.dart';
import 'package:karbon_kita_app/models/merchant_application.dart';
import 'package:karbon_kita_app/models/mitra_register_result.dart';

Map<String, dynamic> _registerJson() => {
  'user': {
    'id': 21,
    'name': 'Budi Toko',
    'phone': '+628123456700',
    'email': 'budi@toko.id',
    'role': 'mitra',
  },
  'token': '1|tokendummy',
  'mitra': {
    'id': 7,
    'nama_usaha': 'Warung Budi',
    'jenis_usaha': 'Kelontong',
    'status_verifikasi': 'pending',
    'is_active': false,
    'bank_validation_status': 'format_valid',
    'bank_validation_note': null,
    'foto_urls': {'foto_toko': null},
  },
};

Map<String, dynamic> _listEnvelope() => {
  'success': true,
  'data': {
    'current_page': 1,
    'last_page': 1,
    'per_page': 15,
    'total': 2,
    'data': [
      {
        'id': 7,
        'nama_usaha': 'Warung Budi',
        'jenis_usaha': 'Kelontong',
        'status_verifikasi': 'pending',
        'is_active': false,
        'created_at': '2026-09-20T10:00:00.000000Z',
        'user': {
          'id': 21,
          'name': 'Budi Toko',
          'email': 'budi@toko.id',
          'phone': '+628123456700',
        },
      },
      {
        'id': 8,
        'nama_usaha': 'Kopi Sore',
        'jenis_usaha': 'Kedai Kopi',
        'status_verifikasi': 'pending',
        'is_active': false,
        'created_at': '2026-09-21T10:00:00.000000Z',
        'user': {
          'id': 22,
          'name': 'Sore Coffee',
          'email': 'sore@kopi.id',
          'phone': '+628123456701',
        },
      },
    ],
  },
  'summary': {'pending': 2, 'verified': 5, 'rejected': 1},
};

Map<String, dynamic> _detailJson() => {
  'id': 7,
  'store': {
    'nama_usaha': 'Warung Budi',
    'jenis_usaha': 'Kelontong',
    'registered_at': '2026-09-20',
  },
  'verification_status': 'pending',
  'is_active': false,
  'verification_note': null,
  'owner': {
    'name': 'Budi Toko',
    'phone': '+628123456700',
    'email': 'budi@toko.id',
    'domisili': 'Surabaya, Gubeng, Mojo RT 005/RW 02',
  },
  'lokasi_usaha': {
    'alamat': 'Jl. Test 1',
    'kelurahan': 'Mojo',
    'kecamatan': 'Gubeng',
    'kota': 'Surabaya',
    'provinsi': 'Jawa Timur',
    'kode_pos': '61311',
  },
  'foto_toko': {'foto_1': null, 'foto_2': null, 'foto_3': null},
  'dokumen': {
    'nomor_ktp': '3578000000000001',
    'foto_ktp': null,
    'nomor_nib': 'NIB123',
    'foto_nib': null,
  },
  'rekening': {
    'bank': 'Bank BCA',
    'nomor_rekening': '1234567890',
    'atas_nama': 'Budi Toko',
    'bank_validation_status': 'format_valid',
    'bank_validated_at': null,
    'bank_validation_note': null,
  },
  'balance': '0.00',
};

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({this.result, this.error})
    : super(AuthRemoteDatasource(DioClient()), TokenStorage());

  MitraRegisterResult? result;
  Exception? error;

  @override
  Future<MitraRegisterResult> registerMitra({
    required Map<String, dynamic> fields,
    required Map<String, XFile?> files,
  }) async {
    if (error != null) throw error!;
    return result!;
  }
}

class FakeAdminRepository extends AdminMerchantRepository {
  FakeAdminRepository({this.page, this.detail, this.verifyResult, this.error})
    : super(AdminMerchantRemoteDatasource(DioClient()));

  MerchantApplicationPage? page;
  MerchantApplicationDetail? detail;
  MerchantVerifyResult? verifyResult;
  Exception? error;

  @override
  Future<MerchantApplicationPage> getApplications({
    String status = 'pending',
  }) async {
    if (error != null) throw error!;
    return page!;
  }

  @override
  Future<MerchantApplicationDetail> getDetail(int id) async {
    if (error != null) throw error!;
    return detail!;
  }

  @override
  Future<MerchantVerifyResult> verify({
    required int id,
    required bool approve,
    String? reason,
  }) async {
    if (error != null) throw error!;
    if (!approve && (reason == null || reason.trim().isEmpty)) {
      throw const VoucherException('Alasan penolakan wajib diisi.');
    }
    return verifyResult!;
  }
}

void main() {
  group('MitraRegisterResult parsing (kontrak register-mitra)', () {
    test('fromJson baca user + token + mitra pending', () {
      final full = MitraRegisterResult.fromJson(_registerJson());
      expect(full.user.role, 'mitra');
      expect(full.user.id, 21);
      expect(full.token, '1|tokendummy');
      expect(full.isPending, isTrue);
      expect(full.storeName, 'Warung Budi');
      expect(full.bankValidationStatus, 'format_valid');
    });
  });

  group('AuthBloc register mitra', () {
    test('sukses -> authenticated role mitra', () async {
      final bloc = AuthBloc(
        FakeAuthRepository(
          result: MitraRegisterResult.fromJson(_registerJson()),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) =>
                s.status == AuthStatus.authenticated && s.user?.role == 'mitra',
          ),
        ),
      );
      bloc.add(
        const MitraRegisterSubmitted(fields: {'name': 'Budi'}, files: {}),
      );
      await future;
      await bloc.close();
    });

    test('422 duplikat -> unauthenticated + pesan field', () async {
      final bloc = AuthBloc(
        FakeAuthRepository(
          error: const AuthException(
            'Email ini sudah terdaftar.',
            errors: {
              'email': ['Email ini sudah terdaftar.'],
            },
            statusCode: 422,
          ),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) =>
                s.status == AuthStatus.unauthenticated &&
                s.message == 'Email ini sudah terdaftar.' &&
                s.fieldErrors['email']?.first == 'Email ini sudah terdaftar.',
          ),
        ),
      );
      bloc.add(
        const MitraRegisterSubmitted(fields: {'name': 'Budi'}, files: {}),
      );
      await future;
      await bloc.close();
    });
  });

  group('MerchantApplicationPage parsing (kontrak AdminController)', () {
    test('fromEnvelope baca items + summary', () {
      final page = MerchantApplicationPage.fromEnvelope(_listEnvelope());
      expect(page.items, hasLength(2));
      expect(page.total, 2);
      expect(page.hasMore, isFalse);
      expect(page.summary.pending, 2);
      expect(page.summary.verified, 5);
      expect(page.items.first.storeName, 'Warung Budi');
      expect(page.items.first.ownerPhone, '+628123456700');
    });

    test('detail parsing baca owner + rekening', () {
      final detail = MerchantApplicationDetail.fromJson(_detailJson());
      expect(detail.ownerName, 'Budi Toko');
      expect(detail.bankName, 'Bank BCA');
      expect(detail.bankValidationStatus, 'format_valid');
      expect(detail.businessAddress, contains('Surabaya'));
      expect(detail.storePhotos, hasLength(3));
    });
  });

  group('AdminMerchantBloc antrean & verifikasi', () {
    test('Loaded -> loaded + summary', () async {
      final bloc = AdminMerchantBloc(
        FakeAdminRepository(
          page: MerchantApplicationPage.fromEnvelope(_listEnvelope()),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AdminMerchantState>(
            (s) =>
                s.status == AdminMerchantStatus.loaded &&
                s.items.length == 2 &&
                s.summary.pending == 2,
          ),
        ),
      );
      bloc.add(const AdminMerchantsLoaded(status: 'pending'));
      await future;
      await bloc.close();
    });

    test('SearchChanged memfilter client-side', () async {
      final bloc = AdminMerchantBloc(
        FakeAdminRepository(
          page: MerchantApplicationPage.fromEnvelope(_listEnvelope()),
        ),
      );
      final loaded = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AdminMerchantState>(
            (s) =>
                s.status == AdminMerchantStatus.loaded && s.items.length == 2,
          ),
        ),
      );
      bloc.add(const AdminMerchantsLoaded(status: 'pending'));
      await loaded;

      final filtered = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AdminMerchantState>(
            (s) => s.searchQuery == 'kopi' && s.filteredItems.length == 1,
          ),
        ),
      );
      bloc.add(const AdminMerchantSearchChanged('kopi'));
      await filtered;
      await bloc.close();
    });

    test('approve sukses -> success + muat ulang', () async {
      final bloc = AdminMerchantBloc(
        FakeAdminRepository(
          page: MerchantApplicationPage.fromEnvelope(_listEnvelope()),
          verifyResult: MerchantVerifyResult.fromJson({
            'id': 7,
            'store_name': 'Warung Budi',
            'verification_status': 'verified',
            'is_active': true,
          }),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AdminMerchantState>(
            (s) =>
                s.verifyStatus == AdminMerchantVerifyStatus.success &&
                s.lastResult!.approved,
          ),
        ),
      );
      bloc.add(const AdminMerchantVerifySubmitted(id: 7, approve: true));
      await future;
      await bloc.close();
    });

    test('reject tanpa alasan -> failure', () async {
      final bloc = AdminMerchantBloc(
        FakeAdminRepository(
          error: const VoucherException('Alasan penolakan wajib diisi.'),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AdminMerchantState>(
            (s) =>
                s.verifyStatus == AdminMerchantVerifyStatus.failure &&
                s.verifyErrorMessage == 'Alasan penolakan wajib diisi.',
          ),
        ),
      );
      bloc.add(const AdminMerchantVerifySubmitted(id: 7, approve: false));
      await future;
      await bloc.close();
    });

    test('409 sudah direview -> failure ramah', () async {
      final bloc = AdminMerchantBloc(
        FakeAdminRepository(
          error: const VoucherException(
            'Merchant has already been reviewed.',
            statusCode: 409,
          ),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AdminMerchantState>(
            (s) =>
                s.verifyStatus == AdminMerchantVerifyStatus.failure &&
                s.verifyErrorMessage!.contains('Sudah direview'),
          ),
        ),
      );
      bloc.add(
        const AdminMerchantVerifySubmitted(id: 7, approve: true, reason: 'ok'),
      );
      await future;
      await bloc.close();
    });

    test('401 -> isUnauthorized', () async {
      final bloc = AdminMerchantBloc(
        FakeAdminRepository(
          error: const AuthException('Unauthenticated.', statusCode: 401),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(predicate<AdminMerchantState>((s) => s.isUnauthorized)),
      );
      bloc.add(const AdminMerchantsLoaded(status: 'pending'));
      await future;
      await bloc.close();
    });
  });
}
