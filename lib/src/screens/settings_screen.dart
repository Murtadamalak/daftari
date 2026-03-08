import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/providers/settings_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';
import '../core/providers/app_providers.dart';
import '../core/widgets/refresh_action_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);

    int? remainingDays;
    if (authState.endDate != null) {
      try {
        final endDate = DateTime.parse(authState.endDate!);
        final difference = endDate.difference(DateTime.now()).inDays;
        remainingDays = difference > 0 ? difference : 0;
      } catch (_) {}
    }

    return settingsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('خطأ: $e')),
      ),
      data: (settings) {
        // Populate text fields once
        if (!_loaded) {
          _nameCtrl.text = settings.shopName;
          _phoneCtrl.text = settings.shopPhone;
          _loaded = true;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('الإعدادات'),
            actions: [
              RefreshActionButton(
                onPressed: () {
                  ref.invalidate(settingsProvider);
                  ref.invalidate(authProvider);
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Shop Logo ─────────────────────────────────────────────────
              _SectionHeader(title: 'هوية المحل', icon: Icons.store_outlined),
              const SizedBox(height: 16),
              _LogoSection(logoPath: settings.logoPath),
              const SizedBox(height: 24),

              // ── Shop Info ─────────────────────────────────────────────────
              _SectionHeader(
                  title: 'بيانات المحل', icon: Icons.business_outlined),
              const SizedBox(height: 16),
              _SettingsCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم المحل',
                        prefixIcon: Icon(Icons.store_outlined),
                      ),
                      onChanged: (v) =>
                          ref.read(settingsProvider.notifier).setShopName(v),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      onChanged: (v) =>
                          ref.read(settingsProvider.notifier).setShopPhone(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Subscription Info ─────────────────────────────────────────
              _SectionHeader(
                  title: 'اشتراكي', icon: Icons.workspace_premium_outlined),
              const SizedBox(height: 16),
              _SettingsCard(
                child: Column(
                  children: [
                    _InfoRow(
                        label: 'الحالة',
                        value: authState.subStatus == 'active'
                            ? 'نشط'
                            : (authState.subStatus == 'expired'
                                ? 'منتهي'
                                : 'في الانتظار')),
                    const Divider(height: 1),
                    _InfoRow(
                        label: 'الباقة',
                        value: authState.planType == 'monthly'
                            ? 'شهرية'
                            : (authState.planType == 'yearly'
                                ? 'سنوية'
                                : 'مجانية')),
                    if (remainingDays != null) ...[
                      const Divider(height: 1),
                      _InfoRow(
                        label: 'الأيام المتبقية',
                        value: '$remainingDays يوم',
                        valueColor: remainingDays < 5
                            ? AppColors.danger
                            : AppColors.success,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Appearance ────────────────────────────────────────────────
              _SectionHeader(title: 'المظهر', icon: Icons.palette_outlined),
              const SizedBox(height: 16),
              _SettingsCard(
                child: Column(
                  children: [
                    _ThemeModeOption(
                      label: 'تلقائي (حسب الجهاز)',
                      icon: Icons.brightness_auto_outlined,
                      mode: ThemeMode.system,
                      selected: settings.themeMode,
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(ThemeMode.system),
                    ),
                    const Divider(height: 1),
                    _ThemeModeOption(
                      label: 'الوضع النهاري',
                      icon: Icons.light_mode_outlined,
                      mode: ThemeMode.light,
                      selected: settings.themeMode,
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(ThemeMode.light),
                    ),
                    const Divider(height: 1),
                    _ThemeModeOption(
                      label: 'الوضع الليلي',
                      icon: Icons.dark_mode_outlined,
                      mode: ThemeMode.dark,
                      selected: settings.themeMode,
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── About App ──────────────────────────────────────────────────
              _SectionHeader(title: 'حول التطبيق', icon: Icons.info_outlined),
              const SizedBox(height: 16),
              _SettingsCard(
                child: Column(
                  children: [
                    _InfoRow(label: 'الإصدار', value: '1.0.0'),
                    const Divider(height: 1),
                    _InfoRow(label: 'التطبيق', value: 'نظام دفتري'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── About Developer ───────────────────────────────────────────
              _SectionHeader(title: 'عن المبرمج', icon: Icons.code_outlined),
              const SizedBox(height: 16),
              _SettingsCard(
                child: Column(
                  children: [
                    // Developer preview row
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.computer_outlined,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('مكتب فن للتصميم والبرمجة',
                                  style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              Text('مرتضى علاء',
                                  style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    // More info button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('معلومات وتواصل'),
                        onPressed: () => _showAboutDeveloperDialog(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Logout Button ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: Text(
                    'تسجيل الخروج',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _confirmLogout(context, ref),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _showAboutDeveloperDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => const _AboutDeveloperDialog(),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تسجيل الخروج', style: GoogleFonts.cairo()),
        content: Text('هل أنت متأكد أنك تريد تسجيل الخروج؟',
            style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء',
                style: GoogleFonts.cairo(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);

              ref.invalidate(settingsProvider);
              ref.invalidate(productRepositoryProvider);
              ref.invalidate(invoiceRepositoryProvider);
              ref.invalidate(customerRepositoryProvider);

              ref.read(authProvider.notifier).logout();
            },
            child: Text('خروج', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo Section
// ─────────────────────────────────────────────────────────────────────────────

class _LogoSection extends ConsumerWidget {
  const _LogoSection({this.logoPath});
  final String? logoPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        children: [
          // Logo display
          GestureDetector(
            onTap: () => _pickLogo(context, ref),
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: logoPath != null
                    ? (kIsWeb
                        ? Image.network(logoPath!, fit: BoxFit.cover)
                        : (File(logoPath!).existsSync()
                            ? Image.file(File(logoPath!), fit: BoxFit.cover)
                            : const Icon(Icons.broken_image_outlined,
                                size: 36, color: Colors.grey)))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 36, color: AppColors.primary),
                          const SizedBox(height: 6),
                          Text(
                            'أضف شعاراً',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('اختيار صورة'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: () => _pickLogo(context, ref),
              ),
              if (logoPath != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('حذف'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      minimumSize: const Size(0, 40)),
                  onPressed: () =>
                      ref.read(settingsProvider.notifier).setLogoPath(null),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickLogo(BuildContext ctx, WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setLogoPath(picked.path);
    if (ctx.mounted) AppSnackBar.success(ctx, 'تم حفظ الشعار بنجاح');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
    required this.label,
    required this.icon,
    required this.mode,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final ThemeMode mode;
  final ThemeMode selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == mode;
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textDisabled,
      ),
      title: Text(
        label,
        style: GoogleFonts.cairo(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          color: isSelected
              ? AppColors.primary
              : Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: 14, color: AppColors.textSecondary)),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: valueColor)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// About Developer Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _AboutDeveloperDialog extends StatelessWidget {
  const _AboutDeveloperDialog();

  static const _phone1 = '07876007620';
  static const _phone2 = '07813938267';
  static const _telegram = 'https://t.me/art8ms';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Avatar ──
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.computer_outlined,
                  color: Colors.white, size: 40),
            ),

            const SizedBox(height: 16),

            // ── Office name ──
            Text(
              'مكتب فن للتصميم والبرمجة',
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            Text(
              'المبرمج: مرتضى علاء',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'نظام دفتري لإدارة الحسابات',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // ── Contact buttons ──
            Text(
              'تواصل معنا',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 12),

            // Phone 1
            _ContactButton(
              icon: Icons.phone_outlined,
              label: _phone1,
              color: AppColors.success,
              onTap: () => _launch('tel:$_phone1'),
            ),
            const SizedBox(height: 8),

            // Phone 2
            _ContactButton(
              icon: Icons.phone_outlined,
              label: _phone2,
              color: AppColors.success,
              onTap: () => _launch('tel:$_phone2'),
            ),
            const SizedBox(height: 8),

            // Telegram
            _ContactButton(
              icon: Icons.telegram,
              label: 'تليجرام: @art8ms',
              color: const Color(0xFF2CA5E0),
              onTap: () => _launch(_telegram),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إغلاق',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 18, color: color),
        label: Text(
          label,
          style: GoogleFonts.cairo(
              fontSize: 13, fontWeight: FontWeight.w600, color: color),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.5)),
          minimumSize: const Size(0, 44),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onTap,
      ),
    );
  }
}
