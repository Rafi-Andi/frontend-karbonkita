import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/core/storage/cache_keys.dart';
import 'package:karbon_kita_app/core/storage/cache_service.dart';
import 'package:karbon_kita_app/models/dashboard.dart';

void main() {
  group('Offline cache (Hive read-only, tanpa kadaluarsa)', () {
    test('write lalu read kembali + lastUpdated terisi', () async {
      final cache = CacheService();
      final dashboard = DashboardData.fromJson({
        'user': {'name': 'Uji', 'eco_points': 99},
        'daily_missions': [],
        'leaderboard_preview': [],
      });
      final key = CacheKeys.dashboard('1');
      await cache.writeJson(key, dashboard.toJson());

      final map = cache.readMap(key);
      expect(map, isNotNull);
      expect(DashboardData.fromJson(map!).user.ecoPoints, 99);
      expect(cache.lastUpdated(key), isNotNull);
    });

    test('key belum pernah ditulis -> null (UI tampilkan empty offline)', () {
      final cache = CacheService();
      expect(cache.readMap('tidak_ada'), isNull);
      expect(cache.lastUpdated('tidak_ada'), isNull);
    });

    test('clearAll hapus cache (dipanggil saat logout)', () async {
      final cache = CacheService();
      await cache.writeJson('k1', {'a': 1});
      await cache.clearAll();
      expect(cache.readMap('k1'), isNull);
    });
  });
}
