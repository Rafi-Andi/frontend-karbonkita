import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Pengambil rute yang mengikuti jalan untuk mode demo/simulasi misi mobilitas.
///
/// Memakai layanan OSRM publik FOSSGIS (routing.openstreetmap.de) yang
/// menyediakan profil `foot` dan `bike`. Hasilnya berupa polyline jalan nyata
/// sehingga rute demo tidak lagi berupa garis lurus yang menembus bangunan.
///
/// Mode demo bersifat opsional & membutuhkan internet. Semua kegagalan
/// (offline, timeout, respons tidak valid) dilempar sebagai
/// [DemoRouteException] agar pemanggil dapat fallback ke rute lurus.
class DemoRouteService {
  DemoRouteService({Dio? dio, Distance? distance})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          ),
      _distance = distance ?? const Distance(roundResult: false);

  static const String _host = 'https://routing.openstreetmap.de';

  final Dio _dio;
  final Distance _distance;

  /// Ambil titik-titik rute mengikuti jalan dari [start] menuju destinasi
  /// sejauh kira-kira [approxDistanceM] meter (jarak lurus — jarak jalan
  /// biasanya lebih jauh). [activityType] menentukan profil OSRM:
  /// `cycling` → `bike`, lainnya (`walking`/`running`) → `foot`.
  ///
  /// [bearingDeg] menentukan arah awal destinasi, dipakai untuk memvariasikan
  /// rute saat menyambung leg berikutnya.
  Future<List<LatLng>> fetchRoadRoute({
    required LatLng start,
    required String activityType,
    required double approxDistanceM,
    double bearingDeg = 45,
  }) async {
    final profile = _profileFor(activityType);
    // Jarak lurus minimal agar OSRM tetap mengembalikan rute yang berarti.
    final straightDistance = approxDistanceM < 200 ? 200.0 : approxDistanceM;
    final destination = _distance.offset(start, straightDistance, bearingDeg);
    final url =
        '$_host/routed-$profile/route/v1/$profile/'
        '${start.longitude},${start.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final res = await _dio.get<Map<String, dynamic>>(url);
      final route = _firstRoute(res.data);
      if (route == null) {
        throw const DemoRouteException('Rute jalan tidak ditemukan.');
      }
      final points = _parseGeometry(route);
      if (points.length < 2) {
        throw const DemoRouteException('Rute jalan terlalu pendek.');
      }
      return points;
    } on DemoRouteException {
      rethrow;
    } on DioException catch (e) {
      throw DemoRouteException('Gagal memuat rute jalan (${e.type.name}).');
    } catch (_) {
      throw const DemoRouteException('Gagal memuat rute jalan.');
    }
  }

  String _profileFor(String activityType) =>
      activityType == 'cycling' ? 'bike' : 'foot';

  Map<String, dynamic>? _firstRoute(dynamic data) {
    if (data is! Map) return null;
    if (data['code'] != 'Ok') return null;
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) return null;
    final first = routes.first;
    return first is Map ? first.cast<String, dynamic>() : null;
  }

  /// OSRM GeoJSON menaruh koordinat sebagai `[lng, lat]`.
  List<LatLng> _parseGeometry(Map<String, dynamic> route) {
    final geometry = route['geometry'];
    if (geometry is! Map) return const [];
    final coordinates = geometry['coordinates'];
    if (coordinates is! List) return const [];
    final points = <LatLng>[];
    for (final c in coordinates) {
      if (c is List && c.length >= 2 && c[0] is num && c[1] is num) {
        points.add(LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()));
      }
    }
    return points;
  }
}

/// Kegagalan pengambilan rute jalan (mode demo) — pemanggil fallback lurus.
class DemoRouteException implements Exception {
  const DemoRouteException(this.message);

  final String message;

  @override
  String toString() => message;
}
