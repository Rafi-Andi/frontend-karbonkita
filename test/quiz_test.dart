import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/bloc/quiz/quiz_bloc.dart';
import 'package:karbon_kita_app/bloc/quiz/quiz_event.dart';
import 'package:karbon_kita_app/bloc/quiz/quiz_state.dart';
import 'package:karbon_kita_app/core/network/auth_exception.dart';
import 'package:karbon_kita_app/core/network/dio_client.dart';
import 'package:karbon_kita_app/core/network/mission_exception.dart';
import 'package:karbon_kita_app/data/datasources/mission_remote_datasource.dart';
import 'package:karbon_kita_app/data/repositories/mission_repository.dart';
import 'package:karbon_kita_app/models/daily_quiz.dart';
import 'package:karbon_kita_app/models/quiz_node.dart';
import 'package:karbon_kita_app/models/quiz_session.dart';

Map<String, dynamic> _sessionQuestion(int i, {bool? correct}) => {
  'id': 10 + i,
  'mission_id': 2,
  'question': 'Soal sesi ${i + 1}?',
  'options': {'A': 'Salah', 'B': 'Benar', 'C': 'Salah', 'D': 'Salah'},
  'order': i,
  'is_answered_today': correct != null,
  'was_correct': correct,
};

QuizSession _session({int answered = 0, int correct = 0}) =>
    QuizSession.fromJson({
      'mission_id': 2,
      'mission_title': 'Petualangan Kuis Hijau',
      'session_date': '2026-09-18',
      'total': 2,
      'xp_per_question': 10,
      'questions': [
        _sessionQuestion(0, correct: answered > 0 ? 0 < correct : null),
        _sessionQuestion(1, correct: answered > 1 ? 1 < correct : null),
      ],
    });

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

Map<String, dynamic> _quizJson({bool completed = false}) => {
  'id': 4,
  'mission_id': 9,
  'mission_title': 'Kuis Pilah Sampah',
  'question': 'Warna tempat sampah untuk anorganik daur ulang?',
  'options': {'A': 'Hijau', 'B': 'Kuning', 'C': 'Merah', 'D': 'Biru'},
  'order': 0,
  'is_completed_today': completed,
  'xp_reward': 50,
  if (completed) 'correct_answer': 'B',
  if (completed) 'explanation': 'Kuning untuk anorganik daur ulang.',
};

/// Datasource yang selalu gagal seperti Dio saat HTTP error.
class _ThrowingDatasource extends MissionRemoteDatasource {
  _ThrowingDatasource() : super(DioClient());

  @override
  Future<DailyQuiz> fetchDailyQuiz() {
    throw const AuthException('Salah.', statusCode: 422);
  }
}

class FakeMissionRepository extends MissionRepository {
  FakeMissionRepository({
    this.quiz,
    this.answer,
    this.error,
    this.nodes = const [],
    this.session,
  }) : super(MissionRemoteDatasource(DioClient()));

  DailyQuiz? quiz;
  QuizAnswerResult? answer;
  Exception? error;
  List<QuizNode> nodes;
  QuizSession? session;

  @override
  Future<DailyQuiz> getDailyQuiz() async {
    if (error != null) throw error!;
    return quiz!;
  }

  @override
  Future<List<QuizNode>> getSagaNodes() async {
    if (error != null) throw error!;
    return nodes;
  }

  @override
  Future<QuizSession> getNodeQuestions(int missionId) async {
    if (error != null) throw error!;
    return session!;
  }

  @override
  Future<QuizAnswerResult> answerQuiz({
    required int quizId,
    required String answer,
  }) async {
    if (error != null) throw error!;
    return this.answer!;
  }
}

void main() {
  group('DailyQuiz parsing (kontrak QuizResource)', () {
    test('fromJson baca soal + opsi map + belum selesai', () {
      final quiz = DailyQuiz.fromJson(_quizJson());

      expect(quiz.id, 4);
      expect(quiz.missionTitle, 'Kuis Pilah Sampah');
      expect(quiz.options, hasLength(4));
      expect(quiz.options[1].label, 'B');
      expect(quiz.options[1].text, 'Kuning');
      expect(quiz.isCompletedToday, isFalse);
      expect(quiz.correctAnswer, isNull);
      expect(quiz.explanation, isNull);
      expect(quiz.xpReward, 50);
    });

    test('selesai -> correct_answer + explanation tersedia', () {
      final quiz = DailyQuiz.fromJson(_quizJson(completed: true));

      expect(quiz.isCompletedToday, isTrue);
      expect(quiz.correctAnswer, 'B');
      expect(quiz.explanation, contains('Kuning'));
    });

    test('toMission untuk daftar misi tab Misi', () {
      final mission = DailyQuiz.fromJson(_quizJson()).toMission();
      expect(mission.category, 'quiz');
      expect(mission.xpReward, 50);
      expect(mission.pointsReward, 0);
    });
  });

  group('QuizAnswerResult parsing', () {
    test('fromJson baca benar + reward', () {
      final result = QuizAnswerResult.fromJson({
        'is_correct': true,
        'xp_earned': 50,
        'new_xp': 2400,
        'new_level': 'Earth Warrior 7',
        'streak_days': 8,
        'user_mission_id': 11,
      });
      expect(result.isCorrect, isTrue);
      expect(result.xpEarned, 50);
      expect(result.newLevel, 'Earth Warrior 7');
      expect(result.attemptsToday, 0);
    });
  });

  group('QuizNode parsing (kontrak SagaNodeResource)', () {
    test('fromJson baca node playable + today_quiz_id', () {
      final node = QuizNode.fromJson(_nodeJson());

      expect(node.id, 1);
      expect(node.title, 'Kuis Hijau 1');
      expect(node.position, 1);
      expect(node.quizzesCount, 2);
      expect(node.xpReward, 50);
      expect(node.isPlayableToday, isTrue);
      expect(node.todayQuizId, 4);
    });

    test('node locked tidak bawa today_quiz_id', () {
      final node = QuizNode.fromJson(_nodeJson(position: 2, playable: false));

      expect(node.isPlayableToday, isFalse);
      expect(node.todayQuizId, isNull);
    });

    test('node selesai persisten (is_completed) tetap tampil done', () {
      final node = QuizNode.fromJson({
        ..._nodeJson(position: 1, playable: false, completed: false),
        'is_completed': true,
      });

      expect(node.isCompleted, isTrue);
      expect(node.isDone, isTrue);
      expect(node.isPlayableToday, isFalse);
    });

    test('tepat 1 playable dari daftar backend', () {
      final nodes = [
        QuizNode.fromJson(_nodeJson(position: 1, playable: false)),
        QuizNode.fromJson(_nodeJson(position: 2)),
        QuizNode.fromJson(_nodeJson(position: 3, playable: false)),
      ];
      expect(nodes.where((n) => n.isPlayableToday), hasLength(1));
    });
  });

  group('QuizSession parsing (kontrak questions)', () {
    test('fromJson baca 5 info sesi + daftar soal', () {
      final session = _session();

      expect(session.missionId, 2);
      expect(session.total, 2);
      expect(session.xpPerQuestion, 10);
      expect(session.questions, hasLength(2));
      expect(session.firstUnansweredIndex, 0);
      expect(session.isFinished, isFalse);
    });

    test('soal terjawab bawa was_correct + kunci', () {
      final session = _session(answered: 1, correct: 0);

      expect(session.questions[0].isCompletedToday, isTrue);
      expect(session.questions[0].wasCorrect, isFalse);
      expect(session.questions[1].wasCorrect, isNull);
      expect(session.firstUnansweredIndex, 1);
    });

    test('semua terjawab -> isFinished', () {
      expect(_session(answered: 2, correct: 2).isFinished, isTrue);
    });
  });

  group('QuizBloc', () {
    test('loaded -> status loaded + soal', () async {
      final bloc = FakeMissionRepository(quiz: DailyQuiz.fromJson(_quizJson()));
      final quizBloc = QuizBloc(bloc);
      final future = expectLater(
        quizBloc.stream,
        emitsThrough(
          predicate<QuizState>(
            (s) =>
                s.status == QuizStatus.loaded &&
                s.quiz?.question.contains('anorganik') == true,
          ),
        ),
      );
      quizBloc.add(const DailyQuizLoaded());
      await future;
      await quizBloc.close();
    });

    test('jawab benar -> result + quiz di-refresh', () async {
      final repo = FakeMissionRepository(
        quiz: DailyQuiz.fromJson(_quizJson()),
        answer: QuizAnswerResult.fromJson({
          'is_correct': true,
          'xp_earned': 10,
          'new_xp': 2400,
          'new_level': 'Earth Warrior 7',
          'streak_days': 8,
          'user_mission_id': 11,
          'node_completed': false,
          'remaining': 1,
          'session_correct': 1,
          'session_xp': 10,
        }),
        session: _session(),
      );
      final quizBloc = QuizBloc(repo);
      // Muat sesi 2 soal, lalu jawab soal pertama dengan benar.
      final loaded = expectLater(
        quizBloc.stream,
        emitsThrough(
          predicate<QuizState>(
            (s) =>
                s.sessionStatus == SessionStatus.loaded &&
                s.session?.questions.length == 2,
          ),
        ),
      );
      quizBloc.add(const NodeSessionLoaded(2));
      await loaded;

      // Setelah benar, bloc refetch -> result benar, index tetap (Lanjut manual).
      repo.session = _session(answered: 1, correct: 1);
      final answered = expectLater(
        quizBloc.stream,
        emitsThrough(
          predicate<QuizState>(
            (s) =>
                s.status == QuizStatus.loaded &&
                s.lastResult?.isCorrect == true &&
                s.sessionIndex == 0,
          ),
        ),
      );
      quizBloc.add(const QuizAnswered('B'));
      await answered;

      // Lanjut -> pindah ke soal kedua, result di-reset.
      final next = expectLater(
        quizBloc.stream,
        emitsThrough(
          predicate<QuizState>(
            (s) => s.sessionIndex == 1 && s.lastResult == null,
          ),
        ),
      );
      quizBloc.add(const SessionQuestionNext());
      await next;
      await quizBloc.close();
    });

    test('jawab salah -> hangus, tidak bisa retry soal yang sama', () async {
      final repo = FakeMissionRepository(
        quiz: DailyQuiz.fromJson(_quizJson()),
        answer: QuizAnswerResult.fromJson({
          'is_correct': false,
          'xp_earned': 0,
          'user_mission_id': 12,
          'node_completed': false,
          'remaining': 1,
          'session_correct': 0,
          'session_xp': 0,
        }),
        session: _session(),
      );
      final quizBloc = QuizBloc(repo);
      final loaded = expectLater(
        quizBloc.stream,
        emitsThrough(
          predicate<QuizState>((s) => s.sessionStatus == SessionStatus.loaded),
        ),
      );
      quizBloc.add(const NodeSessionLoaded(2));
      await loaded;

      repo.session = _session(answered: 1, correct: 0);
      final answered = expectLater(
        quizBloc.stream,
        emitsThrough(
          predicate<QuizState>(
            (s) =>
                s.status == QuizStatus.loaded &&
                s.lastResult?.isCorrect == false,
          ),
        ),
      );
      quizBloc.add(const QuizAnswered('A'));
      await answered;

      // Kirim lagi soal yang sama -> diabaikan (hangus), result tetap salah.
      quizBloc.add(const QuizAnswered('B'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(quizBloc.state.lastResult?.isCorrect, isFalse);
      expect(quizBloc.state.sessionIndex, 0);
      await quizBloc.close();
    });

    test('soal terakhir -> node_completed + nodes di-refresh', () async {
      final repo = FakeMissionRepository(
        quiz: DailyQuiz.fromJson(_quizJson()),
        answer: QuizAnswerResult.fromJson({
          'is_correct': true,
          'xp_earned': 10,
          'new_xp': 2410,
          'new_level': 'Earth Warrior 7',
          'streak_days': 8,
          'user_mission_id': 13,
          'node_completed': true,
          'remaining': 0,
          'session_correct': 2,
          'session_xp': 20,
        }),
        session: _session(answered: 1, correct: 1),
        nodes: [QuizNode.fromJson(_nodeJson(completed: true))],
      );
      final quizBloc = QuizBloc(repo);
      final loaded = expectLater(
        quizBloc.stream,
        emitsThrough(
          predicate<QuizState>((s) => s.sessionStatus == SessionStatus.loaded),
        ),
      );
      quizBloc.add(const NodeSessionLoaded(2));
      await loaded;

      expect(quizBloc.state.sessionIndex, 1);

      repo.session = _session(answered: 2, correct: 2);
      final finished = expectLater(
        quizBloc.stream,
        emitsThrough(
          predicate<QuizState>(
            (s) =>
                s.lastResult?.nodeCompleted == true &&
                s.session?.isFinished == true &&
                s.nodes.any((n) => n.isCompletedToday),
          ),
        ),
      );
      quizBloc.add(const QuizAnswered('B'));
      await finished;
      await quizBloc.close();
    });

    test('nodes loaded -> status loaded + daftar node', () async {
      final quizBloc = QuizBloc(
        FakeMissionRepository(
          nodes: [
            QuizNode.fromJson(_nodeJson(position: 1, playable: false)),
            QuizNode.fromJson(_nodeJson(position: 2)),
          ],
        ),
      );
      final future = expectLater(
        quizBloc.stream,
        emitsThrough(
          predicate<QuizState>(
            (s) =>
                s.nodesStatus == SagaNodesStatus.loaded &&
                s.nodes.length == 2 &&
                s.nodes.where((n) => n.isPlayableToday).length == 1,
          ),
        ),
      );
      quizBloc.add(const SagaNodesLoaded());
      await future;
      await quizBloc.close();
    });

    test('401 -> isUnauthorized (UI wajib logout)', () async {
      final quizBloc = QuizBloc(
        FakeMissionRepository(
          error: const AuthException('Unauthenticated.', statusCode: 401),
        ),
      );
      final future = expectLater(
        quizBloc.stream,
        emitsThrough(predicate<QuizState>((s) => s.isUnauthorized)),
      );
      quizBloc.add(const DailyQuizLoaded());
      await future;
      await quizBloc.close();
    });

    test('repository pertahankan statusCode AuthException', () async {
      final repo = MissionRepository(_ThrowingDatasource());
      try {
        await repo.getDailyQuiz();
        fail('harus lempar');
      } on MissionException catch (e) {
        expect(e.statusCode, 422);
        expect(e.message, 'Salah.');
      }
    });
  });
}
