import '../../models/daily_quiz.dart';
import '../../models/quiz_node.dart';
import '../../models/quiz_session.dart';

/// Status kuis harian.
enum QuizStatus { initial, loading, loaded, answering, error }

/// Status daftar node peta Saga.
enum SagaNodesStatus { initial, loading, loaded, error }

/// Status sesi soal 1 node.
enum SessionStatus { initial, loading, loaded, error }

class QuizState {
  const QuizState({
    this.status = QuizStatus.initial,
    this.quiz,
    this.lastResult,
    this.errorMessage,
    this.isUnauthorized = false,
    this.nodesStatus = SagaNodesStatus.initial,
    this.nodes = const [],
    this.nodesErrorMessage,
    this.sessionStatus = SessionStatus.initial,
    this.session,
    this.sessionIndex = 0,
    this.sessionErrorMessage,
    this.isOffline = false,
    this.lastUpdated,
  });

  final QuizStatus status;
  final DailyQuiz? quiz;

  /// Hasil submit terakhir (null = belum jawab / sudah di-reset).
  final QuizAnswerResult? lastResult;
  final String? errorMessage;

  /// True bila backend 401 — UI harus logout, bukan sekadar retry.
  final bool isUnauthorized;

  /// Daftar node peta Saga (1 node = 1 misi quiz dari backend).
  final SagaNodesStatus nodesStatus;
  final List<QuizNode> nodes;
  final String? nodesErrorMessage;

  /// Sesi multi-soal node yang sedang dimainkan.
  final SessionStatus sessionStatus;
  final QuizSession? session;
  final int sessionIndex;
  final String? sessionErrorMessage;

  /// True bila node/quiz berasal dari cache offline.
  final bool isOffline;
  final DateTime? lastUpdated;

  QuizState copyWith({
    QuizStatus? status,
    DailyQuiz? quiz,
    QuizAnswerResult? lastResult,
    bool clearResult = false,
    String? errorMessage,
    bool? isUnauthorized,
    SagaNodesStatus? nodesStatus,
    List<QuizNode>? nodes,
    String? nodesErrorMessage,
    SessionStatus? sessionStatus,
    QuizSession? session,
    int? sessionIndex,
    String? sessionErrorMessage,
    bool? isOffline,
    DateTime? lastUpdated,
  }) {
    return QuizState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
      errorMessage: errorMessage,
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
      nodesStatus: nodesStatus ?? this.nodesStatus,
      nodes: nodes ?? this.nodes,
      nodesErrorMessage: nodesErrorMessage,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      session: session ?? this.session,
      sessionIndex: sessionIndex ?? this.sessionIndex,
      sessionErrorMessage: sessionErrorMessage,
      isOffline: isOffline ?? this.isOffline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
