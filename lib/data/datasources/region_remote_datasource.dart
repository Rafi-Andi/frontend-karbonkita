import 'package:dio/dio.dart';

import '../../models/region.dart';

/// Akses mentah ke API wilayah Indonesia (wilayah.id, gratis tanpa API key).
///
/// Sengaja memakai Dio polos (bukan [DioClient] backend) karena base URL
/// berbeda dan tidak butuh header `Authorization` KarbonKita.
class RegionRemoteDatasource {
  RegionRemoteDatasource({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://wilayah.id/api',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: const {'Accept': 'application/json'},
            ),
          );

  final Dio _dio;

  Future<List<Region>> getProvinces() async {
    final res = await _dio.get('/provinces.json');
    return Region.listOf(res.data);
  }

  Future<List<Region>> getRegencies(String provinceCode) async {
    final res = await _dio.get('/regencies/$provinceCode.json');
    return Region.listOf(res.data);
  }

  Future<List<Region>> getDistricts(String regencyCode) async {
    final res = await _dio.get('/districts/$regencyCode.json');
    return Region.listOf(res.data);
  }

  Future<List<Region>> getVillages(String districtCode) async {
    final res = await _dio.get('/villages/$districtCode.json');
    return Region.listOf(res.data);
  }
}
