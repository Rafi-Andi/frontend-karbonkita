import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_event.dart';
import 'bloc/auth/auth_state.dart';
import 'bloc/activity/activity_bloc.dart';
import 'bloc/admin_merchant/admin_merchant_bloc.dart';
import 'bloc/admin_mission/admin_mission_bloc.dart';
import 'bloc/admin_reward/admin_reward_bloc.dart';
import 'bloc/dashboard/dashboard_bloc.dart';
import 'bloc/donation/donation_bloc.dart';
import 'bloc/admin_campaign/admin_campaign_bloc.dart';
import 'bloc/leaderboard/leaderboard_bloc.dart';
import 'bloc/level/level_bloc.dart';
import 'bloc/mission/mission_bloc.dart';
import 'bloc/merchant/merchant_bloc.dart';
import 'bloc/merchant_product/merchant_product_bloc.dart';
import 'bloc/quiz/quiz_bloc.dart';
import 'bloc/voucher/voucher_bloc.dart';
import 'core/network/connectivity_service.dart';
import 'core/network/dio_client.dart';
import 'core/storage/cache_service.dart';
import 'core/storage/token_storage.dart';
import 'data/datasources/admin_merchant_remote_datasource.dart';
import 'data/datasources/admin_mission_remote_datasource.dart';
import 'data/datasources/admin_reward_remote_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/donation_remote_datasource.dart';
import 'data/datasources/leaderboard_remote_datasource.dart';
import 'data/datasources/merchant_remote_datasource.dart';
import 'data/datasources/mission_remote_datasource.dart';
import 'data/datasources/profile_remote_datasource.dart';
import 'data/datasources/voucher_remote_datasource.dart';
import 'data/repositories/admin_merchant_repository.dart';
import 'data/repositories/admin_mission_repository.dart';
import 'data/repositories/admin_reward_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/donation_repository.dart';
import 'data/repositories/leaderboard_repository.dart';
import 'data/repositories/merchant_repository.dart';
import 'data/repositories/mission_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/voucher_repository.dart';
import 'ui/screens/admin_validation_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/merchant_dashboard_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'core/storage/onboarding_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Penyimpanan offline (Hive). Gagal init → fallback memori, app tetap jalan.
  final cache = CacheService();
  await cache.init();

  final storage = TokenStorage();
  final connectivity = ConnectivityService();
  final dioClient = DioClient(tokenReader: storage.readToken);
  final authRepository = AuthRepository(
    AuthRemoteDatasource(dioClient),
    storage,
    cache: cache,
  );

  // Repositori dipakai bersama oleh BLoC sesi. Disimpan di satu container
  // agar BLoC bisa dibuat ulang setiap ganti akun (lihat _SessionScope).
  final repositories = AppRepositories(
    mission: MissionRepository(
      MissionRemoteDatasource(dioClient),
      cache: cache,
      storage: storage,
    ),
    voucher: VoucherRepository(
      VoucherRemoteDatasource(dioClient),
      cache: cache,
      storage: storage,
    ),
    leaderboard: LeaderboardRepository(
      LeaderboardRemoteDatasource(dioClient),
      cache: cache,
    ),
    profile: ProfileRepository(
      ProfileRemoteDatasource(dioClient),
      cache: cache,
      storage: storage,
    ),
    merchant: MerchantRepository(
      MerchantRemoteDatasource(dioClient),
      cache: cache,
      storage: storage,
    ),
    donation: DonationRepository(DonationRemoteDatasource(dioClient)),
    adminMerchant: AdminMerchantRepository(
      AdminMerchantRemoteDatasource(dioClient),
    ),
    adminMission: AdminMissionRepository(
      AdminMissionRemoteDatasource(dioClient),
    ),
    adminReward: AdminRewardRepository(AdminRewardRemoteDatasource(dioClient)),
  );

  // AuthBloc hidup sepanjang aplikasi (di atas SessionGate) karena ia yang
  // menentukan sesi. BLoC data justru dibuat per sesi di _SessionScope
  // (di atas Navigator, lihat `MaterialApp.builder`).
  final authBloc = AuthBloc(authRepository)..add(const SessionChecked());

  runApp(
    MyApp(
      authBloc: authBloc,
      repositories: repositories,
      connectivity: connectivity,
    ),
  );
}

/// Kumpulan repositori yang dipakai BLoC data per sesi.
class AppRepositories {
  const AppRepositories({
    required this.mission,
    required this.voucher,
    required this.leaderboard,
    required this.profile,
    required this.merchant,
    required this.donation,
    required this.adminMerchant,
    required this.adminMission,
    required this.adminReward,
  });

  final MissionRepository mission;
  final VoucherRepository voucher;
  final LeaderboardRepository leaderboard;
  final ProfileRepository profile;
  final MerchantRepository merchant;
  final DonationRepository donation;
  final AdminMerchantRepository adminMerchant;
  final AdminMissionRepository adminMission;
  final AdminRewardRepository adminReward;
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.authBloc,
    required this.repositories,
    required this.connectivity,
  });

  final AuthBloc authBloc;
  final AppRepositories repositories;
  final ConnectivityService connectivity;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: authBloc,
      child: MaterialApp(
        title: 'KarbonKita',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const _SessionGate(),
        // BLoC data sesi HARUS berada DI ATAS Navigator. Halaman yang dibuka
        // lewat `Navigator.push` (Donasi, Kuis, Dompet Voucher, admin, mitra)
        // adalah route saudara dari `home`, bukan turunannya — kalau provider
        // diletakkan di dalam `home`, halaman itu tidak menemukan BLoC-nya
        // (ProviderNotFoundException → layar putih di build release).
        builder: (context, child) => _SessionScope(
          repositories: repositories,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Menyediakan semua BLoC data untuk SATU sesi user, di atas Navigator.
///
/// Bentuk tree sengaja dijaga tetap (BlocListener → MultiBlocProvider →
/// Navigator) agar Navigator tidak pernah di-remount saat login/logout —
/// kalau remount, splash 2 detik akan muncul lagi setelah login.
///
/// BLoC dibuat ulang setiap identitas sesi berubah (login akun lain, logout),
/// sehingga tidak ada state akun lama yang nyangkut. Karena provider tidak
/// pernah dilepas, route yang sedang di-pop saat logout tetap bisa membaca
/// BLoC-nya (tidak ada ProviderNotFoundException di tengah animasi).
class _SessionScope extends StatefulWidget {
  const _SessionScope({required this.repositories, required this.child});

  final AppRepositories repositories;
  final Widget child;

  @override
  State<_SessionScope> createState() => _SessionScopeState();
}

class _SessionScopeState extends State<_SessionScope> {
  late _SessionBlocs _blocs;
  int? _sessionUserId;

  @override
  void initState() {
    super.initState();
    _sessionUserId = _userIdOf(context.read<AuthBloc>().state);
    _blocs = _SessionBlocs(widget.repositories);
  }

  static int? _userIdOf(AuthState state) =>
      state.status == AuthStatus.authenticated ? state.user?.id : null;

  void _onSessionChanged(AuthState state) {
    final nextUserId = _userIdOf(state);
    if (nextUserId == _sessionUserId) return;
    setState(() {
      _sessionUserId = nextUserId;
      _blocs.dispose();
      _blocs = _SessionBlocs(widget.repositories);
    });
  }

  @override
  void dispose() {
    _blocs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => _userIdOf(prev) != _userIdOf(curr),
      listener: (context, state) => _onSessionChanged(state),
      child: MultiBlocProvider(
        providers: _blocs.providers,
        child: widget.child,
      ),
    );
  }
}

/// Auto-login: token permanen → langsung Home, tanpa token → Onboarding
/// (sekali saja) → Login.
/// Offline: profil lokal tetap dianggap sesi agar cache offline tampil.
///
/// [SplashScreen] tampil minimum 2 detik sejak aplikasi dibuka,
/// lalu alur sesi di bawahnya berjalan seperti biasa.
class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      // Logout: tutup semua route yang di-push agar Login/tujuan baru terlihat
      // dan route lama tidak memegang BLoC sesi yang sudah ditutup.
      listenWhen: (prev, curr) =>
          prev.status == AuthStatus.authenticated &&
          curr.status == AuthStatus.unauthenticated,
      listener: (context, _) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (!_splashDone) return const SplashScreen();
          switch (state.status) {
            case AuthStatus.initial:
            case AuthStatus.checking:
            case AuthStatus.loading:
              return const SplashScreen();
            case AuthStatus.authenticated:
              final role = state.user?.role ?? 'warga';
              if (role == 'mitra') {
                return const MerchantDashboardScreen();
              } else if (role == 'admin') {
                return const AdminValidationScreen();
              }
              return const HomeScreen();
            case AuthStatus.unauthenticated:
              return const _OnboardingGate();
          }
        },
      ),
    );
  }
}

/// Membuat dan memiliki semua BLoC data untuk SATU sesi user.
///
/// Dipasang di atas Navigator (lihat [_SessionScope]). Saat sesi berganti,
/// [dispose] menutup semua BLoC — state in-memory akun lama ikut hilang.
class _SessionBlocs {
  _SessionBlocs(AppRepositories r)
    : mission = MissionBloc(r.mission),
      voucher = VoucherBloc(r.voucher),
      dashboard = DashboardBloc(r.voucher),
      leaderboard = LeaderboardBloc(r.leaderboard),
      quiz = QuizBloc(r.mission),
      level = LevelBloc(r.profile),
      activity = ActivityBloc(r.profile),
      merchant = MerchantBloc(r.merchant),
      merchantProduct = MerchantProductBloc(r.merchant),
      adminMerchant = AdminMerchantBloc(r.adminMerchant),
      donation = DonationBloc(r.donation),
      adminCampaign = AdminCampaignBloc(r.donation),
      adminMission = AdminMissionBloc(r.adminMission),
      adminReward = AdminRewardBloc(r.adminReward);

  final MissionBloc mission;
  final VoucherBloc voucher;
  final DashboardBloc dashboard;
  final LeaderboardBloc leaderboard;
  final QuizBloc quiz;
  final LevelBloc level;
  final ActivityBloc activity;
  final MerchantBloc merchant;
  final MerchantProductBloc merchantProduct;
  final AdminMerchantBloc adminMerchant;
  final DonationBloc donation;
  final AdminCampaignBloc adminCampaign;
  final AdminMissionBloc adminMission;
  final AdminRewardBloc adminReward;

  List<BlocProvider<dynamic>> get providers => [
    BlocProvider<MissionBloc>.value(value: mission),
    BlocProvider<VoucherBloc>.value(value: voucher),
    BlocProvider<DashboardBloc>.value(value: dashboard),
    BlocProvider<LeaderboardBloc>.value(value: leaderboard),
    BlocProvider<QuizBloc>.value(value: quiz),
    BlocProvider<LevelBloc>.value(value: level),
    BlocProvider<ActivityBloc>.value(value: activity),
    BlocProvider<MerchantBloc>.value(value: merchant),
    BlocProvider<MerchantProductBloc>.value(value: merchantProduct),
    BlocProvider<AdminMerchantBloc>.value(value: adminMerchant),
    BlocProvider<DonationBloc>.value(value: donation),
    BlocProvider<AdminCampaignBloc>.value(value: adminCampaign),
    BlocProvider<AdminMissionBloc>.value(value: adminMission),
    BlocProvider<AdminRewardBloc>.value(value: adminReward),
  ];

  void dispose() {
    mission.close();
    voucher.close();
    dashboard.close();
    leaderboard.close();
    quiz.close();
    level.close();
    activity.close();
    merchant.close();
    merchantProduct.close();
    adminMerchant.close();
    donation.close();
    adminCampaign.close();
    adminMission.close();
    adminReward.close();
  }
}

/// Menampilkan onboarding sekali saja sebelum login.
///
/// Transisi Onboarding → Login terjadi DI DALAM tree (lihat [onFinished]),
/// bukan lewat `pushReplacement`. Ini penting agar route `_SessionGate` di
/// root tidak ikut terhapus — kalau terhapus, tidak ada lagi yang
/// mendengarkan [AuthBloc] sehingga login tidak langsung ke Home.
class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate();

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  bool _seen = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    OnboardingStorage()
        .hasSeenOnboarding()
        .then((seen) {
          if (mounted) setState(() => _seen = seen);
        })
        .whenComplete(() {
          if (mounted) setState(() => _loaded = true);
        });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_seen) return const LoginScreen();
    return OnboardingScreen(onFinished: () => setState(() => _seen = true));
  }
}
