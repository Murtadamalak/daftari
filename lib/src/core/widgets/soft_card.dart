import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A Card with a subtle drop shadow instead of elevation-based shadow.
/// Use this instead of [Card] anywhere you want the "lifted" premium look.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 14.0,
    this.color,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color ?? (isDark ? AppColors.darkSurface : AppColors.white);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF1A3C6E).withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: onTap != null
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(padding: padding, child: child),
                ),
              )
            : Padding(padding: padding, child: child),
      ),
    );
  }
}
