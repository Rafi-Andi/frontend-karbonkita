import 'package:flutter/material.dart';

/// Kartu informasi kecil di sekitar jalur (hadiah / motivasi).
/// Ukuran mengikuti konten (mainAxisSize.min) — tanpa height hardcode.
class QuizInfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String? title;
  final String? titleHighlight;
  final String subtitle;
  final double maxWidth;

  const QuizInfoCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.title,
    this.titleHighlight,
    required this.subtitle,
    this.maxWidth = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                      children: [
                        TextSpan(text: title),
                        if (titleHighlight != null)
                          TextSpan(
                            text: ' $titleHighlight',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                      ],
                    ),
                  ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: title != null ? 12 : 10,
                    fontWeight: title != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: title != null
                        ? const Color(0xFF2E7D32)
                        : Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
