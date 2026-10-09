import 'package:flutter/material.dart';

/// Menggambar jalur S-curve hijau di belakang node tahapan.
class QuizPathPainter extends CustomPainter {
  final Color pathColor;
  final Color dashColor;

  QuizPathPainter({
    this.pathColor = const Color(0xFF81C784),
    this.dashColor = const Color(0xFFA5D6A7),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Jalur S vertikal dari atas (hadiah) ke bawah (start).
    final path = Path()..moveTo(w * 0.5, 0);
    path.cubicTo(w * 0.5, h * 0.10, w * 0.72, h * 0.12, w * 0.68, h * 0.22);
    path.cubicTo(w * 0.64, h * 0.32, w * 0.30, h * 0.33, w * 0.34, h * 0.44);
    path.cubicTo(w * 0.38, h * 0.55, w * 0.72, h * 0.56, w * 0.66, h * 0.68);
    path.cubicTo(w * 0.60, h * 0.80, w * 0.30, h * 0.82, w * 0.36, h * 0.94);
    path.lineTo(w * 0.38, h);

    // Bayangan lembut di bawah jalur.
    canvas.drawPath(
      path.shift(const Offset(0, 6)),
      Paint()
        ..color = const Color(0xFF1B5E20).withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(path, paint);

    // Segmen dashed dekoratif di dekat ujung atas (menuju hadiah).
    final dashPaint = Paint()
      ..color = dashColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    var dy = 8.0;
    while (dy < 52) {
      canvas.drawLine(Offset(w * 0.5, dy), Offset(w * 0.5, dy + 9), dashPaint);
      dy += 17;
    }
  }

  @override
  bool shouldRepaint(covariant QuizPathPainter oldDelegate) =>
      oldDelegate.pathColor != pathColor || oldDelegate.dashColor != dashColor;
}
