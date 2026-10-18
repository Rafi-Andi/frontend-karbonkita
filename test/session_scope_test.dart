import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:karbon_kita_app/bloc/auth/auth_bloc.dart';
import 'package:karbon_kita_app/bloc/auth/auth_event.dart';
import 'package:karbon_kita_app/core/network/connectivity_service.dart';
import 'package:karbon_kita_app/core/storage/onboarding_storage.dart';
import 'package:karbon_kita_app/data/repositories/admin_merchant_repository.dart';
import 'package:karbon_kita_app/data/repositories/admin_mission_repository.dart';
import 'package:karbon_kita_app/data/repositories/admin_reward_repository.dart';
import 'package:karbon_kita_app/data/repositories/auth_repository.dart';
import 'package:karbon_kita_app/data/repositories/donation_repository.dart';
import 'package:karbon_kita_app/data/repositories/leaderboard_repository.dart';
import 'package:karbon_kita_app/data/repositories/merchant_repository.dart';
import 'package:karbon_kita_app/data/repositories/mission_repository.dart';
import 'package:karbon_kita_app/data/repositories/profile_repository.dart';
import 'package:karbon_kita_app/data/repositories/voucher_repository.dart';
import 'package:karbon_kita_app/main.dart';
import 'package:karbon_kita_app/models/user.dart';
import 'package:karbon_kita_app/ui/screens/campaign_manage_screen.dart';
import 'package:karbon_kita_app/ui/screens/donation_screen.dart';
import 'package:karbon_kita_app/ui/screens/dompet_voucher_screen.dart';
import 'package:karbon_kita_app/ui/screens/home_screen.dart';
import 'package:karbon_kita_app/ui/screens/merchant_products_screen.dart';
import 'package:karbon_kita_app/ui/screens/misi_scan_screen.dart';
import 'package:karbon_kita_app/ui/screens/mission_manage_screen.dart';
import 'package:karbon_kita_app/ui/screens/quiz_level_screen.dart';
import 'package:karbon_kita_app/ui/screens/reward_manage_screen.dart';
import 'package:karbon_kita_app/ui/screens/riwayat_pencairan_screen.dart';
import 'package:karbon_kita_app/ui/screens/scan_voucher_screen.dart';

/// Repositori palsu: semua panggilan "menggantung" tanpa jaringan sehingga
/// BLoC tetap di state loading — layar tetap bisa di-render tanpa server.
///
/// `Future<Never>` valid untuk SEMUA `Future<T>` (Never subtipe dari semua
/// tipe), jadi forwarder `noSuchMethod` tidak pernah kena cast error.
class _PendingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Completer<Never>().future;
}

class _StubMissionRepository extends _PendingRepository
    implements MissionRepository {}

class _StubVoucherRepository extends _PendingRepository
    implements VoucherRepository {}

class _StubLeaderboardRepository extends _PendingRepository
    implements LeaderboardRepository {}

class _StubProfileRepository extends _PendingRepository
    implements ProfileRepository {}

class _StubMerchantRepository extends _PendingRepository
    implements MerchantRepository {}

class _StubDonationRepository extends _PendingRepository
    implements DonationRepository {}

class _StubAdminMerchantRepository extends _PendingRepository
    implements AdminMerchantRepository {}

class _StubAdminMissionRepository extends _PendingRepository
    implements AdminMissionRepository {}

class _StubAdminRewardRepository extends _PendingRepository
    implements AdminRewardRepository {}

class _FakeAuthRepository extends _PendingRepository implements AuthRepository {
  _FakeAuthRepository({this.user});

  User? user;

  @override
  Future<User?> checkSession() async => user;

  @override
  Future<void> logout() async {}
}

AppRepositories _buildRepositories() => AppRepositories(
  mission: _StubMissionRepository(),
  voucher: _StubVoucherRepository(),
  leaderboard: _StubLeaderboardRepository(),
  profile: _StubProfileRepository(),
  merchant: _StubMerchantRepository(),
  donation: _StubDonationRepository(),
  adminMerchant: _StubAdminMerchantRepository(),
  adminMission: _StubAdminMissionRepository(),
  adminReward: _StubAdminRewardRepository(),
);

void main() {
  testWidgets('halaman hasil Navigator.push bisa membaca BLoC sesi '
      '(regresi layar putih APK b70062d)', (tester) async {
    final authBloc = AuthBloc(
      _FakeAuthRepository(
        user: const User(
          id: 1,
          name: 'Warga Uji',
          role: 'warga',
          kota: 'Surabaya',
        ),
      ),
    )..add(const SessionChecked());
    addTearDown(authBloc.close);

    await tester.pumpWidget(
      MyApp(
        authBloc: authBloc,
        repositories: _buildRepositories(),
        connectivity: ConnectivityService(),
      ),
    );

    // Selesaikan splash (2 detik) + seluruh microtask sesi.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.byType(HomeScreen), findsOneWidget);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));

    Future<void> openAndClose(Widget screen) async {
      navigator.push(MaterialPageRoute<void>(builder: (_) => screen));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester.takeException(),
        isNull,
        reason: '${screen.runtimeType} gagal dirender',
      );
      expect(find.byWidget(screen), findsOneWidget);
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    // Tiga halaman yang dilaporkan putih di APK: dompet voucher, donasi,
    // dan level kuis.
    await openAndClose(const DompetVoucherScreen());
    await openAndClose(const DonationScreen());
    await openAndClose(const QuizLevelScreen());

    // Halaman lain yang juga di-push dan memakai BLoC sesi (admin & mitra).
    await openAndClose(const RewardManageScreen());
    await openAndClose(const MissionManageScreen());
    await openAndClose(const CampaignManageScreen());
    await openAndClose(const MerchantProductsScreen());
    await openAndClose(const RiwayatPencairanScreen());
    await openAndClose(const ScanVoucherScreen());
    await openAndClose(const MisiScanScreen());

    // Bersihkan tree agar tidak ada timer/animasi tersisa.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('logout saat halaman push masih terbuka tidak melempar error', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({OnboardingStorage.seenKey: true});
    final authRepository = _FakeAuthRepository(
      user: const User(
        id: 7,
        name: 'Warga Logout',
        role: 'warga',
        kota: 'Bandung',
      ),
    );
    final authBloc = AuthBloc(authRepository)..add(const SessionChecked());
    addTearDown(authBloc.close);

    await tester.pumpWidget(
      MyApp(
        authBloc: authBloc,
        repositories: _buildRepositories(),
        connectivity: ConnectivityService(),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.byType(HomeScreen), findsOneWidget);

    // Buka halaman push, lalu logout selagi route-nya masih di atas.
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(MaterialPageRoute<void>(builder: (_) => const DonationScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(DonationScreen), findsOneWidget);

    authBloc.add(const LoggedOut());
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Route push sudah ditutup, dan tidak ada BLoC yang dipakai setelah close.
    expect(find.byType(DonationScreen), findsNothing);
    expect(tester.takeException(), isNull);

    // Login lagi sebagai akun berbeda → BLoC sesi dibuat ulang tanpa error.
    // (Sengaja pakai SessionChecked: event login asli akan menahan close()
    // karena repository palsu tidak pernah menjawab.)
    authRepository.user = const User(
      id: 8,
      name: 'Warga Kedua',
      role: 'warga',
      kota: 'Medan',
    );
    authBloc.add(const SessionChecked());
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
