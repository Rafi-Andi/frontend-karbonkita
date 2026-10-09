import 'package:flutter/material.dart';

class DraggableQuizFab extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  const DraggableQuizFab({super.key, this.onTap, this.onClose});

  @override
  State<DraggableQuizFab> createState() => _DraggableQuizFabState();
}

class _DraggableQuizFabState extends State<DraggableQuizFab>
    with SingleTickerProviderStateMixin {
  double? _x;
  double? _y;
  bool _isVisible = true;
  bool _isDragging = false;
  Offset _dragStart = Offset.zero;
  Offset _positionStart = Offset.zero;

  static const double _fabSize = 72;
  static const double _dragThreshold = 5;
  static const double _padding = 16;

  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _dragStart = details.globalPosition;
    _positionStart = Offset(_x ?? 0, _y ?? 0);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    final dx = details.globalPosition.dx - _dragStart.dx;
    final dy = details.globalPosition.dy - _dragStart.dy;

    if (!_isDragging &&
        (dx.abs() > _dragThreshold || dy.abs() > _dragThreshold)) {
      _isDragging = true;
    }

    if (!_isDragging) return;

    setState(() {
      _x = (_positionStart.dx + dx).clamp(
        _padding,
        size.width - _fabSize - _padding,
      );
      _y = (_positionStart.dy + dy).clamp(
        kToolbarHeight + MediaQuery.of(context).padding.top,
        size.height - _fabSize - 80,
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) {
      widget.onTap?.call();
    }
    _isDragging = false;
  }

  void _hide() {
    _scaleController.reverse().then((_) {
      if (mounted) {
        setState(() => _isVisible = false);
        widget.onClose?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final size = MediaQuery.of(context).size;
    _x ??= size.width - _fabSize - _padding;
    _y ??= size.height - _fabSize - 160;

    return Positioned(
      left: _x,
      top: _y,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: _fabSize,
                height: _fabSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/FABKuis.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF43A047),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.quiz,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -6,
                top: -6,
                child: GestureDetector(
                  onTap: _hide,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
