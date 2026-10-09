import 'package:flutter/material.dart';

/// Indikator progres bertingkat: hijau = benar/aktif, oranye = hangus,
/// abu = belum dijawab.
class QuizProgressSegments extends StatelessWidget {
  final int total;
  final int answeredCount;
  final int currentIndex;

  /// Index soal yang dijawab salah (hangus).
  final Set<int> incorrectIndexes;

  const QuizProgressSegments({
    super.key,
    required this.total,
    required this.answeredCount,
    required this.currentIndex,
    this.incorrectIndexes = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isDone = i < answeredCount || i == currentIndex;
        final isWrong = incorrectIndexes.contains(i);
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(
              left: i == 0 ? 0 : 3,
              right: i == total - 1 ? 0 : 3,
            ),
            decoration: BoxDecoration(
              color: isWrong
                  ? const Color(0xFFEF6C00)
                  : isDone
                  ? const Color(0xFF43A047)
                  : const Color(0xFFBDBDBD).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
