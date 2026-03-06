import 'package:flutter/material.dart';

class DifficultySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const DifficultySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final level = index + 1;
        final isSelected = level <= value;
        return GestureDetector(
          onTap: () => onChanged(level),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isSelected ? Icons.star : Icons.star_border,
              color: isSelected ? colorScheme.primary : colorScheme.outline,
              size: 32,
            ),
          ),
        );
      }),
    );
  }
}
