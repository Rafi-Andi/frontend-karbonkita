/// Model soal kuis (hardcode tahap awal, belum dari API).
/// Koreksi benar/salah dilakukan di akhir babak, bukan per soal.
class QuizAnswerOption {
  final String label;
  final String text;

  const QuizAnswerOption({required this.label, required this.text});
}

class QuizQuestion {
  final String question;
  final List<QuizAnswerOption> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class QuizBabak3Data {
  static const String title = 'Babak 3: Gas Metana';

  /// Durasi timer per babak (detik). Ubah ke 120 untuk 2 menit.
  static const int babakDurationSeconds = 180;

  static const List<QuizQuestion> questions = [
    QuizQuestion(
      question:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit tentang sampah plastik?',
      options: [
        QuizAnswerOption(label: 'A', text: 'Lorem ipsum dolor sit amet'),
        QuizAnswerOption(
          label: 'B',
          text: 'Consectetur adipiscing elit sed do eiusmod',
        ),
        QuizAnswerOption(label: 'C', text: 'Tempor incididunt ut labore'),
        QuizAnswerOption(label: 'D', text: 'Dolore magna aliqua enim'),
      ],
      correctIndex: 1,
      explanation:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
    ),
    QuizQuestion(
      question:
          'Lorem ipsum quid est gas metana dan dari mana asalnya di lingkungan kita?',
      options: [
        QuizAnswerOption(label: 'A', text: 'Lorem ipsum dolor sit amet'),
        QuizAnswerOption(label: 'B', text: 'Ut enim ad minim veniam quis'),
        QuizAnswerOption(
          label: 'C',
          text: 'Nostrud exercitation ullamco laboris nisi',
        ),
        QuizAnswerOption(label: 'D', text: 'Aliquip ex ea commodo consequat'),
      ],
      correctIndex: 2,
      explanation:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
    ),
    QuizQuestion(
      question:
          'Sumber utama gas metana (CH4) dari aktivitas manusia yang paling besar kontribusinya terhadap perubahan iklim adalah?',
      options: [
        QuizAnswerOption(
          label: 'A',
          text: 'Polusi udara dari kendaraan bermotor',
        ),
        QuizAnswerOption(
          label: 'B',
          text: 'Pembusukan sampah organik di tempat pembuangan akhir (TPA)',
        ),
        QuizAnswerOption(
          label: 'C',
          text: 'Penggunaan listrik dari pembangkit tenaga surya',
        ),
        QuizAnswerOption(
          label: 'D',
          text: 'Penggunaan pupuk kimia di lahan pertanian',
        ),
      ],
      correctIndex: 1,
      explanation:
          'Sampah organik seperti sisa makanan yang membusuk di TPA menghasilkan gas metana dalam jumlah besar. Gas metana memiliki potensi pemanasan global 25 kali lebih kuat daripada CO2.',
    ),
    QuizQuestion(
      question:
          'Lorem ipsum quae est dampak gas metana terhadap pemanasan global dibanding CO2?',
      options: [
        QuizAnswerOption(
          label: 'A',
          text: 'Duis aute irure dolor in reprehenderit',
        ),
        QuizAnswerOption(label: 'B', text: 'In voluptate velit esse cillum'),
        QuizAnswerOption(label: 'C', text: 'Dolore eu fugiat nulla pariatur'),
        QuizAnswerOption(
          label: 'D',
          text: 'Excepteur sint occaecat cupidatat non',
        ),
      ],
      correctIndex: 0,
      explanation:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
    ),
    QuizQuestion(
      question:
          'Lorem ipsum quomodo cara sederhana mengurangi emisi metana dari sampah rumah tangga?',
      options: [
        QuizAnswerOption(
          label: 'A',
          text: 'Sunt in culpa qui officia deserunt',
        ),
        QuizAnswerOption(label: 'B', text: 'Mollit anim id est laborum sed'),
        QuizAnswerOption(label: 'C', text: 'Ut enim ad minima veniam quis'),
        QuizAnswerOption(
          label: 'D',
          text: 'Nostrum exercitationem ullam corporis',
        ),
      ],
      correctIndex: 3,
      explanation:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
    ),
  ];
}
