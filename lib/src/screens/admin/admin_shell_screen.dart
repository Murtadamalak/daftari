import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/auth_provider.dart';

class AdminShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AdminShellScreen({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bg = Color(0xFF0A1612);
    const surface = Color(0xFF13211D);
    const primary = Color(0xFF4DB896);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D4C3F), Color(0xFF4DB896)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'د',
                  style: GoogleFonts.almarai(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'لوحة الإدارة',
              style: GoogleFonts.almarai(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(left: 12),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: const Icon(Icons.logout_outlined,
                    color: Colors.red, size: 16),
              ),
              tooltip: 'تسجيل الخروج',
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: primary.withOpacity(0.15),
          ),
        ),
      ),
      body: navigationShell,
      bottomNavigationBar: _AdminNavBar(
        selectedIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

// ─── Admin Navigation Bar ─────────────────────────────────────────────────────

class _AdminNavBar extends StatelessWidget {
  const _AdminNavBar({
    required this.selectedIndex,
    required this.onTap,
  });
  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (
      icon: Icons.dashboard_outlined,
      active: Icons.dashboard,
      label: 'الرئيسية'
    ),
    (
      icon: Icons.pending_actions_outlined,
      active: Icons.pending_actions,
      label: 'الطلبات'
    ),
    (icon: Icons.people_outline, active: Icons.people, label: 'المستخدمين'),
    (icon: Icons.settings_outlined, active: Icons.settings, label: 'الإعدادات'),
  ];

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF13211D);
    const primary = Color(0xFF4DB896);
    const muted = Color(0xFF8AADA5);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          top: BorderSide(
            color: primary.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isSelected = selectedIndex == i;

              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary.withOpacity(0.12)
                        : Colors.transparent,
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
                          isSelected ? item.active : item.icon,
                          key: ValueKey(isSelected),
                          color: isSelected ? primary : muted,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: GoogleFonts.almarai(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected ? primary : muted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
