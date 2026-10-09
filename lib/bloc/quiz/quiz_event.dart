/// Event QuizBloc.
sealed class QuizEvent {
  const QuizEvent();
}

/// Muat kuis harian dari backend.
class DailyQuizLoaded extends QuizEvent {
  const DailyQuizLoaded({this.force = false});

  final bool force;
}

/// Muat daftar node peta Saga dari backend.
class SagaNodesLoaded extends QuizEvent {
  const SagaNodesLoaded({this.force = false});

  final bool force;
}

/// Muat sesi soal 1 node dari backend.
class NodeSessionLoaded extends QuizEvent {
  const NodeSessionLoaded(this.missionId, {this.force = false});

  final int missionId;
  final bool force;
}

/// Lanjut ke soal sesi berikutnya yang belum dijawab.
class SessionQuestionNext extends QuizEvent {
  const SessionQuestionNext();
}

/// Kirim jawaban (label A/B/C/D) untuk soal sesi yang sedang tampil.
class QuizAnswered extends QuizEvent {
  const QuizAnswered(this.answer);

  final String answer;
}
