import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isDesktop ? _buildDrawer(context, isDark) : null,
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: widget.navigationShell,
            ),
          ),
          if (isDesktop)
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isDark ? AppColors.darkBorder : AppColors.border,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.menu,
                        size: 22,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : _FlatNavBar(
              selectedIndex: widget.navigationShell.currentIndex,
              isDark: isDark,
              onTap: (i) => widget.navigationShell.goBranch(
                i,
                initialLocation: i == widget.navigationShell.currentIndex,
              ),
              tabs: _tabs,
            ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark) {
    final bg = isDark ? AppColors.darkSurface : AppColors.white;

    return Drawer(
      backgroundColor: bg,
      width: 240,
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: Center(
                    child: Text(
                      'د',
                      style: GoogleFonts.cairo(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'دفتري',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'نظام المبيعات والديون',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // ── Nav Items ─────────────────────────────────────────────────────
          Expanded(
            child: Container(
              color: isDark ? AppColors.darkSurface : AppColors.background,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: _tabs.asMap().entries.map((e) {
                  final i = e.key;
                  final tab = e.value;
                  final isSelected = widget.navigationShell.currentIndex == i;
                  final textColor = isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary);

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          widget.navigationShell.goBranch(
                            i,
                            initialLocation:
                                i == widget.navigationShell.currentIndex,
                          );
                          Navigator.of(context).pop();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primarySurface
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(
                                    color: AppColors.primary.withOpacity(0.15),
                                    width: 1)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? tab.activeIcon : tab.icon,
                                color: textColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                tab.label,
                                style: GoogleFonts.cairo(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                              if (isSelected) ...[
                                const Spacer(),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Footer ────────────────────────────────────────────────────────
          Container(
            color: isDark ? AppColors.darkSurface : AppColors.background,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textDisabled),
                const SizedBox(width: 6),
                Text(
                  'دفتري — نظام إدارة المبيعات',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Flat & Modern Navigation Bar
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
    final bg = isDark
        ? AppColors.darkSurface.withOpacity(0.9)
        : AppColors.white.withOpacity(0.92);
    final topBorder = isDark
        ? AppColors.darkBorder.withOpacity(0.5)
        : AppColors.border.withOpacity(0.8);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              top: BorderSide(color: topBorder, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(tabs.length, (i) {
                  final tab = tabs[i];
                  final isSelected = selectedIndex == i;
                  return _NavItem(
                    icon: tab.icon,
                    activeIcon: tab.activeIcon,
                    label: tab.label,
                    isSelected: isSelected,
                    isDark: isDark,
                    onTap: () => onTap(i),
                  );
                }),
              ),
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
    final primary = isDark ? const Color(0xFF4DB896) : AppColors.primary;
    final muted = isDark ? AppColors.darkTextSecondary : AppColors.textDisabled;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? primary : muted,
                size: 21,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? primary : muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
