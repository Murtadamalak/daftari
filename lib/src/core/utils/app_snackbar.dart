import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Centralised SnackBar helper — call from anywhere in the widget tree.
///
/// Usage:
/// ```dart
/// AppSnackBar.success(context, 'تم حفظ الفاتورة بنجاح');
/// AppSnackBar.error(context, 'حدث خطأ ما');
/// AppSnackBar.info(context, 'جارٍ المعالجة...');
/// ```
class AppSnackBar {
  AppSnackBar._();

  static void success(BuildContext context, String message) =>
      _show(context, message,
          icon: Icons.check_circle_rounded,
          bg: AppColors.success,
          iconColor: Colors.white);

  static void error(BuildContext context, String message) =>
      _show(context, message,
          icon: Icons.error_rounded,
          bg: AppColors.danger,
          iconColor: Colors.white);

  static void warning(BuildContext context, String message) =>
      _show(context, message,
          icon: Icons.warning_rounded,
          bg: AppColors.warning,
          iconColor: Colors.white);

  static void info(BuildContext context, String message) =>
      _show(context, message,
          icon: Icons.info_rounded,
          bg: AppColors.primary,
          iconColor: Colors.white);

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color bg,
    required Color iconColor,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          content: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
