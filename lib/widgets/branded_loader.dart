import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class BrandedLoader extends StatelessWidget {
  final String? message;
  const BrandedLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation(Color(0xFF212529)), // Dark grey/black from image
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'ITEC PARKING',
            style: AppTheme.heading4.copyWith(
              letterSpacing: 4,
              color: const Color(0xFF7A5B40), // Brownish brand color
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ).animate().fadeIn(duration: 400.ms),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!.toUpperCase(),
              style: AppTheme.label.copyWith(fontSize: 9, letterSpacing: 1, color: AppTheme.textMuted),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ],
      ),
    );
  }
}
