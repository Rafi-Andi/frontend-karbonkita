import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/core/utils/demo_route.dart';
import 'package:latlong2/latlong.dart';

/// Adapter Dio palsu yang mengembalikan body JSON tetap tanpa jaringan.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body, {this.statusCode = 200});

  final String body;
  final int statusCode;
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

DemoRouteService _serviceWith(String body, {int statusCode = 200}) {
  final dio = Dio();
  dio.httpClientAdapter = _FakeAdapter(body, statusCode: statusCode);
  return DemoRouteService(dio: dio);
}

const _okRoute =
    '{"code":"Ok","routes":[{"geometry":{"type":"LineString",'
    '"coordinates":[[112.79,-7.28],[112.792,-7.281],[112.795,-7.285]]}}]}';

void main() {
  group('DemoRouteService.fetchRoadRoute', () {
    test('parse koordinat OSRM [lng, lat] menjadi LatLng(lat, lng)', () async {
      final service = _serviceWith(_okRoute);
      final points = await service.fetchRoadRoute(
        start: const LatLng(-7.28, 112.79),
        activityType: 'cycling',
        approxDistanceM: 1000,
      );

      expect(points.length, 3);
      expect(points.first.latitude, closeTo(-7.28, 1e-9));
      expect(points.first.longitude, closeTo(112.79, 1e-9));
      expect(points.last.latitude, closeTo(-7.285, 1e-9));
      expect(points.last.longitude, closeTo(112.795, 1e-9));
    });

    test('cycling memakai profil bike, walking memakai foot', () async {
      final bikeDio = Dio()..httpClientAdapter = _FakeAdapter(_okRoute);
      final bike = DemoRouteService(dio: bikeDio);
      await bike.fetchRoadRoute(
        start: const LatLng(-7.28, 112.79),
        activityType: 'cycling',
        approxDistanceM: 1000,
      );
      expect(
        (bikeDio.httpClientAdapter as _FakeAdapter).lastOptions?.path,
        contains('/routed-bike/route/v1/bike/'),
      );

      final footDio = Dio()..httpClientAdapter = _FakeAdapter(_okRoute);
      final foot = DemoRouteService(dio: footDio);
      await foot.fetchRoadRoute(
        start: const LatLng(-7.28, 112.79),
        activityType: 'walking',
        approxDistanceM: 1000,
      );
      expect(
        (footDio.httpClientAdapter as _FakeAdapter).lastOptions?.path,
        contains('/routed-foot/route/v1/foot/'),
      );
    });

    test('respons NoRoute -> DemoRouteException', () async {
      final service = _serviceWith('{"code":"NoRoute","routes":[]}');
      expect(
        () => service.fetchRoadRoute(
          start: const LatLng(-7.28, 112.79),
          activityType: 'walking',
          approxDistanceM: 1000,
        ),
        throwsA(isA<DemoRouteException>()),
      );
    });

    test('rute kurang dari 2 titik -> DemoRouteException', () async {
      final service = _serviceWith(
        '{"code":"Ok","routes":[{"geometry":{"type":"LineString",'
        '"coordinates":[[112.79,-7.28]]}}]}',
      );
      expect(
        () => service.fetchRoadRoute(
          start: const LatLng(-7.28, 112.79),
          activityType: 'walking',
          approxDistanceM: 1000,
        ),
        throwsA(isA<DemoRouteException>()),
      );
    });

    test('status HTTP 500 -> DemoRouteException (bukan crash)', () async {
      final service = _serviceWith('{"message":"boom"}', statusCode: 500);
      expect(
        () => service.fetchRoadRoute(
          start: const LatLng(-7.28, 112.79),
          activityType: 'walking',
          approxDistanceM: 1000,
        ),
        throwsA(isA<DemoRouteException>()),
      );
    });
  });
}
