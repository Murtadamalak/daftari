import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

import '../core/providers/settings_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';
import '../core/utils/backup_service.dart';
import '../core/providers/app_providers.dart';
import '../core/providers/invoices_provider.dart';
import '../core/widgets/refresh_action_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _ownerCtrl.dispose();
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
          _ownerCtrl.text = settings.ownerName;
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
                      controller: _ownerCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم صاحب المحل (الاسم الكامل)',
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'أدخل الاسم الثلاثي',
                      ),
                      onChanged: (v) =>
                          ref.read(settingsProvider.notifier).setOwnerName(v),
                    ),
                    const SizedBox(height: 16),
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

              // ── Backup & Restore ─────────────────────────────────────────
              _SectionHeader(
                  title: 'النسخ الاحتياطي والاسترداد',
                  icon: Icons.cloud_sync_outlined),
              const SizedBox(height: 16),
              _SettingsCard(
                child: Column(
                  children: [
                    // Export
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.cloud_upload_outlined,
                            color: Color(0xFF10B981), size: 22),
                      ),
                      title: Text(
                        'إنشاء نسخة احتياطية',
                        style: GoogleFonts.almarai(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'تصدير كل البيانات (منتجات، فواتير، زبائن، ديون) إلى ملف JSON',
                        style: GoogleFonts.almarai(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => _handleExport(context),
                    ),
                    const Divider(height: 20),
                    // Restore
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.cloud_download_outlined,
                            color: Color(0xFF6366F1), size: 22),
                      ),
                      title: Text(
                        'استرداد من نسخة احتياطية',
                        style: GoogleFonts.almarai(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'رفع ملف JSON لاستعادة البيانات (سيُستبدل بالبيانات الموجودة)',
                        style: GoogleFonts.almarai(
                            fontSize: 12, color: AppColors.danger),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => _confirmRestore(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Data Management ──────────────────────────────────────────
              _SectionHeader(
                  title: 'إدارة البيانات', icon: Icons.storage_outlined),
              const SizedBox(height: 16),
              _SettingsCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.format_list_numbered_rtl,
                          color: AppColors.primary),
                      title: Text(
                        'إعادة ترقيم الفواتير',
                        style: GoogleFonts.almarai(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'سيعيد ترتيب أرقام الفواتير بالتسلسل من 1 حسب التاريخ (يعالج الفراغات في الأرقام)',
                        style: GoogleFonts.almarai(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => _confirmRenumberInvoices(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── About App ──────────────────────────────────────────────────
              _SectionHeader(
                  title: 'حول التطبيق وحسابي', icon: Icons.info_outlined),
              const SizedBox(height: 16),
              _SettingsCard(
                child: Column(
                  children: [
                    _InfoRow(label: 'الإصدار', value: '1.0.0'),
                    const Divider(height: 1),
                    _InfoRow(label: 'التطبيق', value: 'نظام دفتري'),
                    const Divider(height: 1),
                    _InfoRow(
                      label: 'اخر تسجيل دخول',
                      value: authState.user?.lastSignInAt != null
                          ? DateFormat('yyyy/MM/dd  hh:mm a', 'ar').format(
                              DateTime.parse(authState.user!.lastSignInAt!)
                                  .toLocal())
                          : 'غير متوفر',
                    ),
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
                                  style: GoogleFonts.almarai(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              Text('مرتضى علاء',
                                  style: GoogleFonts.almarai(
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
                    style: GoogleFonts.almarai(
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
        title: Text('تسجيل الخروج', style: GoogleFonts.almarai()),
        content: Text('هل أنت متأكد أنك تريد تسجيل الخروج؟',
            style: GoogleFonts.almarai()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء',
                style: GoogleFonts.almarai(color: AppColors.textSecondary)),
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
            child:
                Text('خروج', style: GoogleFonts.almarai(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Backup export ─────────────────────────────────────────────────────────

  Future<void> _handleExport(BuildContext context) async {
    // Show loading
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF10B981))),
            const SizedBox(height: 24),
            Text(
              'جاري تجميع البيانات...',
              style: GoogleFonts.almarai(
                  fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 8),
            Text('يرجى الانتظار',
                style: GoogleFonts.almarai(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );

    try {
      await BackupService.exportBackup();
      if (context.mounted) {
        Navigator.pop(context); // hide loading
        _showBackupSuccessDialog(context);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        AppSnackBar.error(context, 'فشل تصدير النسخة الاحتياطية: $e');
      }
    }
  }

  void _showBackupSuccessDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_done_outlined,
                  color: Color(0xFF10B981), size: 60),
            ),
            const SizedBox(height: 20),
            Text(
              'تم إنشاء النسخة الاحتياطية!',
              style: GoogleFonts.almarai(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10B981)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'تم تصدير جميع بياناتك (الزبائن، المنتجات، الفواتير، الديون) إلى ملف JSON. احفظ الملف في مكان آمن.',
              style: GoogleFonts.almarai(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('حسناً',
                    style: GoogleFonts.almarai(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Backup restore ────────────────────────────────────────────────────────

  void _confirmRestore(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.danger, size: 26),
            const SizedBox(width: 10),
            Text('تحذير مهم', style: GoogleFonts.almarai()),
          ],
        ),
        content: Text(
          'سيؤدي الاسترداد إلى حذف جميع بياناتك الحالية (الزبائن، المنتجات، الفواتير) واستبدالها ببيانات ملف النسخة الاحتياطية.\n\nهل تريد المتابعة؟',
          style: GoogleFonts.almarai(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء',
                style: GoogleFonts.almarai(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              _handleRestore(context, ref);
            },
            child: Text('متابعة واختيار الملف',
                style: GoogleFonts.almarai(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    try {
      // 1. اختيار الملف
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) {
        if (context.mounted) {
          AppSnackBar.error(context, 'تعذّر قراءة الملف');
        }
        return;
      }

      // 2. عرض شاشة التحميل
      if (!context.mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1))),
              const SizedBox(height: 24),
              Text(
                'جاري استرداد البيانات...',
                style: GoogleFonts.almarai(
                    fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
              ),
              const SizedBox(height: 8),
              Text('يرجى الانتظار، لا تغلق التطبيق',
                  style: GoogleFonts.almarai(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );

      // 3. تنفيذ الاسترداد
      final restoreResult =
          await BackupService.restoreFromBytes(fileBytes, clearFirst: true);

      // 4. تحديث البيانات في الـ UI
      ref.invalidate(allInvoicesProvider);
      ref.invalidate(invoiceRepositoryProvider);
      ref.invalidate(customerRepositoryProvider);
      ref.invalidate(productRepositoryProvider);

      if (context.mounted) {
        Navigator.pop(context); // إغلاق شاشة التحميل
        _showRestoreSuccessDialog(context, restoreResult);
      }
    } catch (e) {
      if (context.mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
        AppSnackBar.error(context,
            'فشل الاسترداد: ${e.toString().replaceFirst('FormatException: ', '')}');
      }
    }
  }

  void _showRestoreSuccessDialog(BuildContext context, RestoreResult result) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_done_outlined,
                  color: Color(0xFF6366F1), size: 60),
            ),
            const SizedBox(height: 20),
            Text(
              'تم الاسترداد بنجاح!',
              style: GoogleFonts.almarai(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6366F1)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            _RestoreStat(
                icon: Icons.people_outline,
                label: 'الزبائن',
                count: result.customers),
            _RestoreStat(
                icon: Icons.inventory_2_outlined,
                label: 'المنتجات',
                count: result.products),
            _RestoreStat(
                icon: Icons.receipt_long_outlined,
                label: 'الفواتير',
                count: result.invoices),
            _RestoreStat(
                icon: Icons.list_alt_outlined,
                label: 'بنود الفواتير',
                count: result.invoiceItems),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/invoices');
                },
                child: Text('مشاهدة الفواتير',
                    style: GoogleFonts.almarai(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRenumberInvoices(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إعادة ترقيم الفواتير', style: GoogleFonts.almarai()),
        content: Text(
          'هل أنت متأكد؟ هذا سيقوم بتحديث أرقام جميع الفواتير لتكون متسلسلة (1, 2, 3...) حسب تاريخ إنشائها. هذا الإجراء مفيد إذا كان هناك فجوات أو أرقام غير مرتبة.',
          style: GoogleFonts.almarai(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء',
                style: GoogleFonts.almarai(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              _handleRenumber(context, ref);
            },
            child:
                Text('تأكيد', style: GoogleFonts.almarai(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRenumber(BuildContext context, WidgetRef ref) async {
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'جاري إعادة ترقيم الفواتير...',
                style: GoogleFonts.almarai(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'يرجى الانتظار، يتم تحديث البيانات',
                style: GoogleFonts.almarai(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );

      await ref.read(invoiceRepositoryProvider).renumberAllInvoices();

      if (context.mounted) {
        Navigator.pop(context); // hide loading

        // Refresh data
        ref.invalidate(allInvoicesProvider);
        ref.invalidate(invoiceRepositoryProvider);

        // Show success notice
        _showSuccessNotice(context);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // hide loading
        AppSnackBar.error(context, 'حدث خطأ أثناء إعادة الترقيم: $e');
      }
    }
  }

  void _showSuccessNotice(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with glowing effect
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'اكتملت المهمة بنجاح!',
              style: GoogleFonts.almarai(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'تمت إعادة ترقيم كافة الفواتير والمقبوضات بالتسلسل الصحيح (1, 2, 3...) بناءً على تاريخ إنشائها.',
              style: GoogleFonts.almarai(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.receipt_long,
                    size: 20, color: Colors.white),
                label: Text(
                  'مشاهدة سجل الفواتير',
                  style: GoogleFonts.almarai(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/invoices');
                },
              ),
            ),
          ],
        ),
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
                            style: GoogleFonts.almarai(
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
          style: GoogleFonts.almarai(
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
        style: GoogleFonts.almarai(
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
              style: GoogleFonts.almarai(
                  fontSize: 14, color: AppColors.textSecondary)),
          Text(value,
              style: GoogleFonts.almarai(
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
              style: GoogleFonts.almarai(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            Text(
              'المبرمج: مرتضى علاء',
              style: GoogleFonts.almarai(
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
                style: GoogleFonts.almarai(
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
              style: GoogleFonts.almarai(
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
                style: GoogleFonts.almarai(fontWeight: FontWeight.w600),
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

class _RestoreStat extends StatelessWidget {
  const _RestoreStat({
    required this.icon,
    required this.label,
    required this.count,
  });
  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6366F1)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: GoogleFonts.almarai(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.almarai(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );
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
          style: GoogleFonts.almarai(
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
