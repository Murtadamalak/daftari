import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:daftar_debt_manager/src/core/widgets/app_bar_logo.dart';

import '../core/providers/app_providers.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';
import '../data/repositories/expense_repository.dart';

// ─── Formatters ───────────────────────────────────────────────────────────────
final _numFmt = NumberFormat('#,###', 'en');
String _fmtMoney(double v) => '${_numFmt.format(v.round())} د.ع';
String _fmtDate(String d) {
  final dt = DateTime.tryParse(d);
  if (dt == null) return d;
  return DateFormat('yyyy/MM/dd').format(dt);
}

// ─── Category icon/color maps ─────────────────────────────────────────────────
const Map<String, IconData> _catIcons = {
  'مواد خام': Icons.inventory_2_outlined,
  'رواتب': Icons.people_outline,
  'إيجار': Icons.home_work_outlined,
  'كهرباء ومياه': Icons.bolt_outlined,
  'نقل وتوصيل': Icons.local_shipping_outlined,
  'صيانة': Icons.build_outlined,
  'تسويق وإعلان': Icons.campaign_outlined,
  'مصاريف إدارية': Icons.folder_open_outlined,
  'أخرى': Icons.more_horiz_outlined,
};

const Map<String, Color> _catColors = {
  'مواد خام': Color(0xFF7C3AED),
  'رواتب': Color(0xFF2563EB),
  'إيجار': Color(0xFF059669),
  'كهرباء ومياه': Color(0xFFD97706),
  'نقل وتوصيل': Color(0xFF0891B2),
  'صيانة': Color(0xFF9F1239),
  'تسويق وإعلان': Color(0xFFDB2777),
  'مصاريف إدارية': Color(0xFF4B5563),
  'أخرى': Color(0xFF6B7280),
};

enum _DateFilter { today, week, month, all }

const _filterLabels = {
  _DateFilter.today: 'اليوم',
  _DateFilter.week: 'هذا الأسبوع',
  _DateFilter.month: 'هذا الشهر',
  _DateFilter.all: 'الكل',
};

// =============================================================================
// ExpensesScreen
// =============================================================================
class ExpensesScreen extends ConsumerStatefulWidget {
  final String? linkedInvoiceId;
  final String? linkedInvoiceNum;
  const ExpensesScreen({super.key, this.linkedInvoiceId, this.linkedInvoiceNum});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  _DateFilter _filter = _DateFilter.month;
  String? _catFilter;

  List<ExpenseModel> _applyFilters(List<ExpenseModel> all) {
    final now = DateTime.now();
    DateTime? from;
    DateTime? to;
    switch (_filter) {
      case _DateFilter.today:
        from = DateTime(now.year, now.month, now.day);
        to = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case _DateFilter.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        from = DateTime(weekStart.year, weekStart.month, weekStart.day);
        to = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case _DateFilter.month:
        from = DateTime(now.year, now.month, 1);
        to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case _DateFilter.all:
        break;
    }
    return all.where((e) {
      final d = DateTime.tryParse(e.date);
      if (d == null) return false;
      if (from != null && d.isBefore(from)) return false;
      if (to != null && d.isAfter(to)) return false;
      if (_catFilter != null && e.category != _catFilter) return false;
      if (widget.linkedInvoiceId != null && e.invoiceId != widget.linkedInvoiceId) {
        return false;
      }
      return true;
    }).toList();
  }

  double _total(List<ExpenseModel> list) => list.fold(0.0, (s, e) => s + e.amount);

  Map<String, double> _byCategory(List<ExpenseModel> list) {
    final m = <String, double>{};
    for (final e in list) {
      m[e.category] = (m[e.category] ?? 0) + e.amount;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expAsync = ref.watch(allExpensesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: widget.linkedInvoiceId != null
            ? Text(
                'مصروفات الفاتورة #${widget.linkedInvoiceNum ?? ""}',
                style: TextStyle(
                  fontFamily: 'KOMedia',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              )
            : const AppBarLogo(),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: (isDark ? const Color(0xFF0A1612) : const Color(0xFFF7F5F0))
                  .withValues(alpha: 0.6),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9F1239),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontFamily: 'KOMedia', fontSize: 13, fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة'),
              onPressed: () => _openAddSheet(context),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0A1612), const Color(0xFF13211D)]
                : [const Color(0xFFF7F5F0), const Color(0xFFEEEBE1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: expAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(
              child: Text('خطأ: $e', style: const TextStyle(color: AppColors.danger))),
          data: (all) {
            final expenses = _applyFilters(all);
            final total = _total(expenses);
            final byCat = _byCategory(expenses);
            return _buildContent(context, isDark, expenses, total, byCat);
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isDark,
    List<ExpenseModel> expenses,
    double total,
    Map<String, double> byCat,
  ) {
    final topPad = MediaQuery.of(context).padding.top + kToolbarHeight;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: topPad + 8)),

        // Date filters
        if (widget.linkedInvoiceId == null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _DateFilter.values.map((f) {
                    final sel = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(
                          _filterLabels[f]!,
                          style: TextStyle(
                            fontFamily: 'KOMedia',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: sel
                                ? Colors.white
                                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          ),
                        ),
                        selected: sel,
                        onSelected: (_) => setState(() => _filter = f),
                        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                        selectedColor: AppColors.primary,
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: sel
                              ? AppColors.primary
                              : (isDark ? AppColors.darkBorder : AppColors.border),
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Summary card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SummaryCard(total: total, count: expenses.length),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Category breakdown
        if (byCat.isNotEmpty && widget.linkedInvoiceId == null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CategoryBreakdown(
                byCat: byCat,
                total: total,
                isDark: isDark,
                activeFilter: _catFilter,
                onFilter: (cat) =>
                    setState(() => _catFilter = _catFilter == cat ? null : cat),
              ),
            ),
          ),

        if (byCat.isNotEmpty && widget.linkedInvoiceId == null)
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(children: [
              Icon(Icons.receipt_long_outlined,
                  size: 16,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'قائمة المصروفات (${expenses.length})',
                style: TextStyle(
                  fontFamily: 'KOMedia',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ]),
          ),
        ),

        // Empty state
        if (expenses.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                child: Column(children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 56,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textDisabled),
                  const SizedBox(height: 12),
                  Text('لا توجد مصروفات مسجّلة',
                      style: TextStyle(
                        fontFamily: 'KOMedia',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      )),
                  const SizedBox(height: 6),
                  Text('اضغط "+ إضافة" لتسجيل مصروف جديد',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textDisabled,
                      )),
                ]),
              ),
            ),
          ),

        // List
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 0, 16, i == expenses.length - 1 ? 80 : 10),
              child: _ExpenseCard(
                expense: expenses[i],
                isDark: isDark,
                onEdit: () => _openEditSheet(context, expenses[i]),
                onDelete: () => _confirmDelete(context, expenses[i]),
              ),
            ),
            childCount: expenses.length,
          ),
        ),
      ],
    );
  }

  void _openAddSheet(BuildContext ctx) => showModalBottomSheet<void>(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ExpenseFormSheet(
          linkedInvoiceId: widget.linkedInvoiceId,
          linkedInvoiceNum: widget.linkedInvoiceNum,
          onSaved: () {
            ref.invalidate(allExpensesProvider);
            if (mounted) AppSnackBar.success(ctx, 'تم حفظ المصروف بنجاح');
          },
        ),
      );

  void _openEditSheet(BuildContext ctx, ExpenseModel e) =>
      showModalBottomSheet<void>(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ExpenseFormSheet(
          existing: e,
          linkedInvoiceId: widget.linkedInvoiceId,
          linkedInvoiceNum: widget.linkedInvoiceNum,
          onSaved: () {
            ref.invalidate(allExpensesProvider);
            if (mounted) AppSnackBar.success(ctx, 'تم تحديث المصروف');
          },
        ),
      );

  void _confirmDelete(BuildContext ctx, ExpenseModel e) => showDialog<void>(
        context: ctx,
        builder: (dlg) => AlertDialog(
          title: const Text('حذف المصروف',
              style: TextStyle(fontFamily: 'KOMedia', fontWeight: FontWeight.w800)),
          content: Text('هل تريد حذف "${e.title}"؟\nلا يمكن التراجع.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dlg).pop(),
                child: const Text('إلغاء')),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('حذف', style: TextStyle(fontFamily: 'KOMedia')),
              onPressed: () async {
                Navigator.of(dlg).pop();
                try {
                  await ref.read(expenseRepositoryProvider).delete(e.id);
                  ref.invalidate(allExpensesProvider);
                  if (!ctx.mounted) return;
                  AppSnackBar.success(ctx, 'تم حذف المصروف');
                } catch (err) {
                  if (!ctx.mounted) return;
                  AppSnackBar.error(ctx, 'فشل الحذف: $err');
                }
              },
            ),
          ],
        ),
      );
}

// =============================================================================
// _SummaryCard
// =============================================================================
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total, required this.count});
  final double total;
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF881337), Color(0xFFBE185D)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9F1239).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('إجمالي المصروفات',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 4),
              Text(_fmtMoney(total),
                  style: const TextStyle(
                    fontFamily: 'KOMedia',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  )),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$count مصروف',
                style: const TextStyle(
                  fontFamily: 'KOMedia',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                )),
          ),
        ]),
      );
}

// =============================================================================
// _CategoryBreakdown
// =============================================================================
class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({
    required this.byCat,
    required this.total,
    required this.isDark,
    required this.onFilter,
    required this.activeFilter,
  });
  final Map<String, double> byCat;
  final double total;
  final bool isDark;
  final void Function(String) onFilter;
  final String? activeFilter;

  @override
  Widget build(BuildContext context) {
    final sorted = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.pie_chart_outline, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('توزيع المصروفات حسب الفئة',
              style: TextStyle(
                fontFamily: 'KOMedia',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              )),
        ]),
        const SizedBox(height: 14),
        ...sorted.map((entry) {
          final pct = total > 0 ? entry.value / total : 0.0;
          final color = _catColors[entry.key] ?? AppColors.primary;
          final isActive = activeFilter == entry.key;
          return GestureDetector(
            onTap: () => onFilter(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive ? color.withValues(alpha: 0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? color.withValues(alpha: 0.35)
                      : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_catIcons[entry.key] ?? Icons.circle, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key,
                            style: TextStyle(
                              fontFamily: 'KOMedia',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            )),
                        Text(_fmtMoney(entry.value),
                            style: TextStyle(
                              fontFamily: 'KOMedia',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            )),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: isDark ? AppColors.darkBorder : AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 5,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                Text('${(pct * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    )),
              ]),
            ),
          );
        }),
      ]),
    );
  }
}

// =============================================================================
// _ExpenseCard
// =============================================================================
class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });
  final ExpenseModel expense;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _catColors[expense.category] ?? AppColors.primary;
    final icon = _catIcons[expense.category] ?? Icons.circle;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(expense.title,
                        style: TextStyle(
                          fontFamily: 'KOMedia',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text(_fmtMoney(expense.amount),
                      style: const TextStyle(
                        fontFamily: 'KOMedia',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF9F1239),
                      )),
                ]),
                const SizedBox(height: 4),
                Wrap(spacing: 6, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(expense.category,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: color,
                        )),
                  ),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textDisabled),
                    const SizedBox(width: 3),
                    Text(_fmtDate(expense.date),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textDisabled,
                        )),
                  ]),
                  if (expense.invoiceNum != null)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.receipt_outlined,
                          size: 11, color: AppColors.primary.withValues(alpha: 0.7)),
                      const SizedBox(width: 3),
                      Text('ف#${expense.invoiceNum}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: AppColors.primary.withValues(alpha: 0.8),
                          )),
                    ]),
                ]),
                if (expense.note != null && expense.note!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(expense.note!,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ]),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  size: 18,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('تعديل', style: TextStyle(fontFamily: 'KOMedia', fontSize: 13)),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('حذف',
                        style: TextStyle(
                            fontFamily: 'KOMedia', fontSize: 13, color: AppColors.danger)),
                  ]),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

// =============================================================================
// _ExpenseFormSheet
// =============================================================================
class _ExpenseFormSheet extends ConsumerStatefulWidget {
  const _ExpenseFormSheet({
    this.existing,
    this.linkedInvoiceId,
    this.linkedInvoiceNum,
    required this.onSaved,
  });
  final ExpenseModel? existing;
  final String? linkedInvoiceId;
  final String? linkedInvoiceNum;
  final VoidCallback onSaved;

  @override
  ConsumerState<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<_ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _category = kExpenseCategories.first;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _amountCtrl.text = e.amount == e.amount.roundToDouble()
          ? e.amount.toInt().toString()
          : e.amount.toStringAsFixed(2);
      _noteCtrl.text = e.note ?? '';
      _category = kExpenseCategories.contains(e.category) ? e.category : kExpenseCategories.last;
      _date = DateTime.tryParse(e.date) ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(expenseRepositoryProvider);
      final amount = double.parse(_amountCtrl.text.replaceAll(',', ''));
      final dateStr =
          '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

      if (widget.existing == null) {
        await repo.create(
          title: _titleCtrl.text,
          category: _category,
          amount: amount,
          date: _date,
          note: _noteCtrl.text,
          invoiceId: widget.linkedInvoiceId,
          invoiceNum: widget.linkedInvoiceNum,
        );
      } else {
        await repo.update(widget.existing!.copyWith(
          title: _titleCtrl.text,
          category: _category,
          amount: amount,
          date: dateStr,
          note: _noteCtrl.text,
        ));
      }
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, sc) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9F1239).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_outlined,
                      color: Color(0xFF9F1239), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  isEdit ? 'تعديل المصروف' : 'إضافة مصروف',
                  style: TextStyle(
                    fontFamily: 'KOMedia',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop()),
              ]),
            ),
            const Divider(height: 16),
            Expanded(
              child: SingleChildScrollView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Invoice link badge
                    if (widget.linkedInvoiceNum != null || widget.existing?.invoiceNum != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.receipt_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'مرتبط بالفاتورة #${widget.linkedInvoiceNum ?? widget.existing?.invoiceNum}',
                            style: const TextStyle(
                              fontFamily: 'KOMedia',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ]),
                      ),

                    _lbl('اسم المصروف *', isDark),
                    TextFormField(
                      controller: _titleCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: _dec('مثال: راتب موظف، فاتورة كهرباء...', isDark),
                      style: _ts(isDark),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'أدخل اسم المصروف' : null,
                    ),
                    const SizedBox(height: 16),

                    _lbl('المبلغ (د.ع) *', isDark),
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
                      textInputAction: TextInputAction.next,
                      decoration: _dec('0', isDark),
                      style: _ts(isDark),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'أدخل المبلغ';
                        final n = double.tryParse(v.replaceAll(',', ''));
                        if (n == null) return 'مبلغ غير صحيح';
                        if (n <= 0) return 'يجب أن يكون أكبر من صفر';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _lbl('الفئة *', isDark),
                    _buildCategoryPicker(isDark),
                    const SizedBox(height: 16),

                    _lbl('التاريخ', isDark),
                    GestureDetector(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setState(() => _date = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface2 : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.border),
                        ),
                        child: Row(children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 18,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('yyyy/MM/dd').format(_date),
                            style: TextStyle(
                              fontFamily: 'KOMedia',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _lbl('ملاحظات (اختياري)', isDark),
                    TextFormField(
                      controller: _noteCtrl,
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                      decoration: _dec('أضف أي تفاصيل إضافية...', isDark),
                      style: _ts(isDark),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF9F1239),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(
                              fontFamily: 'KOMedia', fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(isEdit ? Icons.save_outlined : Icons.add_circle_outline, size: 20),
                        label: Text(_saving
                            ? 'جارٍ الحفظ...'
                            : (isEdit ? 'حفظ التعديل' : 'إضافة المصروف')),
                        onPressed: _saving ? null : _save,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildCategoryPicker(bool isDark) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: kExpenseCategories.map((cat) {
          final sel = _category == cat;
          final color = _catColors[cat] ?? AppColors.primary;
          final icon = _catIcons[cat] ?? Icons.circle;
          return GestureDetector(
            onTap: () => setState(() => _category = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: sel
                    ? color.withValues(alpha: 0.12)
                    : (isDark ? AppColors.darkSurface2 : AppColors.background),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel ? color : (isDark ? AppColors.darkBorder : AppColors.border),
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon,
                    size: 14,
                    color: sel
                        ? color
                        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                const SizedBox(width: 5),
                Text(cat,
                    style: TextStyle(
                      fontFamily: 'KOMedia',
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                      color: sel
                          ? color
                          : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    )),
              ]),
            ),
          );
        }).toList(),
      );

  Widget _lbl(String t, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: TextStyle(
              fontFamily: 'KOMedia',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            )),
      );

  InputDecoration _dec(String hint, bool isDark) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textDisabled),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface2 : AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      );

  TextStyle _ts(bool isDark) => TextStyle(
        fontFamily: 'KOMedia',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      );
}

