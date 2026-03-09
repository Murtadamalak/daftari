import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/providers/comprehensive_reports_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';
import '../core/utils/pdf_report_generator.dart';

final _amtFmt = NumberFormat('#,###', 'en');
String _fmt(double v) => '${_amtFmt.format(v)} د.ع';

class ComprehensiveReportsScreen extends ConsumerWidget {
  const ComprehensiveReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(comprehensiveReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل التقارير والأرباح'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Header controls (Presets) ──
          _HeaderPresets(),

          // ── Data Body ──
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (data) => _ReportBody(data: data),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderPresets extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curPreset =
        ref.watch(comprehensiveReportProvider.notifier).currentPreset;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PresetChip(label: 'اليوم', selected: curPreset == 'اليوم'),
                const SizedBox(width: 8),
                _PresetChip(
                    label: 'هذا الأسبوع', selected: curPreset == 'هذا الأسبوع'),
                const SizedBox(width: 8),
                _PresetChip(
                    label: 'هذا الشهر', selected: curPreset == 'هذا الشهر'),
                const SizedBox(width: 8),
                _CustomDateChip(selected: curPreset == 'تحديد مخصص'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Consumer(builder: (ctx, r, _) {
            final st = r.watch(comprehensiveReportProvider);
            return st.maybeWhen(
              data: (d) {
                final start =
                    DateFormat('yyyy/MM/dd').format(d.dateRange.start);
                final end = DateFormat('yyyy/MM/dd').format(d.dateRange.end);
                return Text('الفترة: من $start إلى $end',
                    style: GoogleFonts.almarai(
                        color: AppColors.textSecondary, fontSize: 13));
              },
              orElse: () => const SizedBox.shrink(),
            );
          }),
        ],
      ),
    );
  }
}

class _PresetChip extends ConsumerWidget {
  const _PresetChip({required this.label, required this.selected});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        if (val) {
          ref.read(comprehensiveReportProvider.notifier).setPreset(label);
        }
      },
    );
  }
}

class _CustomDateChip extends ConsumerWidget {
  const _CustomDateChip({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChoiceChip(
      label: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 14),
          SizedBox(width: 6),
          Text('تحديد مخصص'),
        ],
      ),
      selected: selected,
      onSelected: (val) async {
        if (!val) return;
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: now,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context),
              child: child!,
            );
          },
        );
        if (picked != null) {
          ref.read(comprehensiveReportProvider.notifier).setDateRange(picked);
        }
      },
    );
  }
}

class _ReportBody extends ConsumerWidget {
  const _ReportBody({required this.data});
  final ComprehensiveReportData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(comprehensiveReportProvider.notifier).loadData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Print Button ──
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.print_outlined),
              label: const Text('طباعة وتصدير تقرير الفترة PDF'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, 50),
              ),
              onPressed: () => _printReport(context, ref),
            ),
          ),
          const SizedBox(height: 24),

          // ── Overview Cards ──
          Text('ملخص الإيرادات والأرباح',
              style:
                  GoogleFonts.almarai(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _StatCard(
                  title: 'إجمالي المبيعات',
                  value: _fmt(data.totalSales),
                  color: AppColors.primary,
                  icon: Icons.point_of_sale),
              _StatCard(
                  title: 'المُحصل (نقدي)',
                  value: _fmt(data.totalPaid),
                  color: AppColors.success,
                  icon: Icons.payments_outlined),
              _StatCard(
                  title: 'الديون المتبقية',
                  value: _fmt(data.totalDebt),
                  color: AppColors.danger,
                  icon: Icons.warning_amber),
              _StatCard(
                  title: 'إجمالي الخصومات',
                  value: _fmt(data.totalDiscount),
                  color: AppColors.warning,
                  icon: Icons.discount_outlined),
            ],
          ),
          const SizedBox(height: 24),

          // ── Top Products ──
          Text('المنتجات المباعة (الكميات)',
              style:
                  GoogleFonts.almarai(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          if (data.itemQuantities.isEmpty)
            Center(
                child: Text('لم يتم بيع أي منتجات في هذه الفترة.',
                    style: GoogleFonts.almarai(color: AppColors.textSecondary)))
          else
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2))),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: data.itemQuantities.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final e = data.itemQuantities[i];
                  return ListTile(
                    leading: const Icon(Icons.inventory_2_outlined,
                        color: AppColors.primary),
                    title: Text(e.key, style: GoogleFonts.almarai(fontSize: 14)),
                    trailing: Text(
                      e.value == e.value.truncate()
                          ? e.value.toInt().toString()
                          : e.value.toStringAsFixed(2),
                      style: GoogleFonts.almarai(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.primary),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),

          // ── Invoices ──
          Text('فواتير هذه الفترة (${data.invoices.length})',
              style:
                  GoogleFonts.almarai(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          if (data.invoices.isEmpty)
            Center(
                child: Text('لا توجد فواتير لتسجيلها.',
                    style: GoogleFonts.almarai(color: AppColors.textSecondary)))
          else
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2))),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: data.invoices.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final inv = data.invoices[i];
                  return ListTile(
                    isThreeLine: inv.payType == 'تسديد دين',
                    title: Text(inv.customerName,
                        style: GoogleFonts.almarai(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        'رقم ${inv.formattedNum} - ${DateFormat('yyyy/MM/dd HH:mm').format(inv.date)}${inv.payType == 'تسديد دين' && inv.note != null ? '\n${inv.note}' : ''}',
                        style: GoogleFonts.almarai(
                          fontSize: 12,
                          color: inv.payType == 'تسديد دين'
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                        )),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_fmt(inv.grandTotal),
                            style:
                                GoogleFonts.almarai(fontWeight: FontWeight.w700)),
                        Text(
                          inv.payType == 'تسديد دين'
                              ? 'دُفعة مسددة'
                              : (inv.status == 'paid'
                                  ? 'مسدد'
                                  : (inv.status == 'partial' ? 'جزئي' : 'دين')),
                          style: TextStyle(
                            color: inv.payType == 'تسديد دين'
                                ? AppColors.primary
                                : (inv.status == 'paid'
                                    ? AppColors.success
                                    : (inv.status == 'partial'
                                        ? AppColors.warning
                                        : AppColors.danger)),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _printReport(BuildContext context, WidgetRef ref) async {
    try {
      final settings = ref.read(settingsProvider).valueOrNull;
      AppSnackBar.success(context, 'جاري توليد التقرير...');
      await PdfReportGenerator.generateAndShare(
        dateRange: data.dateRange,
        invoices: data.invoices,
        itemQuantities: data.itemQuantities,
        totalSales: data.totalSales,
        totalPaid: data.totalPaid,
        totalDebt: data.totalDebt,
        shopName: settings?.shopName,
        shopLogoPath: settings?.logoPath,
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, 'حدث خطأ أثناء الطباعة: $e');
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard(
      {required this.title,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: GoogleFonts.almarai(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(value,
                style: GoogleFonts.almarai(
                    fontSize: 18, color: color, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
