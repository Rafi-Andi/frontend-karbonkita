import 'package:flutter/material.dart';

/// Bingkai fokus pemindai: isi putih transparan + grid putus-putus
/// dengan 4 sudut siku hijau menyala.
class ScanFramePainter extends CustomPainter {
  ScanFramePainter({this.cornerColor = const Color(0xFF22C55E)});

  final Color cornerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.shortestSide * 0.06);

    // Isi putih transparan.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );

    // Grid putus-putus 3x3.
    final dashed = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (int i = 1; i < 3; i++) {
      _dashedLine(
        canvas,
        Offset(size.width * i / 3, 0),
        Offset(size.width * i / 3, size.height),
        dashed,
      );
      _dashedLine(
        canvas,
        Offset(0, size.height * i / 3),
        Offset(size.width, size.height * i / 3),
        dashed,
      );
    }

    // Sudut siku hijau menyala (digambar dua lapis untuk efek glow).
    final cornerLen = size.shortestSide * 0.18;
    final cornerPaint = Paint()
      ..color = cornerColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final glowPaint = Paint()
      ..color = cornerColor.withValues(alpha: 0.35)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final corners = <List<Offset>>[
      // Kiri atas.
      [const Offset(0, 0), Offset(cornerLen, 0)],
      [const Offset(0, 0), Offset(0, cornerLen)],
      // Kanan atas.
      [Offset(size.width, 0), Offset(size.width - cornerLen, 0)],
      [Offset(size.width, 0), Offset(size.width, cornerLen)],
      // Kiri bawah.
      [Offset(0, size.height), Offset(cornerLen, size.height)],
      [Offset(0, size.height), Offset(0, size.height - cornerLen)],
      // Kanan bawah.
      [
        Offset(size.width, size.height),
        Offset(size.width - cornerLen, size.height),
      ],
      [
        Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLen),
      ],
    ];
    for (final line in corners) {
      canvas.drawLine(line[0], line[1], glowPaint);
      canvas.drawLine(line[0], line[1], cornerPaint);
    }
  }

  void _dashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dash = 7.0;
    const gap = 6.0;
    final total = (to - from).distance;
    var drawn = 0.0;
    while (drawn < total) {
      final end = (drawn + dash).clamp(0.0, total);
      final p1 = Offset.lerp(from, to, drawn / total)!;
      final p2 = Offset.lerp(from, to, end / total)!;
      canvas.drawLine(p1, p2, paint);
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant ScanFramePainter oldDelegate) =>
      oldDelegate.cornerColor != cornerColor;
}
