/// Base URL & endpoint API KarbonKita.
///
/// Isi via --dart-define API_BASE_URL saat run/build.
/// Default localhost untuk Windows/Web, ganti ke 10.0.2.2 untuk emulator Android.
class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String me = '/user';
  static const String registerMitra = '/auth/register-mitra';

  // Missions
  static const String missionsActive = '/missions/active';
  static const String verifyWaste = '/missions/verify-waste';
  static const String mobilitySync = '/missions/mobility-sync';

  // Saga (Quiz)
  static const String sagaNodes = '/saga/nodes';
  static const String sagaQuizzes = '/saga/quizzes';
  static const String sagaAnswer = '/saga/answer';

  static String sagaNodeQuestions(int missionId) =>
      '$sagaNodes/$missionId/questions';

  // Marketplace (Voucher)
  static const String vouchers = '/vouchers';
  static const String vouchersClaim = '/vouchers/claim';
  static const String myVouchers = '/user/my-vouchers';

  /// GET /api/vouchers, opsional filter `?category=kuliner|...`.
  static String vouchersQuery({String? category}) =>
      category == null ? vouchers : '$vouchers?category=$category';

  // Dashboard (saldo eco_points)
  static const String userDashboard = '/user/dashboard';

  // Level tiers (3 tier lencana untuk Profil)
  static const String userLevels = '/user/levels';

  // Aktivitas terbaru untuk Profil
  static const String userActivities = '/user/activities';

  // Leaderboard (scope: rt|rw, timeframe: weekly|monthly)
  static const String leaderboard = '/leaderboard';

  // Merchant (Mitra UMKM) — role:mitra
  static const String merchantDashboard = '/merchant/dashboard';
  static const String merchantStatus = '/merchant/status';
  static const String merchantDisbursements = '/merchant/disbursements';

  // Redeem voucher oleh kasir (QR scan / input manual token).
  // Body: {unique_code: qr_token}. Token asli backend format KBK-XXX-XXX.
  static const String vouchersRedeem = '/vouchers/redeem';

  // Donasi warga — katalog publik, donasi & riwayat butuh login.
  static const String donationCampaigns = '/donation-campaigns';
  static const String donations = '/donations';
  static const String myDonations = '/user/my-donations';

  static String donationCampaignDetail(String slug) =>
      '$donationCampaigns/$slug';
  static String donationCancel(int id) => '$donations/$id/cancel';

  // Admin donasi & pendanaan (role:admin).
  static const String adminDonationCampaigns = '/admin/donation-campaigns';
  static const String adminVouchers = '/admin/vouchers';

  static String adminDonationCampaign(int id) => '$adminDonationCampaigns/$id';

  // Admin validasi mitra (role:admin).
  static const String adminMerchants = '/admin/merchants';

  /// GET /api/admin/merchants?status=pending|verified|rejected.
  static String adminMerchantsQuery({String status = 'pending'}) =>
      '$adminMerchants?status=$status';

  static String adminMerchantDetail(int id) => '$adminMerchants/$id';
  static String adminMerchantVerify(int id) => '$adminMerchants/$id/verify';

  // Admin kelola misi mobility & waste (role:admin).
  static const String adminMissions = '/admin/missions';

  static String adminMission(int id) => '$adminMissions/$id';
  static String adminMissionStatus(int id) => '$adminMissions/$id/status';

  static String leaderboardQuery({
    required String scope,
    required String timeframe,
  }) => '$leaderboard?scope=$scope&timeframe=$timeframe';

  static String url(String path) => '$baseUrl$path';

  /// Normalisasi URL gambar dari server agar bisa di-load aplikasi.
  ///
  /// Backend membangun URL via `Storage::url()` dari `APP_URL`, yang bisa
  /// beda host/port dengan base URL yang dipakai Flutter (cth. APP_URL
  /// `http://localhost` tanpa port, emulator `10.0.2.2`, atau domain
  /// produksi). Fungsi ini mempertahankan path+query tapi menukar
  /// origin (scheme/host/port) ke [baseUrl] — server yang pasti terjangkau
  /// karena API-nya sendiri jalan di sana. URL relatif juga didukung.
  /// Return '' bila kosong/tidak valid (UI tampilkan placeholder).
  static String resolveImageUrl(String? url) {
    if (url == null) return '';
    final raw = url.trim();
    if (raw.isEmpty) return '';
    final base = Uri.parse(baseUrl);
    final parsed = Uri.tryParse(raw);
    if (parsed == null) return '';
    if (!parsed.hasScheme) {
      final path = raw.startsWith('/') ? raw : '/$raw';
      return '${base.origin}$path';
    }
    final rebuilt = parsed.replace(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
    );
    return rebuilt.toString();
  }
}
