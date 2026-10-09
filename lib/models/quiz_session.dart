import 'daily_quiz.dart';

/// Sesi multi-soal 1 node dari `GET /api/saga/nodes/{id}/questions`.
/// Fixed 5 soal deterministik per node playable/hari.
class QuizSession {
  const QuizSession({
    required this.missionId,
    required this.missionTitle,
    required this.sessionDate,
    required this.total,
    required this.xpPerQuestion,
    required this.questions,
  });

  final int missionId;
  final String missionTitle;
  final String sessionDate;
  final int total;
  final int xpPerQuestion;
  final List<DailyQuiz> questions;

  /// Index soal pertama yang belum dijawab (-1 bila semua terjawab).
  int get firstUnansweredIndex {
    for (var i = 0; i < questions.length; i++) {
      if (!questions[i].isCompletedToday) return i;
    }
    return -1;
  }

  /// True bila semua soal sesi sudah terjawab (benar/salah).
  bool get isFinished => firstUnansweredIndex == -1 && questions.isNotEmpty;

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    return QuizSession(
      missionId: _toInt(json['mission_id']),
      missionTitle: json['mission_title'] as String? ?? 'Kuis Harian',
      sessionDate: json['session_date'] as String? ?? '',
      total: _toInt(json['total']),
      xpPerQuestion: _toInt(json['xp_per_question']),
      questions: rawQuestions is List
          ? rawQuestions
                .whereType<Map<String, dynamic>>()
                .map(DailyQuiz.fromSessionJson)
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'mission_id': missionId,
    'mission_title': missionTitle,
    'session_date': sessionDate,
    'total': total,
    'xp_per_question': xpPerQuestion,
    'questions': questions.map((q) => q.toJson()).toList(),
  };
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
