import 'package:flutter/material.dart';

/// Displays a cleanliness score as a colored progress indicator.
/// 0.0 = sparkling clean (green), 1.0 = very dirty (red)
class CleanlinessIndicator extends StatelessWidget {
  final double dirtiness;
  final double size;

  const CleanlinessIndicator({
    super.key,
    required this.dirtiness,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = dirtiness.clamp(0.0, 1.0);
    final color = Color.lerp(
      Colors.green,
      Colors.red,
      clamped,
    )!;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1.0 - clamped,
            strokeWidth: 4,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Icon(
            clamped < 0.3
                ? Icons.sentiment_very_satisfied
                : clamped < 0.7
                    ? Icons.sentiment_neutral
                    : Icons.sentiment_very_dissatisfied,
            size: size * 0.5,
            color: color,
          ),
        ],
      ),
    );
  }
}
