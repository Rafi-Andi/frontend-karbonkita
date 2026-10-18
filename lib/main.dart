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
  // agar BLoC bisa dibuat ulang setiap ganti akun (lihat _AuthenticatedScope).
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
  // menentukan sesi. BLoC data justru dibuat per sesi di _AuthenticatedScope.
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
        home: _SessionGate(repositories: repositories),
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
  const _SessionGate({required this.repositories});

  final AppRepositories repositories;

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
              final user = state.user;
              final role = user?.role ?? 'warga';
              final Widget destination;
              if (role == 'mitra') {
                destination = const MerchantDashboardScreen();
              } else if (role == 'admin') {
                destination = const AdminValidationScreen();
              } else {
                destination = const HomeScreen();
              }
              // Key per user: ganti akun → seluruh BLoC data dibuang & dibuat
              // baru, sehingga tidak ada state/cache akun lama yang nyangkut.
              return _AuthenticatedScope(
                key: ValueKey('session-${user?.id ?? role}'),
                repositories: widget.repositories,
                child: destination,
              );
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
/// Saat key berubah (ganti akun) atau saat logout (subtree dilepas), state
/// di [dispose] menutup semua BLoC — state in-memory akun lama ikut hilang.
class _AuthenticatedScope extends StatefulWidget {
  const _AuthenticatedScope({
    super.key,
    required this.repositories,
    required this.child,
  });

  final AppRepositories repositories;
  final Widget child;

  @override
  State<_AuthenticatedScope> createState() => _AuthenticatedScopeState();
}

class _AuthenticatedScopeState extends State<_AuthenticatedScope> {
  late final MissionBloc _missionBloc;
  late final VoucherBloc _voucherBloc;
  late final DashboardBloc _dashboardBloc;
  late final LeaderboardBloc _leaderboardBloc;
  late final QuizBloc _quizBloc;
  late final LevelBloc _levelBloc;
  late final ActivityBloc _activityBloc;
  late final MerchantBloc _merchantBloc;
  late final MerchantProductBloc _merchantProductBloc;
  late final AdminMerchantBloc _adminMerchantBloc;
  late final DonationBloc _donationBloc;
  late final AdminCampaignBloc _adminCampaignBloc;
  late final AdminMissionBloc _adminMissionBloc;
  late final AdminRewardBloc _adminRewardBloc;

  @override
  void initState() {
    super.initState();
    final r = widget.repositories;
    _missionBloc = MissionBloc(r.mission);
    _voucherBloc = VoucherBloc(r.voucher);
    _dashboardBloc = DashboardBloc(r.voucher);
    _leaderboardBloc = LeaderboardBloc(r.leaderboard);
    _quizBloc = QuizBloc(r.mission);
    _levelBloc = LevelBloc(r.profile);
    _activityBloc = ActivityBloc(r.profile);
    _merchantBloc = MerchantBloc(r.merchant);
    _merchantProductBloc = MerchantProductBloc(r.merchant);
    _adminMerchantBloc = AdminMerchantBloc(r.adminMerchant);
    _donationBloc = DonationBloc(r.donation);
    _adminCampaignBloc = AdminCampaignBloc(r.donation);
    _adminMissionBloc = AdminMissionBloc(r.adminMission);
    _adminRewardBloc = AdminRewardBloc(r.adminReward);
  }

  @override
  void dispose() {
    _missionBloc.close();
    _voucherBloc.close();
    _dashboardBloc.close();
    _leaderboardBloc.close();
    _quizBloc.close();
    _levelBloc.close();
    _activityBloc.close();
    _merchantBloc.close();
    _merchantProductBloc.close();
    _adminMerchantBloc.close();
    _donationBloc.close();
    _adminCampaignBloc.close();
    _adminMissionBloc.close();
    _adminRewardBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _missionBloc),
        BlocProvider.value(value: _voucherBloc),
        BlocProvider.value(value: _dashboardBloc),
        BlocProvider.value(value: _leaderboardBloc),
        BlocProvider.value(value: _quizBloc),
        BlocProvider.value(value: _levelBloc),
        BlocProvider.value(value: _activityBloc),
        BlocProvider.value(value: _merchantBloc),
        BlocProvider.value(value: _merchantProductBloc),
        BlocProvider.value(value: _adminMerchantBloc),
        BlocProvider.value(value: _donationBloc),
        BlocProvider.value(value: _adminCampaignBloc),
        BlocProvider.value(value: _adminMissionBloc),
        BlocProvider.value(value: _adminRewardBloc),
      ],
      child: widget.child,
    );
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
