import 'package:flutter/material.dart';
import '../../../models/quiz_question.dart';

/// Tile pilihan jawaban A–D: default putih, selected hijau + centang.
/// Ukuran mengikuti konten — tanpa height hardcode.
class QuizAnswerOptionTile extends StatelessWidget {
  final QuizAnswerOption option;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  const QuizAnswerOptionTile({
    super.key,
    required this.option,
    required this.selected,
    required this.locked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE8F5E9).withValues(alpha: 0.7)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF43A047) : const Color(0xFFE0E0E0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF43A047)
                    : const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                option.text,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
            if (selected) const SizedBox(width: 8),
            if (selected)
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF43A047),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF43A047),
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
