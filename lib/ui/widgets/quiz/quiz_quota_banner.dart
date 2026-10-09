import 'package:flutter/material.dart';

/// Banner kuota main harian di halaman Saga Quiz.
/// Menampilkan sisa kuota (max 2 node selesai/hari): "Sisa 2/2 main hari ini".
class QuizQuotaBanner extends StatelessWidget {
  final int remaining;
  final int total;

  const QuizQuotaBanner({super.key, required this.remaining, this.total = 2});

  @override
  Widget build(BuildContext context) {
    final exhausted = remaining <= 0;
    final almostOut = !exhausted && remaining == 1;
    final bgColor = exhausted
        ? const Color(0xFFF5F5F5)
        : almostOut
        ? const Color(0xFFFFF8E1)
        : Colors.white;
    final iconBg = exhausted
        ? const Color(0xFFE0E0E0)
        : almostOut
        ? const Color(0xFFFFE0B2)
        : const Color(0xFFE8F5E9);
    final iconColor = exhausted
        ? Colors.grey
        : almostOut
        ? const Color(0xFFFF8F00)
        : const Color(0xFF43A047);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: exhausted ? Colors.grey.shade300 : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(
              exhausted ? Icons.battery_0_bar : Icons.bolt,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  exhausted
                      ? 'Kuota hari ini habis'
                      : 'Sisa $remaining/$total main hari ini',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  exhausted
                      ? 'Kembali besok untuk lanjut babak berikutnya'
                      : 'Selesaikan 1 node untuk buka babak berikutnya',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(total, (i) {
              final filled = i < remaining;
              return Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? const Color(0xFF43A047)
                        : Colors.grey.shade300,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
