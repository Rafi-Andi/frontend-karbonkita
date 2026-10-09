import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_event.dart';
import 'bloc/auth/auth_state.dart';
import 'bloc/activity/activity_bloc.dart';
import 'bloc/admin_merchant/admin_merchant_bloc.dart';
import 'bloc/admin_mission/admin_mission_bloc.dart';
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
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/donation_remote_datasource.dart';
import 'data/datasources/leaderboard_remote_datasource.dart';
import 'data/datasources/merchant_remote_datasource.dart';
import 'data/datasources/mission_remote_datasource.dart';
import 'data/datasources/profile_remote_datasource.dart';
import 'data/datasources/voucher_remote_datasource.dart';
import 'data/repositories/admin_merchant_repository.dart';
import 'data/repositories/admin_mission_repository.dart';
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
  final missionRepository = MissionRepository(
    MissionRemoteDatasource(dioClient),
    cache: cache,
    storage: storage,
  );
  final voucherRepository = VoucherRepository(
    VoucherRemoteDatasource(dioClient),
    cache: cache,
    storage: storage,
  );

  final authBloc = AuthBloc(authRepository)..add(const SessionChecked());
  final missionBloc = MissionBloc(missionRepository);
  final voucherBloc = VoucherBloc(voucherRepository);
  final dashboardBloc = DashboardBloc(voucherRepository);
  final leaderboardBloc = LeaderboardBloc(
    LeaderboardRepository(LeaderboardRemoteDatasource(dioClient), cache: cache),
  );
  final quizBloc = QuizBloc(missionRepository);
  final profileRepository = ProfileRepository(
    ProfileRemoteDatasource(dioClient),
    cache: cache,
    storage: storage,
  );
  final levelBloc = LevelBloc(profileRepository);
  final activityBloc = ActivityBloc(profileRepository);
  final merchantRepository = MerchantRepository(
    MerchantRemoteDatasource(dioClient),
    cache: cache,
    storage: storage,
  );
  final merchantBloc = MerchantBloc(merchantRepository);
  final merchantProductBloc = MerchantProductBloc(merchantRepository);
  final adminMerchantBloc = AdminMerchantBloc(
    AdminMerchantRepository(AdminMerchantRemoteDatasource(dioClient)),
  );
  final donationRepository = DonationRepository(
    DonationRemoteDatasource(dioClient),
  );
  final donationBloc = DonationBloc(donationRepository);
  final adminCampaignBloc = AdminCampaignBloc(donationRepository);
  final adminMissionBloc = AdminMissionBloc(
    AdminMissionRepository(AdminMissionRemoteDatasource(dioClient)),
  );

  runApp(
    MyApp(
      authBloc: authBloc,
      missionBloc: missionBloc,
      voucherBloc: voucherBloc,
      dashboardBloc: dashboardBloc,
      leaderboardBloc: leaderboardBloc,
      quizBloc: quizBloc,
      levelBloc: levelBloc,
      activityBloc: activityBloc,
      merchantBloc: merchantBloc,
      merchantProductBloc: merchantProductBloc,
      adminMerchantBloc: adminMerchantBloc,
      donationBloc: donationBloc,
      adminCampaignBloc: adminCampaignBloc,
      adminMissionBloc: adminMissionBloc,
      connectivity: connectivity,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.authBloc,
    required this.missionBloc,
    required this.voucherBloc,
    required this.dashboardBloc,
    required this.leaderboardBloc,
    required this.quizBloc,
    required this.levelBloc,
    required this.activityBloc,
    required this.merchantBloc,
    required this.merchantProductBloc,
    required this.adminMerchantBloc,
    required this.donationBloc,
    required this.adminCampaignBloc,
    required this.adminMissionBloc,
    required this.connectivity,
  });

  final AuthBloc authBloc;
  final MissionBloc missionBloc;
  final VoucherBloc voucherBloc;
  final DashboardBloc dashboardBloc;
  final LeaderboardBloc leaderboardBloc;
  final QuizBloc quizBloc;
  final LevelBloc levelBloc;
  final ActivityBloc activityBloc;
  final MerchantBloc merchantBloc;
  final MerchantProductBloc merchantProductBloc;
  final AdminMerchantBloc adminMerchantBloc;
  final DonationBloc donationBloc;
  final AdminCampaignBloc adminCampaignBloc;
  final AdminMissionBloc adminMissionBloc;
  final ConnectivityService connectivity;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
        BlocProvider.value(value: missionBloc),
        BlocProvider.value(value: voucherBloc),
        BlocProvider.value(value: dashboardBloc),
        BlocProvider.value(value: leaderboardBloc),
        BlocProvider.value(value: quizBloc),
        BlocProvider.value(value: levelBloc),
        BlocProvider.value(value: activityBloc),
        BlocProvider.value(value: merchantBloc),
        BlocProvider.value(value: merchantProductBloc),
        BlocProvider.value(value: adminMerchantBloc),
        BlocProvider.value(value: donationBloc),
        BlocProvider.value(value: adminCampaignBloc),
        BlocProvider.value(value: adminMissionBloc),
      ],
      child: MaterialApp(
        title: 'KarbonKita',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const _SessionGate(),
      ),
    );
  }
}

/// Auto-login: token permanen → langsung Home, tanpa token → Onboarding
/// (sekali saja) → Login.
/// Offline: profil lokal tetap dianggap sesi agar cache offline tampil.
class _SessionGate extends StatelessWidget {
  const _SessionGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.initial:
          case AuthStatus.checking:
          case AuthStatus.loading:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.authenticated:
            final role = state.user?.role ?? 'warga';
            if (role == 'mitra') return const MerchantDashboardScreen();
            if (role == 'admin') return const AdminValidationScreen();
            return const HomeScreen();
          case AuthStatus.unauthenticated:
            return const _OnboardingGate();
        }
      },
    );
  }
}

/// Menampilkan onboarding sekali saja sebelum login.
class _OnboardingGate extends StatelessWidget {
  const _OnboardingGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: OnboardingStorage().hasSeenOnboarding(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) return const LoginScreen();
        return const OnboardingScreen();
      },
    );
  }
}
