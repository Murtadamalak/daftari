import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/comprehensive_reports_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_bar_logo.dart';
import '../data/repositories/invoice_repository.dart';

final _amtFmt = NumberFormat('#,###', 'en');
String _fmt(double v) => '${_amtFmt.format(v)} د.ع';

class TransactionsLogScreen extends ConsumerStatefulWidget {
  const TransactionsLogScreen({super.key});

  @override
  ConsumerState<TransactionsLogScreen> createState() => _TransactionsLogScreenState();
}

class _TransactionsLogScreenState extends ConsumerState<TransactionsLogScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(comprehensiveReportProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const AppBarLogo(),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: (isDark ? const Color(0xFF0A1612) : const Color(0xFFF7F5F0)).withOpacity(0.4),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0A1612), const Color(0xFF13211D)]
                : [const Color(0xFFF7F5F0), const Color(0xFFEEEBE1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight - 8),
            
            // ── Time Frame Selectors ──
            const _HeaderPresets(),

            // ── Search field ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF101D1A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isDark ? const Color(0xFF1E3C36) : const Color(0xFFD0DCDA)).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: const TextStyle(
                    fontFamily: 'KOMedia',
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'البحث باسم الزبون...',
                    hintStyle: TextStyle(
                      fontFamily: 'KOMedia',
                      fontSize: 13,
                      color: isDark ? const Color(0xFF85AFA7).withOpacity(0.6) : const Color(0xFF9CA3AF),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? const Color(0xFF85AFA7) : const Color(0xFF9CA3AF),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

            // ── Content ──
            Expanded(
              child: state.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('حدث خطأ: $e', style: GoogleFonts.almarai(color: Colors.red))),
                data: (data) {
                  // Filter invoices based on search query
                  final filteredInvoices = data.invoices.where((inv) {
                    if (_searchQuery.trim().isEmpty) return true;
                    return inv.customerName.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  // Sort latest first
                  filteredInvoices.sort((a, b) => b.date.compareTo(a.date));

                  return _TransactionsList(
                    invoices: filteredInvoices,
                    totalPaid: data.totalPaid,
                    totalDebt: data.totalDebt,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderPresets extends ConsumerWidget {
  const _HeaderPresets();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curPreset = ref.watch(comprehensiveReportProvider.notifier).currentPreset;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PresetChip(label: 'اليوم', selected: curPreset == 'اليوم'),
                const SizedBox(width: 8),
                _PresetChip(label: 'هذا الأسبوع', selected: curPreset == 'هذا الأسبوع'),
                const SizedBox(width: 8),
                _PresetChip(label: 'هذا الشهر', selected: curPreset == 'هذا الشهر'),
                const SizedBox(width: 8),
                _CustomDateChip(selected: curPreset == 'تحديد مخصص'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Consumer(builder: (ctx, r, _) {
            final st = r.watch(comprehensiveReportProvider);
            return st.maybeWhen(
              data: (d) {
                final start = DateFormat('yyyy/MM/dd').format(d.dateRange.start);
                final end = DateFormat('yyyy/MM/dd').format(d.dateRange.end);
                return Center(
                  child: Text(
                    'الفترة: من $start إلى $end',
                    style: TextStyle(
                      fontFamily: 'KOMedia',
                      color: isDark ? const Color(0xFF85AFA7) : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                );
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
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'KOMedia',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: selected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
        ),
      ),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF162A26) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected
              ? Colors.transparent
              : (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E3C36).withOpacity(0.5)
                  : const Color(0xFFD0DCDA)),
        ),
      ),
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
    return ActionChip(
      avatar: Icon(
        Icons.calendar_today,
        size: 14,
        color: selected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
      ),
      label: Text(
        'مخصص',
        style: TextStyle(
          fontFamily: 'KOMedia',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: selected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
        ),
      ),
      backgroundColor: selected
          ? AppColors.primary
          : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF162A26) : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected
              ? Colors.transparent
              : (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E3C36).withOpacity(0.5)
                  : const Color(0xFFD0DCDA)),
        ),
      ),
      onPressed: () async {
        final currentRange = ref.read(comprehensiveReportProvider.notifier).currentRange;
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          initialDateRange: currentRange,
          locale: const Locale('ar'),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                      surface: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF0F1E1B)
                          : Colors.white,
                    ),
              ),
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

class _TransactionsList extends StatelessWidget {
  const _TransactionsList({
    required this.invoices,
    required this.totalPaid,
    required this.totalDebt,
  });

  final List<InvoiceModel> invoices;
  final double totalPaid;
  final double totalDebt;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      children: [
        // ── Financial Summary Cards ──
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'إجمالي المقبوضات',
                value: _fmt(totalPaid),
                color: AppColors.success,
                icon: Icons.move_to_inbox_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'الديون المتولدة',
                value: _fmt(totalDebt),
                color: AppColors.danger,
                icon: Icons.outbox_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Text(
          'تفاصيل السجل (${invoices.length} حركة)',
          style: const TextStyle(
            fontFamily: 'KOMedia',
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 10),

        if (invoices.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                'لا توجد حركات مالية مسجلة لهذه الفترة.',
                style: TextStyle(
                  fontFamily: 'KOMedia',
                  fontSize: 15,
                  color: isDark ? const Color(0xFF85AFA7) : AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ...invoices.map((inv) => _TransactionCard(invoice: inv)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101D1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? const Color(0xFF1E3C36) : const Color(0xFFD0DCDA)).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'KOMedia',
                    fontSize: 13,
                    color: isDark ? const Color(0xFF85AFA7) : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'KOMedia',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F1E1B),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.invoice});
  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isDebtPayment = invoice.payType == 'تسديد دين';
    final hasRemaining = invoice.debt > 0;

    String typeLabel = 'بيع نقدي';
    Color typeColor = AppColors.success;
    IconData typeIcon = Icons.check_circle_outline;

    if (isDebtPayment) {
      typeLabel = 'تسديد دين';
      typeColor = AppColors.primary;
      typeIcon = Icons.price_check_outlined;
    } else if (hasRemaining) {
      typeLabel = 'بيع بالآجل';
      typeColor = AppColors.warning;
      typeIcon = Icons.hourglass_bottom_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101D1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? const Color(0xFF1E3C36) : const Color(0xFFD0DCDA)).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            context.push('/invoices/details/${invoice.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon Type indicator
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),

                // Transaction Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.customerName,
                        style: TextStyle(
                          fontFamily: 'KOMedia',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F1E1B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            typeLabel,
                            style: TextStyle(
                              fontFamily: 'KOMedia',
                              fontSize: 13,
                              color: typeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('yyyy/MM/dd hh:mm a', 'ar').format(invoice.date),
                            style: TextStyle(
                              fontFamily: 'KOMedia',
                              fontSize: 12,
                              color: isDark ? const Color(0xFF85AFA7).withOpacity(0.8) : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (invoice.note != null && invoice.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          invoice.note!,
                          style: TextStyle(
                            fontFamily: 'KOMedia',
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]
                    ],
                  ),
                ),

                // Financial columns
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Paid amount (Green/Bold)
                    Text(
                      '+ ${_fmt(invoice.paid)}',
                      style: const TextStyle(
                        fontFamily: 'KOMedia',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Remaining Debt
                    if (invoice.debt > 0)
                      Text(
                        'المتبقي: ${_fmt(invoice.debt)}',
                        style: const TextStyle(
                          fontFamily: 'KOMedia',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      )
                    else
                      const Text(
                        'مسدد بالكامل ✓',
                        style: TextStyle(
                          fontFamily: 'KOMedia',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
