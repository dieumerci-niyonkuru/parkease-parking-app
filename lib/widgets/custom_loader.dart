import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class CustomLoader extends StatelessWidget {
  final double size;
  const CustomLoader({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Brown circle
            _buildDot(AppTheme.primary, size * 0.4, 0),
            // White circle
            _buildDot(Colors.white, size * 0.4, 150),
            // Grey/Off-white circle
            _buildDot(AppTheme.bgSurface, size * 0.4, 300),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(Color color, double dotSize, int delayMs) {
    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).scale(
      begin: const Offset(0.5, 0.5),
      end: const Offset(1.2, 1.2),
      duration: 1000.ms,
      curve: Curves.easeInOut,
      delay: delayMs.ms,
    ).fadeOut(
      duration: 1000.ms,
      curve: Curves.easeOut,
      delay: delayMs.ms,
    );
  }
}
