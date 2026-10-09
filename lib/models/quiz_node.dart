/// Node peta Saga dari `GET /api/saga/nodes` (1 node = 1 misi quiz).
/// Progres berurutan dari bawah: hanya 1 node berikutnya yang belum
/// selesai yang terbuka (anti-loncat); kuota 2 node selesai per hari.
/// Skip sehari tidak menghanguskan progres.
class QuizNode {
  const QuizNode({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
    required this.position,
    required this.quizzesCount,
    required this.isCompletedToday,
    required this.isPlayableToday,
    required this.todayQuizId,
    this.totalQuestions = 0,
    this.answeredToday = 0,
    this.isCompleted = false,
  });

  final int id;
  final String title;
  final String description;
  final String icon;
  final int xpReward;
  final int position;
  final int quizzesCount;
  final bool isCompletedToday;
  final bool isPlayableToday;

  /// Pernah selesai (persisten). Node selesai tetap tampil selesai
  /// meski sesi hari ini belum dikerjakan.
  final bool isCompleted;

  /// Selesai untuk tampilan: selesai hari ini atau pernah selesai.
  bool get isDone => isCompletedToday || isCompleted;

  /// Jumlah soal sesi (5) dan yang sudah terjawab hari ini.
  final int totalQuestions;
  final int answeredToday;

  /// ID soal hari ini — hanya ada pada node playable.
  final int? todayQuizId;

  factory QuizNode.fromJson(Map<String, dynamic> json) {
    return QuizNode(
      id: _toInt(json['id']),
      title: json['title'] as String? ?? 'Kuis Harian',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'quiz',
      xpReward: _toInt(json['xp_reward']),
      position: _toInt(json['position']),
      quizzesCount: _toInt(json['quizzes_count']),
      isCompletedToday: json['is_completed_today'] as bool? ?? false,
      isPlayableToday: json['is_playable_today'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      todayQuizId: json['today_quiz_id'] == null
          ? null
          : _toInt(json['today_quiz_id']),
      totalQuestions: _toInt(json['total_questions']),
      answeredToday: _toInt(json['answered_today']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    'xp_reward': xpReward,
    'position': position,
    'quizzes_count': quizzesCount,
    'is_completed_today': isCompletedToday,
    'is_completed': isCompleted,
    'is_playable_today': isPlayableToday,
    'today_quiz_id': todayQuizId,
    'total_questions': totalQuestions,
    'answered_today': answeredToday,
  };
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
