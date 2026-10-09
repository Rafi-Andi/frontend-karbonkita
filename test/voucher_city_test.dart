import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/bloc/voucher/voucher_bloc.dart';
import 'package:karbon_kita_app/bloc/voucher/voucher_event.dart';
import 'package:karbon_kita_app/bloc/voucher/voucher_state.dart';
import 'package:karbon_kita_app/core/network/dio_client.dart';
import 'package:karbon_kita_app/data/datasources/voucher_remote_datasource.dart';
import 'package:karbon_kita_app/data/repositories/voucher_repository.dart';
import 'package:karbon_kita_app/models/dashboard.dart';
import 'package:karbon_kita_app/models/my_voucher.dart';
import 'package:karbon_kita_app/models/voucher.dart';
import 'package:karbon_kita_app/models/voucher_city.dart';

class _FakeRepo extends VoucherRepository {
  _FakeRepo() : super(VoucherRemoteDatasource(DioClient()));

  String? lastCategory;
  String? lastCity;

  @override
  Future<List<Voucher>> getVouchers({String? category, String? city}) async {
    lastCategory = category;
    lastCity = city;
    return const [];
  }

  @override
  Future<({List<Voucher> vouchers, DateTime? savedAt})> getCachedVouchers({
    String? category,
    String? city,
  }) async {
    return (vouchers: const <Voucher>[], savedAt: null);
  }

  @override
  Future<int> getEcoPoints() async => 0;

  @override
  Future<List<VoucherCity>> getVoucherCities() async => const [
        VoucherCity(city: 'Surabaya', voucherCount: 3),
      ];

  @override
  Future<List<VoucherCity>> getCachedVoucherCities() async => const [];
}

void main() {
  test('Voucher mitra baca city + alamat lengkap', () {
    final v = Voucher.fromJson({
      'id': 1,
      'title': 'Kopi',
      'description': 'd',
      'category': 'kuliner',
      'image_url': '',
      'points_cost': 250,
      'rupiah_value': '10000.00',
      'stock': 5,
      'claimed_count': 0,
      'expired_at': '2026-12-31',
      'is_active': true,
      'mitra': {
        'name': 'Budi',
        'store_name': 'Kedai Kopi',
        'city': 'Surabaya',
        'address': {
          'alamat': 'Jl. Test No 1',
          'kelurahan': 'Kel A',
          'kecamatan': 'Kec A',
          'kota': 'Surabaya',
          'provinsi': 'Jawa Timur',
          'kode_pos': '60111',
        },
      },
    });
    expect(v.mitra.displayCity, 'Surabaya');
    expect(v.mitra.address.fullLabel,
        'Jl. Test No 1, Kel A, Kec A, Surabaya, Jawa Timur, 60111');
  });

  test('Voucher lama tanpa city tetap aman', () {
    final v = Voucher.fromJson({
      'id': 1,
      'title': 'Kopi',
      'description': 'd',
      'image_url': '',
      'points_cost': 250,
      'rupiah_value': 10000,
      'stock': 5,
      'claimed_count': 0,
      'expired_at': '2026-12-31',
      'is_active': true,
      'mitra': {'name': 'Budi', 'store_name': 'Kedai Kopi'},
    });
    expect(v.mitra.displayCity, '-');
    expect(v.mitra.address.fullLabel, '-');
  });

  test('MyVoucherClaim baca city + address', () {
    final inv = MyVoucherInventory.fromJson({
      'active': [
        {
          'claim_id': 11,
          'qr_token': 'KBK-A',
          'status': 'claimed',
          'voucher': {'id': 5, 'title': 'Kopi', 'expired_at': '2026-12-31'},
          'mitra': {
            'store_name': 'Kedai Kopi',
            'name': 'Budi',
            'city': 'Bandung',
            'address': {'kota': 'Bandung', 'kecamatan': 'Kec B'},
          },
        }
      ],
      'used': [],
      'expired': [],
    });
    expect(inv.active.first.city, 'Bandung');
    expect(inv.active.first.addressLabel, contains('Bandung'));
  });

  test('DashboardUser baca kota', () {
    final u = DashboardUser.fromJson({
      'name': 'Warga',
      'kota': 'Surabaya',
      'kecamatan': 'Gubeng',
      'rt': '01',
      'rw': '02',
      'kelurahan': 'Kel',
    });
    expect(u.kota, 'Surabaya');
  });

  test('VouchersLoaded(city) teruskan city ke repository', () async {
    final repo = _FakeRepo();
    final bloc = VoucherBloc(repo);
    final future = expectLater(
      bloc.stream,
      emitsThrough(predicate<VoucherState>(
          (s) => s.status == VoucherStatus.loaded && s.selectedCity == 'Surabaya')),
    );
    bloc.add(const VouchersLoaded(city: 'Surabaya'));
    await future;
    expect(repo.lastCity, 'Surabaya');
    await bloc.close();
  });

  test('VoucherCitiesLoaded isi opsi kota', () async {
    final bloc = VoucherBloc(_FakeRepo());
    final future = expectLater(
      bloc.stream,
      emitsThrough(
          predicate<VoucherState>((s) => s.cities.length == 1)),
    );
    bloc.add(const VoucherCitiesLoaded());
    await future;
    await bloc.close();
  });
}
