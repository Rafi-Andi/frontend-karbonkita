import 'package:flutter/material.dart';

class EmissionSliderRow extends StatelessWidget {
  const EmissionSliderRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.minLabel,
    required this.maxLabel,
    required this.displayValue,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final String minLabel;
  final String maxLabel;
  final String displayValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF43A047), size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                minLabel,
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF43A047),
                  inactiveTrackColor: Colors.grey.shade200,
                  thumbColor: Colors.white,
                  overlayColor: const Color(0xFF43A047).withValues(alpha: 0.15),
                  thumbShape: const _RingThumbShape(),
                  trackHeight: 6,
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                ),
                child: Slider(
                  value: value.clamp(min, max).toDouble(),
                  min: min,
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                maxLabel,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minWidth: 76),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                displayValue,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RingThumbShape extends SliderComponentShape {
  const _RingThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(22, 22);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final outer = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.fill;
    final middle = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final inner = Paint()
      ..color = const Color(0xFF43A047)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 11, outer);
    canvas.drawCircle(center, 8.5, middle);
    canvas.drawCircle(center, 5, inner);
  }
}
