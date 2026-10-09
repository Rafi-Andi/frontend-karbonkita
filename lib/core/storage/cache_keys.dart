/// Kunci cache offline (Hive box `karbon_cache`).
///
/// Tanpa kadaluarsa: cache selalu dianggap valid dan hanya ditimpa saat
/// fetch online sukses. Kunci user-scope memakai `uid` agar user berbeda
/// tidak saling intip; logout tetap menghapus semua cache.
class CacheKeys {
  static String dashboard(String uid) => 'dashboard_$uid';
  static String missionsActive(String uid) => 'missions_active_$uid';
  static String sagaNodes(String uid) => 'saga_nodes_$uid';
  static String sagaQuizzes(String uid) => 'saga_quizzes_$uid';
  static String dailyQuiz(String date) => 'daily_quiz_$date';

  /// Sesi soal per node (global per node untuk hari berjalan).
  static String sagaSession(int missionId) => 'saga_session_$missionId';

  static String vouchers(String? category, [String? city]) =>
      'vouchers_${category ?? 'all'}_${(city == null || city.isEmpty) ? 'all' : city}';
  static const String voucherCities = 'voucher_cities';
  static String myVouchers(String uid) => 'my_vouchers_$uid';
  static String ecoPoints(String uid) => 'eco_points_$uid';

  static String leaderboard(String scope, String timeframe) =>
      'leaderboard_${scope}_$timeframe';

  static String levels(String uid) => 'levels_$uid';
  static String activities(String uid, int limit) => 'activities_${uid}_$limit';

  /// Dashboard merchant per user mitra (1 toko per user).
  static String merchantDashboard(String uid) => 'merchant_dashboard_$uid';

  /// Cache master wilayah (nasional, bukan per user).
  static const String regionsProvinces = 'regions_provinces';
  static String regionsRegencies(String provinceCode) =>
      'regions_regencies_$provinceCode';
  static String regionsDistricts(String regencyCode) =>
      'regions_districts_$regencyCode';
  static String regionsVillages(String districtCode) =>
      'regions_villages_$districtCode';
}
