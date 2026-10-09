/// Model data untuk tahapan kuis (hardcode tahap awal, belum dari API).
enum QuizStageStatus { completed, active, locked }

class QuizStage {
  final int number;
  final String tag;
  final String title;
  final String description;
  final int questionCount;
  final QuizStageStatus status;

  const QuizStage({
    required this.number,
    required this.tag,
    required this.title,
    required this.description,
    required this.questionCount,
    required this.status,
  });

  String get titleWithCount => '$title - $questionCount Pertanyaan';
}

/// Data dummy Level 1 — diganti API/BLoC nanti.
class QuizLevelData {
  static const String levelTitle = 'Peta Saga';
  static const int userPoints = 1250;
  static const int rewardPoints = 500;

  static const List<QuizStage> stages = [
    QuizStage(
      number: 1,
      tag: 'BABAK 1',
      title: 'Kenali Jenis Plastik',
      description:
          'Pelajari jenis-jenis plastik di sekitarmu dan cara memilahnya dengan benar.',
      questionCount: 5,
      status: QuizStageStatus.completed,
    ),
    QuizStage(
      number: 2,
      tag: 'BABAK 2',
      title: 'Daur Ulang Dasar',
      description:
          'Pahami alur daur ulang plastik dari rumah hingga menjadi produk baru.',
      questionCount: 5,
      status: QuizStageStatus.completed,
    ),
    QuizStage(
      number: 3,
      tag: 'BABAK 3',
      title: 'Bahaya Gas Metana',
      description:
          'Pelajari bagaimana sampah plastik dapat menghasilkan gas metana dan berdampak pada lingkungan kita.',
      questionCount: 5,
      status: QuizStageStatus.active,
    ),
    QuizStage(
      number: 4,
      tag: 'BABAK 4',
      title: 'Gaya Hidup Minim Sampah',
      description:
          'Temukan kebiasaan kecil yang berdampak besar untuk mengurangi sampah plastik.',
      questionCount: 5,
      status: QuizStageStatus.locked,
    ),
    QuizStage(
      number: 5,
      tag: 'BABAK 5',
      title: 'Aksi Pahlawan Hijau',
      description:
          'Uji pemahamanmu dan raih hadiah spesial 500 poin di babak final.',
      questionCount: 5,
      status: QuizStageStatus.locked,
    ),
  ];
}
