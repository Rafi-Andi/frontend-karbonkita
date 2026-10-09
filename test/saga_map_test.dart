import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/bloc/auth/auth_bloc.dart';
import 'package:karbon_kita_app/bloc/dashboard/dashboard_bloc.dart';
import 'package:karbon_kita_app/bloc/quiz/quiz_bloc.dart';
import 'package:karbon_kita_app/core/network/dio_client.dart';
import 'package:karbon_kita_app/core/storage/token_storage.dart';
import 'package:karbon_kita_app/data/datasources/auth_remote_datasource.dart';
import 'package:karbon_kita_app/data/datasources/mission_remote_datasource.dart';
import 'package:karbon_kita_app/data/datasources/voucher_remote_datasource.dart';
import 'package:karbon_kita_app/data/repositories/auth_repository.dart';
import 'package:karbon_kita_app/data/repositories/mission_repository.dart';
import 'package:karbon_kita_app/data/repositories/voucher_repository.dart';
import 'package:karbon_kita_app/models/daily_quiz.dart';
import 'package:karbon_kita_app/models/quiz_node.dart';
import 'package:karbon_kita_app/models/user.dart';
import 'package:karbon_kita_app/ui/screens/quiz_level_screen.dart';
import 'package:karbon_kita_app/ui/widgets/quiz/quiz_stage_node.dart';

Map<String, dynamic> _nodeJson({
  int position = 1,
  bool playable = true,
  bool completed = false,
}) => {
  'id': position,
  'title': 'Kuis Hijau $position',
  'description': 'Deskripsi babak $position',
  'icon': 'quiz',
  'xp_reward': 50,
  'position': position,
  'quizzes_count': 2,
  'is_completed_today': completed,
  'is_playable_today': playable,
  if (playable) 'today_quiz_id': 4,
};

Map<String, dynamic> _quizJson() => {
  'id': 4,
  'mission_id': 2,
  'mission_title': 'Petualangan Kuis Hijau',
  'question': 'Warna tempat sampah untuk anorganik daur ulang?',
  'options': {'A': 'Hijau', 'B': 'Kuning', 'C': 'Merah', 'D': 'Biru'},
  'order': 0,
  'is_completed_today': false,
  'xp_reward': 30,
};

class _FakeAuthRepo extends AuthRepository {
  _FakeAuthRepo() : super(AuthRemoteDatasource(DioClient()), TokenStorage());

  @override
  Future<User?> checkSession() async => null;

  @override
  Future<void> logout() async {}
}

class _FakeMissionRepo extends MissionRepository {
  _FakeMissionRepo(this.nodes) : super(MissionRemoteDatasource(DioClient()));

  final List<QuizNode> nodes;

  @override
  Future<List<QuizNode>> getSagaNodes() async => nodes;

  @override
  Future<DailyQuiz> getDailyQuiz() async => DailyQuiz.fromJson(_quizJson());
}

Future<void> _pumpMap(WidgetTester tester, List<QuizNode> nodes) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(create: (_) => AuthBloc(_FakeAuthRepo())),
          BlocProvider<DashboardBloc>(
            create: (_) => DashboardBloc(
              VoucherRepository(VoucherRemoteDatasource(DioClient())),
            ),
          ),
          BlocProvider<QuizBloc>(
            create: (_) => QuizBloc(_FakeMissionRepo(nodes)),
          ),
        ],
        child: const QuizLevelScreen(),
      ),
    ),
  );
  // Jangan pumpAndSettle: node aktif memakai animasi pulse berulang.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('QuizLevelScreen (peta Saga dari backend)', () {
    testWidgets('2 node (DB lama) tetap tampil semua, tidak ter-clip', (
      tester,
    ) async {
      await _pumpMap(tester, [
        QuizNode.fromJson(_nodeJson(position: 1)),
        QuizNode.fromJson(_nodeJson(position: 2, playable: false)),
      ]);

      expect(find.byType(QuizStageNode), findsNWidgets(2));
      // Semua node harus muat di viewport uji 600px (peta 2 node tidak scroll).
      final size = tester.view.physicalSize / tester.view.devicePixelRatio;
      for (final node in find.byType(QuizStageNode).evaluate()) {
        final center = tester.getCenter(find.byWidget(node.widget));
        expect(
          center.dy,
          lessThan(size.height),
          reason: 'Node ter-clip di luar peta (center=$center, viewport=$size)',
        );
      }
    });

    testWidgets('5 node tampil sesuai jumlah dari backend', (tester) async {
      await _pumpMap(tester, [
        QuizNode.fromJson(_nodeJson(position: 1, playable: false)),
        QuizNode.fromJson(_nodeJson(position: 2)),
        QuizNode.fromJson(_nodeJson(position: 3, playable: false)),
        QuizNode.fromJson(_nodeJson(position: 4, playable: false)),
        QuizNode.fromJson(_nodeJson(position: 5, playable: false)),
      ]);

      expect(find.byType(QuizStageNode), findsNWidgets(5));

      // Position kecil di bawah (dy besar), besar di atas (dy kecil).
      final centers = <int, double>{};
      for (final element in find.byType(QuizStageNode).evaluate()) {
        final node = element.widget as QuizStageNode;
        centers[node.stage.number] = tester.getCenter(find.byWidget(node)).dy;
      }
      for (var position = 1; position < 5; position++) {
        expect(
          centers[position],
          greaterThan(centers[position + 1]!),
          reason: 'Node $position harus di bawah node ${position + 1}',
        );
      }
    });
  });
}
