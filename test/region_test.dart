import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/bloc/register_region/register_region_cubit.dart';
import 'package:karbon_kita_app/core/utils/address_normalize.dart';
import 'package:karbon_kita_app/data/datasources/region_remote_datasource.dart';
import 'package:karbon_kita_app/data/repositories/region_repository.dart';
import 'package:karbon_kita_app/models/region.dart';

class _FakeRegionRepository extends RegionRepository {
  _FakeRegionRepository() : super(RegionRemoteDatasource());

  final Map<String, List<Region>> data = {
    'provinces': const [
      Region(code: '35', name: 'Jawa Timur'),
      Region(code: '31', name: 'DKI Jakarta'),
    ],
    'regencies:35': const [
      Region(code: '35.78', name: 'Surabaya'),
      Region(code: '35.79', name: 'Batu'),
    ],
    'districts:35.78': const [
      Region(code: '35.78.08', name: 'Gubeng'),
      Region(code: '35.78.01', name: 'Sukolilo'),
    ],
    'villages:35.78.08': const [
      Region(code: '35.78.08.1005', name: 'Mojo'),
      Region(code: '35.78.08.1001', name: 'Airlangga'),
    ],
  };

  bool throwAll = false;

  @override
  Future<RegionFetch> getProvinces() async {
    if (throwAll) throw Exception('offline');
    return (regions: data['provinces']!, fallback: false, reason: null);
  }

  @override
  Future<RegionFetch> getRegencies(String provinceCode) async {
    if (throwAll) throw Exception('offline');
    return (
      regions: data['regencies:$provinceCode'] ?? const [],
      fallback: false,
      reason: null,
    );
  }

  @override
  Future<RegionFetch> getDistricts(String regencyCode) async {
    if (throwAll) throw Exception('offline');
    return (
      regions: data['districts:$regencyCode'] ?? const [],
      fallback: false,
      reason: null,
    );
  }

  @override
  Future<RegionFetch> getVillages(String districtCode) async {
    if (throwAll) throw Exception('offline');
    return (
      regions: data['villages:$districtCode'] ?? const [],
      fallback: false,
      reason: null,
    );
  }
}

/// Remote yang selalu gagal (simulasi tidak ada koneksi ke wilayah.id).
class _FailingRemote extends RegionRemoteDatasource {
  _FailingRemote();

  @override
  Future<List<Region>> getProvinces() {
    throw Exception('offline');
  }

  @override
  Future<List<Region>> getRegencies(String provinceCode) {
    throw Exception('offline');
  }

  @override
  Future<List<Region>> getDistricts(String regencyCode) {
    throw Exception('offline');
  }

  @override
  Future<List<Region>> getVillages(String districtCode) {
    throw Exception('offline');
  }
}

void main() {
  group('Region parsing (kontrak wilayah.id)', () {
    test('fromJson baca code+name', () {
      const r = Region(code: '35', name: 'Jawa Timur');
      expect(Region.fromJson({'code': '35', 'name': 'Jawa Timur'}), r);
    });

    test('fromJson toleran format id (emsifa)', () {
      final r = Region.fromJson({'id': '35', 'name': 'JAWA TIMUR'});
      expect(r.code, '35');
      expect(r.name, 'JAWA TIMUR');
    });

    test('listOf terima envelope {data:[...]} maupun list polos', () {
      final fromEnvelope = Region.listOf({
        'data': [
          {'code': '35', 'name': 'Jawa Timur'},
        ],
        'meta': {'updated_at': '2025-07-04'},
      });
      final fromList = Region.listOf([
        {'code': '35', 'name': 'Jawa Timur'},
      ]);
      expect(fromEnvelope, hasLength(1));
      expect(fromList, hasLength(1));
    });

    test('listOf buang entri kosong', () {
      final list = Region.listOf([
        {'code': '', 'name': ''},
        {'code': '35', 'name': 'Jawa Timur'},
      ]);
      expect(list, hasLength(1));
    });
  });

  group('Normalisasi alamat (frontend-only, tanpa ubah backend)', () {
    test('RT: 5 -> 005, 05 -> 005, 005 tetap', () {
      expect(normalizeRt('5'), '005');
      expect(normalizeRt('05'), '005');
      expect(normalizeRt('005'), '005');
    });

    test('RW: 2 -> 02, 02 tetap', () {
      expect(normalizeRw('2'), '02');
      expect(normalizeRw('02'), '02');
    });

    test('RT/RW invalid terdeteksi', () {
      expect(isValidRt(''), isFalse);
      expect(isValidRt('abc'), isFalse);
      expect(isValidRt('1234'), isFalse);
      expect(isValidRw('123'), isFalse);
      expect(isValidRt('7'), isTrue);
      expect(isValidRw('9'), isTrue);
    });

    test('No HP dinormalisasi ke +62… (format backend)', () {
      expect(normalizePhone('+628123456789'), '+628123456789');
      expect(normalizePhone('08123456789'), '+628123456789');
      expect(normalizePhone('628123456789'), '+628123456789');
      expect(normalizePhone('8123456789'), '+628123456789');
      expect(isValidPhone('08123456789'), isTrue);
      expect(isValidPhone('123'), isFalse);
    });

    test('Email & nama diraplikan', () {
      expect(isValidEmail('rafi@example.com'), isTrue);
      expect(isValidEmail('bukan-email'), isFalse);
      expect(canonicalName('  Surabaya   Timur '), 'Surabaya Timur');
    });
  });

  group('RegionRepository fallback offline', () {
    test('offline + tanpa cache -> rantai Surabaya + flag fallback', () async {
      final failing = RegionRepository(_FailingRemote());
      final prov = await failing.getProvinces();
      expect(prov.regions, RegionRepository.fallbackProvinces);
      expect(prov.fallback, isTrue);
      expect(prov.reason, isNotNull);
      final reg = await failing.getRegencies('35');
      expect(reg.regions, RegionRepository.fallbackRegencies);
      expect(reg.fallback, isTrue);
      final dis = await failing.getDistricts('35.78');
      expect(dis.regions, RegionRepository.fallbackDistricts);
      expect(dis.fallback, isTrue);
      final vil = await failing.getVillages('35.78.08');
      expect(vil.regions.map((e) => e.name), contains('Mojo'));
      expect(vil.fallback, isTrue);
    });
  });

  group('RegisterRegionCubit cascading', () {
    test('load otomatis preselect Surabaya → Gubeng → Mojo', () async {
      final cubit = RegisterRegionCubit(_FakeRegionRepository());
      await cubit.loadProvinces();
      expect(cubit.state.province?.name, 'Jawa Timur');
      expect(cubit.state.regency?.name, 'Surabaya');
      expect(cubit.state.district?.name, 'Gubeng');
      expect(cubit.state.village?.name, 'Mojo');
      expect(cubit.state.isComplete, isTrue);
      expect(cubit.state.isOffline, isFalse);
      await cubit.close();
    });

    test('ganti provinsi me-reset anaknya', () async {
      final cubit = RegisterRegionCubit(_FakeRegionRepository());
      await cubit.loadProvinces();
      expect(cubit.state.isComplete, isTrue);
      await cubit.selectProvince(const Region(code: '31', name: 'DKI Jakarta'));
      expect(cubit.state.province?.name, 'DKI Jakarta');
      expect(cubit.state.regency, isNull);
      expect(cubit.state.district, isNull);
      expect(cubit.state.village, isNull);
      expect(cubit.state.isComplete, isFalse);
      await cubit.close();
    });

    test(
      'fallback menandai isOffline + alasan (kasus dropdown 1 item)',
      () async {
        final cubit = RegisterRegionCubit(RegionRepository(_FailingRemote()));
        await cubit.loadProvinces();
        expect(cubit.state.isOffline, isTrue);
        expect(cubit.state.offlineReason, isNotNull);
        // rantai minimal tetap terisi agar register tidak buntu
        expect(cubit.state.province?.name, 'Jawa Timur');
        expect(cubit.state.isComplete, isTrue);
        await cubit.close();
      },
    );

    test('retry online kembali mengisi penuh + pertahankan pilihan', () async {
      final repo = _FakeRegionRepository();
      final cubit = RegisterRegionCubit(repo);
      await cubit.loadProvinces();
      await cubit.selectProvince(const Region(code: '31', name: 'DKI Jakarta'));
      // simulasi koneksi kembali: retry tidak me-reset pilihan manual
      await cubit.retry();
      expect(cubit.state.province?.code, '31');
      expect(cubit.state.provinces, hasLength(2));
      await cubit.close();
    });
  });
}
