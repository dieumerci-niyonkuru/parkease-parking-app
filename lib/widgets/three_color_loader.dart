import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Three-color animated loading indicator using green, blue, and yellow
class ThreeColorLoader extends StatefulWidget {
  final double size;
  final Color color1, color2, color3;

  const ThreeColorLoader({
    super.key,
    this.size = 48,
    this.color1 = AppTheme.primary,
    this.color2 = AppTheme.accent,
    this.color3 = AppTheme.warning,
  });

  @override
  State<ThreeColorLoader> createState() => _ThreeColorLoaderState();
}

class _ThreeColorLoaderState extends State<ThreeColorLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating ring 1 (Green)
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Transform.rotate(
              angle: _controller.value * 2 * 3.14159,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  color: widget.color1,
                  progress: _controller.value,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          // Rotating ring 2 (Blue) - opposite direction
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Transform.rotate(
              angle: -_controller.value * 1.5 * 3.14159,
              child: CustomPaint(
                size: Size(widget.size * 0.7, widget.size * 0.7),
                painter: _RingPainter(
                  color: widget.color2,
                  progress: _controller.value,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ),
          // Rotating ring 3 (Yellow) - middle speed
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Transform.rotate(
              angle: _controller.value * 0.8 * 3.14159,
              child: CustomPaint(
                size: Size(widget.size * 0.45, widget.size * 0.45),
                painter: _RingPainter(
                  color: widget.color3,
                  progress: _controller.value,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
          // Center dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.color1,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color1.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  final double progress;
  final double strokeWidth;

  _RingPainter({
    required this.color,
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const sweepAngle = 0.5; // 90 degrees
    final startAngle = progress * 2 * 3.14159;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
