import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Half-doughnut gauge (180°) dengan gradasi hijau → kuning → oranye.
class EmissionGaugePainter extends CustomPainter {
  EmissionGaugePainter({required this.progress});

  /// 0.0 – 1.0
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    final center = Offset(size.width / 2, size.height);
    final radius = math.min(size.width / 2, size.height) - strokeWidth;

    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    final sweep = (progress.clamp(0.0, 1.0)) * math.pi;
    if (sweep <= 0) return;

    final fgPaint = Paint()
      ..shader = SweepGradient(
        startAngle: math.pi,
        endAngle: 2 * math.pi,
        colors: const [
          Color(0xFF43A047),
          Color(0xFF9CCC65),
          Color(0xFFFFCA28),
          Color(0xFFF57C00),
        ],
        stops: const [0.0, 0.35, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant EmissionGaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
