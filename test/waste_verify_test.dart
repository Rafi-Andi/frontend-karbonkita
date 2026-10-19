import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/bloc/mission/mission_bloc.dart';
import 'package:karbon_kita_app/bloc/mission/mission_event.dart';
import 'package:karbon_kita_app/bloc/mission/mission_state.dart';
import 'package:karbon_kita_app/core/network/auth_exception.dart';
import 'package:karbon_kita_app/core/network/dio_client.dart';
import 'package:karbon_kita_app/core/network/mission_exception.dart';
import 'package:karbon_kita_app/data/datasources/mission_remote_datasource.dart';
import 'package:karbon_kita_app/data/repositories/mission_repository.dart';
import 'package:karbon_kita_app/models/mission.dart';
import 'package:karbon_kita_app/models/verify_waste_result.dart';
import 'package:karbon_kita_app/ui/widgets/mission_scan/validation_result_sheet.dart';
import 'package:karbon_kita_app/ui/widgets/mission_scan/waste_verify_dialogs.dart';

Map<String, dynamic> _verifiedData() => {
  'duplicate': false,
  'user_mission_id': 7,
  'status': 'verified',
  'is_valid': true,
  'confidence': 92.0,
  'waste_category': 'plastic',
  'xp_earned': 300,
  'points_earned': 100,
  'new_xp': 1300,
  'new_level': 'Hijau Muda',
  'new_eco_points': 250,
  'streak_days': 3,
  'verification_note':
      'AI mengenali foto ini sebagai plastik dengan keyakinan 92%.',
};

Map<String, dynamic> _rejectedData() => {
  'user_mission_id': 8,
  'status': 'rejected',
  'is_valid': false,
  'confidence': 40.0,
  'waste_category': 'unknown',
  'rejection_reason': 'AI menilai foto ini belum memenuhi kriteria misi.',
  'ai_reason': 'Foto terlalu gelap sehingga sampah tidak terlihat jelas.',
  'hint': 'Foto ulang dari jarak dekat dengan pencahayaan cukup.',
  'xp_earned': 0,
  'points_earned': 0,
};

/// Datasource sukses: kembalikan envelope backend apa adanya.
class _OkDatasource extends MissionRemoteDatasource {
  _OkDatasource(this.envelope) : super(DioClient());

  final Map<String, dynamic> envelope;

  @override
  Future<Map<String, dynamic>> verifyWaste({
    required int missionId,
    required String imagePath,
  }) async => envelope;
}

/// Datasource gagal: lempar AuthException seperti DioClient saat HTTP error.
class _ErrorDatasource extends MissionRemoteDatasource {
  _ErrorDatasource(this.error) : super(DioClient());

  final AuthException error;

  @override
  Future<Map<String, dynamic>> verifyWaste({
    required int missionId,
    required String imagePath,
  }) async {
    throw error;
  }
}

class FakeWasteRepository extends MissionRepository {
  FakeWasteRepository({this.result, this.error})
    : super(MissionRemoteDatasource(DioClient()));

  VerifyWasteResult? result;
  Exception? error;

  @override
  Future<VerifyWasteResult> verifyWaste({
    required int missionId,
    required String imagePath,
  }) async {
    if (error != null) throw error!;
    return result!;
  }

  @override
  Future<List<Mission>> getActiveMissions() async => [];
}

void main() {
  group('VerifyWasteResult parsing (kontrak MissionController)', () {
    test('fromJson baca 201 verified + reward + progres', () {
      final result = VerifyWasteResult.fromJson(_verifiedData());

      expect(result.verified, true);
      expect(result.userMissionId, 7);
      expect(result.confidence, 92.0);
      expect(result.wasteCategory, 'plastic');
      expect(result.categoryLabel, 'Plastik Terpilah');
      expect(result.xpEarned, 300);
      expect(result.pointsEarned, 100);
      expect(result.newLevel, 'Hijau Muda');
      expect(result.streakDays, 3);
      expect(result.verificationNote, contains('keyakinan 92%'));
    });

    test('fromJson baca 200 rejected + rejection_reason', () {
      final result = VerifyWasteResult.fromJson(_rejectedData());

      expect(result.verified, false);
      expect(result.status, 'rejected');
      expect(result.xpEarned, 0);
      expect(result.pointsEarned, 0);
      expect(result.rejectionReason, contains('kriteria misi'));
      expect(result.aiReason, contains('terlalu gelap'));
      expect(result.hint, contains('pencahayaan'));
    });

    test('kategori tak dikenal -> label generik', () {
      final result = VerifyWasteResult.fromJson({
        ..._rejectedData(),
        'waste_category': 'misteri',
      });

      expect(result.categoryLabel, 'Sampah Terpilah');
    });

    test("kategori 'unknown' (foto ditolak) -> 'Belum dikenali'", () {
      final result = VerifyWasteResult.fromJson(_rejectedData());

      expect(result.wasteCategory, 'unknown');
      expect(result.categoryLabel, 'Belum dikenali');
    });
  });

  group('MissionRepository.verifyWaste', () {
    test('envelope 201 -> VerifyWasteResult', () async {
      final repo = MissionRepository(
        _OkDatasource({'success': true, 'data': _verifiedData()}),
      );

      final result = await repo.verifyWaste(
        missionId: 1,
        imagePath: '/tmp/foto.jpg',
      );

      expect(result.verified, true);
      expect(result.pointsEarned, 100);
    });

    test('409 duplicate diteruskan dengan data backend', () async {
      final repo = MissionRepository(
        _ErrorDatasource(
          const AuthException(
            'Duplicate image.',
            statusCode: 409,
            data: {'user_mission_id': 9, 'status': 'rejected'},
          ),
        ),
      );

      try {
        await repo.verifyWaste(missionId: 1, imagePath: '/tmp/foto.jpg');
        fail('harus lempar');
      } on MissionException catch (e) {
        expect(e.statusCode, 409);
        expect(e.data?['status'], 'rejected');
      }
    });
  });

  group('MissionBloc waste verify', () {
    test('201 -> uploading lalu verified + hasil', () async {
      final bloc = MissionBloc(
        FakeWasteRepository(
          result: VerifyWasteResult.fromJson(_verifiedData()),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MissionState>(
            (s) =>
                s.wasteVerifyStatus == WasteVerifyStatus.verified &&
                s.verifyResult?.xpEarned == 300,
          ),
        ),
      );
      bloc.add(
        const WasteVerifyRequested(missionId: 1, imagePath: '/tmp/foto.jpg'),
      );
      await future;
      await bloc.close();
    });

    test('200 AI rejected -> status rejected + xp 0', () async {
      final bloc = MissionBloc(
        FakeWasteRepository(
          result: VerifyWasteResult.fromJson(_rejectedData()),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MissionState>(
            (s) =>
                s.wasteVerifyStatus == WasteVerifyStatus.rejected &&
                s.verifyResult?.xpEarned == 0,
          ),
        ),
      );
      bloc.add(
        const WasteVerifyRequested(missionId: 1, imagePath: '/tmp/foto.jpg'),
      );
      await future;
      await bloc.close();
    });

    test('409 foto duplikat -> status duplicate', () async {
      final bloc = MissionBloc(
        FakeWasteRepository(
          error: const MissionException(
            'Duplicate image.',
            statusCode: 409,
            data: {'user_mission_id': 9, 'status': 'rejected'},
          ),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MissionState>(
            (s) => s.wasteVerifyStatus == WasteVerifyStatus.duplicate,
          ),
        ),
      );
      bloc.add(
        const WasteVerifyRequested(missionId: 1, imagePath: '/tmp/foto.jpg'),
      );
      await future;
      await bloc.close();
    });

    test('409 daily-cap -> status dailyCapped', () async {
      final bloc = MissionBloc(
        FakeWasteRepository(
          error: const MissionException(
            'Misi sudah diselesaikan hari ini.',
            statusCode: 409,
            data: {'mission_id': 1, 'already_completed_today': true},
          ),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MissionState>(
            (s) => s.wasteVerifyStatus == WasteVerifyStatus.dailyCapped,
          ),
        ),
      );
      bloc.add(
        const WasteVerifyRequested(missionId: 1, imagePath: '/tmp/foto.jpg'),
      );
      await future;
      await bloc.close();
    });

    test('503 AI down -> status pendingReview', () async {
      final bloc = MissionBloc(
        FakeWasteRepository(
          error: const MissionException(
            'AI validation temporarily unavailable.',
            statusCode: 503,
            data: {'user_mission_id': 10, 'status': 'pending'},
          ),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MissionState>(
            (s) => s.wasteVerifyStatus == WasteVerifyStatus.pendingReview,
          ),
        ),
      );
      bloc.add(
        const WasteVerifyRequested(missionId: 1, imagePath: '/tmp/foto.jpg'),
      );
      await future;
      await bloc.close();
    });

    test('503: pesan dialog pakai alasan Indonesia dari data backend', () async {
      final bloc = MissionBloc(
        FakeWasteRepository(
          error: const MissionException(
            'AI validation temporarily unavailable. Please try again later.',
            statusCode: 503,
            data: {
              'user_mission_id': 10,
              'status': 'pending',
              'rejection_reason':
                  'Validasi AI sedang tidak tersedia, jadi foto ini belum bisa dinilai.',
              'hint':
                  'Tidak ada poin yang hilang. Coba unggah lagi beberapa saat lagi.',
            },
          ),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MissionState>(
            (s) =>
                s.wasteVerifyStatus == WasteVerifyStatus.pendingReview &&
                (s.wasteVerifyErrorMessage ?? '').contains('tidak tersedia'),
          ),
        ),
      );
      bloc.add(
        const WasteVerifyRequested(missionId: 1, imagePath: '/tmp/foto.jpg'),
      );
      await future;
      await bloc.close();
    });

    test('409 duplikat: pesan dialog pakai alasan Indonesia', () async {
      final bloc = MissionBloc(
        FakeWasteRepository(
          error: const MissionException(
            'Duplicate image.',
            statusCode: 409,
            data: {
              'user_mission_id': 9,
              'status': 'rejected',
              'rejection_reason':
                  'Foto ini sudah pernah dikirim sebelumnya. Setiap foto hanya boleh dipakai sekali.',
              'hint':
                  'Ambil foto baru dari kondisi saat ini - foto lama yang sama tidak bisa dipakai dua kali.',
            },
          ),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MissionState>(
            (s) =>
                s.wasteVerifyStatus == WasteVerifyStatus.duplicate &&
                (s.wasteVerifyErrorMessage ?? '').contains(
                  'sudah pernah dikirim',
                ),
          ),
        ),
      );
      bloc.add(
        const WasteVerifyRequested(missionId: 1, imagePath: '/tmp/foto.jpg'),
      );
      await future;
      await bloc.close();
    });

    test('422 validasi -> status failure', () async {
      final bloc = MissionBloc(
        FakeWasteRepository(
          error: const MissionException('Validation failed.', statusCode: 422),
        ),
      );
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MissionState>(
            (s) =>
                s.wasteVerifyStatus == WasteVerifyStatus.failure &&
                s.wasteVerifyErrorMessage == 'Validation failed.',
          ),
        ),
      );
      bloc.add(
        const WasteVerifyRequested(missionId: 1, imagePath: '/tmp/foto.jpg'),
      );
      await future;
      await bloc.close();
    });

    test('reset -> kembali initial + hasil dibersihkan', () async {
      final bloc = MissionBloc(
        FakeWasteRepository(
          result: VerifyWasteResult.fromJson(_verifiedData()),
        ),
      );
      final verified = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MissionState>(
            (s) => s.wasteVerifyStatus == WasteVerifyStatus.verified,
          ),
        ),
      );
      bloc.add(
        const WasteVerifyRequested(missionId: 1, imagePath: '/tmp/foto.jpg'),
      );
      await verified;
      final reset = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<MissionState>(
            (s) =>
                s.wasteVerifyStatus == WasteVerifyStatus.initial &&
                s.verifyResult == null,
          ),
        ),
      );
      bloc.add(const WasteVerifyReset());
      await reset;
      await bloc.close();
    });
  });

  group('ValidationResultSheet menampilkan alasan', () {
    Future<void> pumpSheet(
      WidgetTester tester,
      VerifyWasteResult result,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValidationResultSheet(result: result, onContinue: () {}),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('ditolak: alasan + catatan AI + saran tampil', (tester) async {
      await pumpSheet(tester, VerifyWasteResult.fromJson(_rejectedData()));

      expect(find.text('Validasi AI Vision'), findsOneWidget);
      expect(find.text('Ditolak AI'), findsOneWidget);
      expect(find.textContaining('kriteria misi'), findsOneWidget);
      expect(find.text('Catatan AI'), findsOneWidget);
      expect(find.textContaining('terlalu gelap'), findsOneWidget);
      expect(find.text('Agar foto diterima'), findsOneWidget);
      expect(find.textContaining('pencahayaan'), findsOneWidget);
    });

    testWidgets('diterima: verification_note tampil', (tester) async {
      await pumpSheet(tester, VerifyWasteResult.fromJson(_verifiedData()));

      expect(find.text('Sukses!'), findsOneWidget);
      expect(find.textContaining('keyakinan 92%'), findsOneWidget);
      expect(find.text('Catatan AI'), findsNothing);
    });

    testWidgets('backend lama tanpa field alasan tetap aman', (tester) async {
      final result = VerifyWasteResult.fromJson({
        'user_mission_id': 11,
        'status': 'rejected',
        'is_valid': false,
        'confidence': 20.0,
        'waste_category': 'unknown',
        'xp_earned': 0,
        'points_earned': 0,
      });

      await pumpSheet(tester, result);

      expect(find.text('Ditolak AI'), findsOneWidget);
      expect(
        find.text('Foto tidak sesuai misi. Coba foto lain.'),
        findsOneWidget,
      );
      expect(find.text('Catatan AI'), findsNothing);
      expect(find.text('Agar foto diterima'), findsNothing);
    });
  });

  group('Dialog penolakan memakai saran dari backend', () {
    Future<void> pumpDialog(
      WidgetTester tester,
      Future<void> Function(BuildContext) open,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => open(context),
                child: const Text('buka'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();
    }

    testWidgets('503: alasan + hint backend tampil, bukan pesan Inggris', (
      tester,
    ) async {
      await pumpDialog(
        tester,
        (context) => showPendingWasteDialog(
          context,
          message:
              'Validasi AI sedang tidak tersedia, jadi foto ini belum bisa dinilai.',
          hint:
              'Tidak ada poin yang hilang. Coba unggah lagi beberapa saat lagi.',
          onRetry: () {},
          onBackToMissions: () {},
        ),
      );

      expect(find.text('AI Sedang Sibuk'), findsOneWidget);
      expect(find.textContaining('sedang tidak tersedia'), findsOneWidget);
      expect(find.textContaining('Tidak ada poin yang hilang'), findsOneWidget);
      expect(find.textContaining('temporarily unavailable'), findsNothing);
    });

    testWidgets('tanpa hint backend: saran bawaan tetap tampil', (
      tester,
    ) async {
      await pumpDialog(
        tester,
        (context) => showDuplicateWasteDialog(
          context,
          message: 'Foto ini sudah pernah dikirim sebelumnya.',
          onBackToMissions: () {},
        ),
      );

      expect(
        find.textContaining('Sistem anti-fraud menolak foto duplikat'),
        findsOneWidget,
      );
    });
  });
}
