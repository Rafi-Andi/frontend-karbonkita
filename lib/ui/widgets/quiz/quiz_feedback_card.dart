import 'package:flutter/material.dart';

/// Kotak umpan balik di bawah pilihan jawaban.
/// Varian: netral "Jawaban Tersimpan", benar (hijau), salah (oranye).
enum QuizFeedbackVariant { neutral, correct, incorrect }

class QuizFeedbackCard extends StatelessWidget {
  final String explanation;
  final QuizFeedbackVariant variant;
  final String? title;

  const QuizFeedbackCard({
    super.key,
    required this.explanation,
    this.variant = QuizFeedbackVariant.neutral,
    this.title,
  });

  Color get _accent => switch (variant) {
    QuizFeedbackVariant.neutral => const Color(0xFF43A047),
    QuizFeedbackVariant.correct => const Color(0xFF2E7D32),
    QuizFeedbackVariant.incorrect => const Color(0xFFEF6C00),
  };

  IconData get _icon => switch (variant) {
    QuizFeedbackVariant.neutral => Icons.check_circle,
    QuizFeedbackVariant.correct => Icons.emoji_events,
    QuizFeedbackVariant.incorrect => Icons.refresh,
  };

  String get _defaultTitle => switch (variant) {
    QuizFeedbackVariant.neutral => 'Jawaban Tersimpan',
    QuizFeedbackVariant.correct => 'Jawaban Benar!',
    QuizFeedbackVariant.incorrect => 'Belum Tepat, Coba Lagi',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon, color: Colors.white, size: 14),
                const SizedBox(width: 5),
                Text(
                  title ?? _defaultTitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
