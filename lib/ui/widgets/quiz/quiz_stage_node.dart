import 'package:flutter/material.dart';
import '../../../models/quiz_stage.dart';

/// Node lingkaran tahapan: completed (bintang), active (bendera + pulse),
/// locked (gembok). Active memakai animasi pulsing pelan.
class QuizStageNode extends StatefulWidget {
  final QuizStage stage;
  final VoidCallback? onTap;

  const QuizStageNode({super.key, required this.stage, this.onTap});

  @override
  State<QuizStageNode> createState() => _QuizStageNodeState();
}

class _QuizStageNodeState extends State<QuizStageNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scale;
  late final Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowOpacity = Tween<double>(begin: 0.35, end: 0.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.stage.status == QuizStageStatus.active) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.stage.status == QuizStageStatus.active;
    final node = GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 84,
        height: 84,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isActive)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) => Opacity(
                  opacity: _glowOpacity.value,
                  child: Container(
                    width: 76 * _scale.value,
                    height: 76 * _scale.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF9800).withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Transform.scale(
                scale: isActive ? _scale.value : 1.0,
                child: child,
              ),
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isActive
                      ? const LinearGradient(
                          colors: [Color(0xFFFFB300), Color(0xFFFF6D00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isActive ? null : Colors.white,
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFE65100)
                        : const Color(0xFFE0E0E0),
                    width: isActive ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isActive
                          ? const Color(0xFFFF9800).withValues(alpha: 0.45)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: isActive ? 18 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _iconFor(widget.stage.status),
                  color: _iconColorFor(widget.stage.status),
                  size: 26,
                ),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFFF6D00)
                      : const Color(0xFFBDBDBD),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${widget.stage.number}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return node;
  }

  IconData _iconFor(QuizStageStatus status) {
    switch (status) {
      case QuizStageStatus.completed:
        return Icons.star;
      case QuizStageStatus.active:
        return Icons.flag;
      case QuizStageStatus.locked:
        return Icons.lock;
    }
  }

  Color _iconColorFor(QuizStageStatus status) {
    switch (status) {
      case QuizStageStatus.completed:
        return const Color(0xFF43A047);
      case QuizStageStatus.active:
        return Colors.white;
      case QuizStageStatus.locked:
        return const Color(0xFF9E9E9E);
    }
  }
}

/// Tooltip melayang "Kamu di sini!" di atas node aktif.
class QuizActiveTooltip extends StatelessWidget {
  const QuizActiveTooltip({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Kamu di sini!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6D00),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Lanjutkan\npetualanganmu!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ),
        CustomPaint(painter: _TooltipArrowPainter(), size: const Size(16, 8)),
      ],
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
