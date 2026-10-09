import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/core/network/api_endpoints.dart';

// resolveImageUrl menukar origin URL server ke origin baseUrl aktif
// (bisa localhost dev atau domain produksi via --dart-define).
// Test ini menghitung ekspektasi dari baseUrl agar tak bergantung
// nilai default yang bisa berubah.

String _origin() => Uri.parse(ApiEndpoints.baseUrl).origin;

void main() {
  group('ApiEndpoints.resolveImageUrl', () {
    test('null/kosong/tidak valid -> string kosong', () {
      expect(ApiEndpoints.resolveImageUrl(null), '');
      expect(ApiEndpoints.resolveImageUrl(''), '');
      expect(ApiEndpoints.resolveImageUrl('   '), '');
    });

    test('origin berbeda ditukar ke origin baseUrl', () {
      expect(
        ApiEndpoints.resolveImageUrl(
          'http://localhost/storage/mitra/21/foto.png',
        ),
        '${_origin()}/storage/mitra/21/foto.png',
      );
    });

    test('path relatif digabung ke origin baseUrl', () {
      expect(
        ApiEndpoints.resolveImageUrl('/storage/mitra/21/foto.png'),
        '${_origin()}/storage/mitra/21/foto.png',
      );
      expect(
        ApiEndpoints.resolveImageUrl('storage/mitra/21/foto.png'),
        '${_origin()}/storage/mitra/21/foto.png',
      );
    });

    test('URL yang sudah benar tidak berubah', () {
      final url = '${_origin()}/storage/mitra/21/foto.png';
      expect(ApiEndpoints.resolveImageUrl(url), url);
    });

    test('query string dipertahankan', () {
      expect(
        ApiEndpoints.resolveImageUrl('http://localhost/storage/x.png?sig=abc'),
        '${_origin()}/storage/x.png?sig=abc',
      );
    });
  });
}
