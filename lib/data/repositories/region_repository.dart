import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/storage/cache_service.dart';
import '../../core/storage/cache_keys.dart';
import '../../models/region.dart';
import '../datasources/region_remote_datasource.dart';

/// Hasil fetch wilayah + penanda apakah datanya fallback offline.
///
/// `fallback == true` berarti request network gagal dan tidak ada cache,
/// sehingga UI wajib menampilkannya (sebelumnya bug: fallback diam-diam
/// sehingga dropdown terlihat hanya berisi 1 item tanpa penjelasan).
/// `reason` berisi penyebab singkat (mis. CORS di web) untuk diagnosis.
typedef RegionFetch = ({List<Region> regions, bool fallback, String? reason});

/// Repository wilayah: network-first dengan cache Hive + fallback offline.
///
/// - Online: hasil API ditulis ke cache agar buka berikutnya instan.
/// - Offline/gagal: pakai cache terakhir; bila cache kosong, pakai rantai
///   minimal Surabaya agar register tetap bisa jalan (nama yang dikirim ke
///   backend tetap string sesuai kontrak, hanya code fallback yang lokal).
class RegionRepository {
  RegionRepository(this._remote, {CacheService? cache}) : _cache = cache;

  final RegionRemoteDatasource _remote;
  final CacheService? _cache;

  // ----- Fallback offline minimal (hanya nama yang dipakai backend) -----
  static const fallbackProvinces = [Region(code: '35', name: 'Jawa Timur')];
  static const fallbackRegencies = [Region(code: '35.78', name: 'Surabaya')];
  static const fallbackDistricts = [Region(code: '35.78.08', name: 'Gubeng')];
  static const fallbackVillages = [
    Region(code: '35.78.08.1001', name: 'Airlangga'),
    Region(code: '35.78.08.1002', name: 'Baratajaya'),
    Region(code: '35.78.08.1003', name: 'Gubeng'),
    Region(code: '35.78.08.1004', name: 'Kertajaya'),
    Region(code: '35.78.08.1005', name: 'Mojo'),
    Region(code: '35.78.08.1006', name: 'Pucang Sewu'),
  ];

  Future<RegionFetch> getProvinces() => _get(
    cacheKey: CacheKeys.regionsProvinces,
    fallback: fallbackProvinces,
    fetch: _remote.getProvinces,
  );

  Future<RegionFetch> getRegencies(String provinceCode) => _get(
    cacheKey: CacheKeys.regionsRegencies(provinceCode),
    fallback: provinceCode == '35' ? fallbackRegencies : const [],
    fetch: () => _remote.getRegencies(provinceCode),
  );

  Future<RegionFetch> getDistricts(String regencyCode) => _get(
    cacheKey: CacheKeys.regionsDistricts(regencyCode),
    fallback: regencyCode == '35.78' ? fallbackDistricts : const [],
    fetch: () => _remote.getDistricts(regencyCode),
  );

  Future<RegionFetch> getVillages(String districtCode) => _get(
    cacheKey: CacheKeys.regionsVillages(districtCode),
    fallback: districtCode == '35.78.08' ? fallbackVillages : const [],
    fetch: () => _remote.getVillages(districtCode),
  );

  Future<RegionFetch> _get({
    required String cacheKey,
    required List<Region> fallback,
    required Future<List<Region>> Function() fetch,
  }) async {
    try {
      final fresh = await fetch();
      if (fresh.isNotEmpty) {
        await _cache?.writeJson(
          cacheKey,
          fresh.map((e) => e.toJson()).toList(),
        );
        return (regions: fresh, fallback: false, reason: null);
      }
      debugPrint('[RegionRepository] $cacheKey: API kosong, pakai cache.');
    } catch (e) {
      final reason = _shortReason(e);
      debugPrint('[RegionRepository] $cacheKey gagal: $e');
      final cached = _cachedRegions(cacheKey);
      if (cached.isNotEmpty) {
        return (regions: cached, fallback: false, reason: null);
      }
      return (regions: fallback, fallback: true, reason: reason);
    }
    final cached = _cachedRegions(cacheKey);
    if (cached.isNotEmpty) {
      return (regions: cached, fallback: false, reason: null);
    }
    return (
      regions: fallback,
      fallback: true,
      reason: 'API mengembalikan data kosong',
    );
  }

  List<Region> _cachedRegions(String cacheKey) {
    final cached = _cache?.readList(cacheKey);
    if (cached == null || cached.isEmpty) return const [];
    return cached
        .whereType<Map<String, dynamic>>()
        .map(Region.fromJson)
        .where((e) => e.code.isNotEmpty && e.name.isNotEmpty)
        .toList();
  }

  /// Ringkas penyebab gagal agar bisa ditampilkan di UI.
  static String _shortReason(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.transformTimeout:
          return 'timeout jaringan (10 dtk)';
        case DioExceptionType.connectionError:
          return 'tidak ada koneksi internet ke wilayah.id';
        case DioExceptionType.badResponse:
          return 'server wilayah: HTTP ${e.response?.statusCode ?? '?'}';
        case DioExceptionType.cancel:
          return 'request dibatalkan';
        case DioExceptionType.unknown:
          final msg = (e.message ?? e.error?.toString() ?? '').toString();
          if (msg.contains('XMLHttpRequest')) {
            return 'diblokir browser (CORS) — jalankan di emulator/HP, bukan Chrome';
          }
          return msg.isEmpty ? 'gangguan jaringan tak dikenal' : msg;
        case DioExceptionType.badCertificate:
          return 'sertifikat HTTPS ditolak perangkat';
      }
    }
    return e.toString();
  }
}
