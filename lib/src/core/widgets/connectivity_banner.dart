import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/connectivity_provider.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';

/// شريط حالة الاتصال والمزامنة — يظهر أعلى الشاشة عند:
/// ■ فقدان الإنترنت (أحمر)
/// ■ جارٍ المزامنة (أزرق)
/// ■ نجاح المزامنة (أخضر — يختفي بعد 3 ثوان)
/// ■ خطأ في المزامنة (برتقالي)
class ConnectivityBanner extends ConsumerStatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  ConsumerState<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnim;
  bool _visible = false;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _show() {
    if (!_visible) {
      _visible = true;
      _animController.forward();
    }
  }

  void _hide() {
    if (_visible) {
      _visible = false;
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final pendingCount = ref.watch(pendingOperationsCountProvider);

    // تحديد الحالة والرسالة واللون
    final status = syncStatus.valueOrNull ?? SyncStatus.idle;
    final pending = pendingCount.valueOrNull ?? 0;

    Color bgColor;
    IconData icon;
    String message;
    bool shouldShow;

    if (!isOnline) {
      // ■ أوفلاين
      bgColor = AppColors.danger;
      icon = Icons.cloud_off_rounded;
      message = 'لا يوجد اتصال بالإنترنت — البيانات محفوظة محلياً';
      shouldShow = true;
      _wasOffline = true;
    } else if (status == SyncStatus.syncing) {
      // ■ جارٍ المزامنة
      bgColor = const Color(0xFF2196F3);
      icon = Icons.cloud_sync_rounded;
      message = pending > 0
          ? 'جارٍ المزامنة... ($pending عملية معلقة)'
          : 'جارٍ المزامنة...';
      shouldShow = true;
    } else if (status == SyncStatus.error) {
      // ■ خطأ
      bgColor = const Color(0xFFFF9800);
      icon = Icons.cloud_off_rounded;
      message = 'فشل في المزامنة — سيُعاد المحاولة تلقائياً';
      shouldShow = true;
    } else if (status == SyncStatus.synced && _wasOffline) {
      // ■ تمت المزامنة (فقط بعد أن كان أوفلاين)
      bgColor = AppColors.success;
      icon = Icons.cloud_done_rounded;
      message = 'تمت المزامنة بنجاح ✓';
      shouldShow = true;
      _wasOffline = false;

      // إخفاء بعد 3 ثوان
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _hide();
      });
    } else if (pending > 0 && isOnline) {
      // ■ عمليات معلقة ولكن لم تبدأ المزامنة
      bgColor = const Color(0xFF2196F3).withValues(alpha: 0.9);
      icon = Icons.sync_rounded;
      message = '$pending عملية بانتظار المزامنة';
      shouldShow = true;
    } else {
      bgColor = Colors.transparent;
      icon = Icons.check;
      message = '';
      shouldShow = false;
    }

    if (shouldShow) {
      _show();
    } else if (!_wasOffline && status != SyncStatus.syncing) {
      _hide();
    }

    return SizeTransition(
      sizeFactor: _slideAnim,
      axisAlignment: -1,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (status == SyncStatus.syncing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              else
                Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // زر مزامنة يدوية إذا كان أونلاين وهناك عمليات معلقة
              if (isOnline &&
                  pending > 0 &&
                  status != SyncStatus.syncing) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => ref.invalidate(syncNowProvider),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'مزامنة الآن',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
