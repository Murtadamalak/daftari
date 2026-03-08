import 'package:flutter/material.dart';

class RefreshActionButton extends StatelessWidget {
  const RefreshActionButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'تحديث',
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.refresh_outlined,
            color:
                isDark ? theme.colorScheme.primary : theme.colorScheme.primary,
            size: 20,
          ),
        ),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
