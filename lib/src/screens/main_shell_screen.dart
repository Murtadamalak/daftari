import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/connectivity_banner.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/connectivity_provider.dart';
import '../core/services/sync_service.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _tabs = [
    (
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'المنتجات'
    ),
    (
      icon: Icons.money_off_outlined,
      activeIcon: Icons.money_off,
      label: 'سجل الديون'
    ),
    (
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'الفواتير'
    ),
    (
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'التقارير'
    ),
    (
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'الإعدادات'
    ),
  ];

  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 850;
    
    final location = GoRouterState.of(context).uri.path;
    final isMainTab = location == '/products' ||
        location == '/customers' ||
        location == '/invoices' ||
        location == '/reports' ||
        location == '/settings';

    if (isDesktop && isMainTab) {
      final currentTab = _tabs[widget.navigationShell.currentIndex];

      return Scaffold(
        body: Row(
          children: [
            // ── المحتوى الرئيسي (على اليسار في RTL) ──
            Expanded(
              child: Column(
                children: [
                  // ── شريط سطح المكتب العلوي الأنيق ──
                  _buildDesktopTopBar(context, isDark, currentTab),
                  const ConnectivityBanner(),
                  Expanded(
                    child: Container(
                      color: isDark ? AppColors.darkBg : AppColors.background,
                      child: widget.navigationShell,
                    ),
                  ),
                ],
              ),
            ),
            // ── القائمة الجانبية الثابتة والقابلة للطي (على اليمين في RTL) ──
            _buildDesktopSidebar(context, isDark),
          ],
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawer: null,
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  const ConnectivityBanner(),
                  Expanded(child: widget.navigationShell),
                ],
              ),
            ),
          ),
          if (!isDesktop && isMainTab)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _FlatNavBar(
                selectedIndex: widget.navigationShell.currentIndex,
                isDark: isDark,
                onTap: (i) => widget.navigationShell.goBranch(
                  i,
                  initialLocation: i == widget.navigationShell.currentIndex,
                ),
                tabs: _tabs,
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // شريط سطح المكتب العلوي
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktopTopBar(
    BuildContext context,
    bool isDark,
    ({IconData icon, IconData activeIcon, String label}) currentTab,
  ) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final isOnline = ref.watch(isOnlineProvider);
    final syncStatus = ref.watch(syncStatusProvider).valueOrNull ?? SyncStatus.idle;
    final pendingCount = ref.watch(pendingOperationsCountProvider).valueOrNull ?? 0;

    String dateStr = '';
    try {
      dateStr = DateFormat('EEEE، d MMMM y', 'ar').format(DateTime.now());
    } catch (_) {
      dateStr = DateFormat('yyyy/MM/dd').format(DateTime.now());
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // ── عنوان القسم الحالي ──
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F322E) : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              currentTab.activeIcon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentTab.label,
                style: TextStyle(
                  fontFamily: 'KOMedia',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const Spacer(),

          // ── شارة حالة السحابة والمزامنة ──
          InkWell(
            onTap: isOnline
                ? () {
                    ref.invalidate(syncNowProvider);
                  }
                : null,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isOnline
                    ? (syncStatus == SyncStatus.syncing
                        ? Colors.blue.withOpacity(0.12)
                        : Colors.green.withOpacity(0.12))
                    : Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isOnline
                      ? (syncStatus == SyncStatus.syncing
                          ? Colors.blue.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3))
                      : Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (syncStatus == SyncStatus.syncing)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF2196F3)),
                      ),
                    )
                  else
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    !isOnline
                        ? 'أوفلاين (كاش محلي)'
                        : syncStatus == SyncStatus.syncing
                            ? 'جارٍ المزامنة...'
                            : (pendingCount > 0
                                ? '$pendingCount بانتظار المزامنة'
                                : 'متصل بالسحابة ✓'),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isOnline
                          ? (syncStatus == SyncStatus.syncing
                              ? const Color(0xFF2196F3)
                              : const Color(0xFF16A34A))
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── زر طي / إظهار القائمة الجانبية من الهيدر ──
          Tooltip(
            message: _isSidebarCollapsed ? 'توسيع القائمة الجانبية' : 'طي القائمة الجانبية',
            child: IconButton(
              icon: Icon(
                _isSidebarCollapsed
                    ? Icons.menu_rounded
                    : Icons.menu_open_rounded,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // القائمة الجانبية للديسكتوب
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktopSidebar(BuildContext context, bool isDark) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final authState = ref.watch(authProvider);
    final shopName = authState.shopName ?? 'دفتري';
    final fullName = authState.fullName ?? 'المستخدم';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      width: _isSidebarCollapsed ? 76 : 260,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          left: BorderSide(color: borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── الهيدر واللوجو ──
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              height: 80,
              alignment: Alignment.center,
              child: Row(
                children: [
                  if (!_isSidebarCollapsed) ...[
                    Image.asset(
                      'assets/images/light.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.receipt_long, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'دفتري',
                            style: TextStyle(
                              fontFamily: 'KOMedia',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            shopName,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_isSidebarCollapsed)
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          'assets/images/light.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.receipt_long, color: AppColors.primary, size: 24),
                        ),
                      ),
                    ),
                  Tooltip(
                    message: _isSidebarCollapsed ? 'توسيع' : 'طي',
                    child: IconButton(
                      icon: Icon(
                        _isSidebarCollapsed
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSidebarCollapsed = !_isSidebarCollapsed;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(color: borderColor, height: 1),

          // ── بنود الملاحة ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              itemCount: _tabs.length,
              itemBuilder: (context, i) {
                final tab = _tabs[i];
                final isSelected = widget.navigationShell.currentIndex == i;
                final activeColor = isDark ? const Color(0xFF38B5A6) : AppColors.primary;
                final inactiveColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

                final itemColor = isSelected ? activeColor : inactiveColor;
                final activeBg = isDark ? const Color(0xFF0F322E) : AppColors.primarySurface;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Tooltip(
                    message: _isSidebarCollapsed ? tab.label : '',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => widget.navigationShell.goBranch(
                          i,
                          initialLocation: i == widget.navigationShell.currentIndex,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: _isSidebarCollapsed ? 0 : 16,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? activeBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected
                                ? Border.all(
                                    color: activeColor.withOpacity(0.25),
                                    width: 1,
                                  )
                                : null,
                          ),
                          alignment: _isSidebarCollapsed ? Alignment.center : Alignment.centerRight,
                          child: Row(
                            mainAxisAlignment: _isSidebarCollapsed
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            children: [
                              Icon(
                                isSelected ? tab.activeIcon : tab.icon,
                                color: itemColor,
                                size: 22,
                              ),
                              if (!_isSidebarCollapsed) ...[
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    tab.label,
                                    style: TextStyle(
                                      fontFamily: 'KOMedia',
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                      color: itemColor,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 6,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: activeColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(color: borderColor, height: 1),

          // ── بيانات المستخدم وتسجيل الخروج ──
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      widget.navigationShell.goBranch(4); // الانتقال للإعدادات
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (!_isSidebarCollapsed) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shopName,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    fullName,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.settings_outlined,
                              size: 18,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('تسجيل الخروج'),
                            content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('إلغاء'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                  minimumSize: const Size(80, 40),
                                ),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  ref.read(authProvider.notifier).logout();
                                },
                                child: const Text('خروج'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _isSidebarCollapsed ? 0 : 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isDark
                              ? Colors.red.withOpacity(0.12)
                              : Colors.red.withOpacity(0.06),
                        ),
                        alignment: _isSidebarCollapsed ? Alignment.center : Alignment.centerRight,
                        child: Row(
                          mainAxisAlignment: _isSidebarCollapsed
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            if (!_isSidebarCollapsed) ...[
                              const SizedBox(width: 10),
                              const Text(
                                'تسجيل الخروج',
                                style: TextStyle(
                                  fontFamily: 'KOMedia',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating Rounded Capsule Navigation Bar (Glassmorphic & Premium for Mobile)
// ─────────────────────────────────────────────────────────────────────────────

class _FlatNavBar extends StatelessWidget {
  const _FlatNavBar({
    required this.selectedIndex,
    required this.isDark,
    required this.onTap,
    required this.tabs,
  });

  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onTap;
  final List<({IconData icon, IconData activeIcon, String label})> tabs;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    final primaryDark = isDark ? const Color(0xFF0C1D1A) : AppColors.primaryDark;

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  primary,
                  primaryDark,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (i) {
                final tab = tabs[i];
                final isSelected = selectedIndex == i;
                return Expanded(
                  child: _NavItem(
                    icon: tab.icon,
                    activeIcon: tab.activeIcon,
                    label: tab.label,
                    isSelected: isSelected,
                    isDark: isDark,
                    onTap: () => onTap(i),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeBgColor = Colors.white;
    final activeIconColor = AppColors.primary;
    final inactiveColor = Colors.white.withOpacity(0.65);
    const activeTextColor = Colors.white;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            padding: EdgeInsets.all(isSelected ? 9 : 4),
            decoration: BoxDecoration(
              color: isSelected ? activeBgColor : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? Colors.black.withOpacity(0.15)
                      : Colors.transparent,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeIconColor : inactiveColor,
              size: isSelected ? 22 : 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'KOMedia',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? activeTextColor : Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}
