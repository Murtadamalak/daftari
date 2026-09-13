import 'package:flutter/material.dart';
import 'package:daftar_debt_manager/src/core/theme/google_fonts_mock.dart';
import '../theme/app_theme.dart';

/// ويدجت موحّد لعرض أخطاء تحميل البيانات بشكل لطيف للمستخدم
class DataErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const DataErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.retryLabel,
  });

  bool get _isNetworkError {
    final msg = error.toString();
    return msg.contains('SocketException') ||
        msg.contains('No route to host') ||
        msg.contains('Connection refused') ||
        msg.contains('Network is unreachable') ||
        msg.contains('errno = 113') ||
        msg.contains('ClientException');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNetwork = _isNetworkError;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 64,
              color: isDark
                  ? const Color(0xFF85AFA7)
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              isNetwork ? 'لا يوجد اتصال بالإنترنت' : 'تعذّر تحميل البيانات',
              textAlign: TextAlign.center,
              style: GoogleFonts.almarai(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0A221F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isNetwork
                  ? 'تحقق من اتصالك بالإنترنت وأعد المحاولة'
                  : 'حدث خطأ أثناء تحميل البيانات، يرجى إعادة المحاولة',
              textAlign: TextAlign.center,
              style: GoogleFonts.almarai(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF85AFA7)
                    : AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryLabel ?? 'إعادة المحاولة'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
