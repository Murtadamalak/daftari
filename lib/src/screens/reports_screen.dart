import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/providers/statistics_provider.dart';
import '../core/theme/app_theme.dart';
import '../data/repositories/invoice_repository.dart';

// ─── Formatters ───────────────────────────────────────────────────────────────
final _amtFmt = NumberFormat('#,###', 'en');
final _dateFmt = DateFormat('dd/MM  hh:mm a', 'ar');

String _fmt(double v) => '${_amtFmt.format(v)} د.ع';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('لوحة التحكم',
            style: GoogleFonts.almarai(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.primary)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppColors.primary)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.refresh_outlined,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.primary,
                    size: 18),
              ),
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(dashboardStatsProvider),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF0A1612), const Color(0xFF13211D)]
                : [const Color(0xFFF7F5F0), const Color(0xFFEEEBE1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: statsAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => _ErrorView(error: e.toString()),
          data: (stats) => _DashboardBody(stats: stats),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Body
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(dashboardStatsProvider),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              isWide ? 32 : 16,
              MediaQuery.of(context).padding.top +
                  70, // Clear transparent AppBar
              isWide ? 32 : 16,
              40,
            ),
            children: [
              // ── Greeting ────────────────────────────────────────────────────────
              _GreetingHeader(stats: stats),
              const SizedBox(height: 20),

              // ── KPI Cards ───────────────────────────────────────────────────────
              _SectionTitle(title: 'نظرة عامة', icon: Icons.dashboard_outlined),
              const SizedBox(height: 12),
              _KpiGrid(stats: stats),
              const SizedBox(height: 20),

              // ── Reports Button ────────────────────────────────────────────────
              _ReportsButton(
                  onTap: () => context.push('/reports/comprehensive')),
              const SizedBox(height: 24),

              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildUnpaidSection()),
                    const SizedBox(width: 32),
                    Expanded(child: _buildTodaySection()),
                  ],
                )
              else ...[
                _buildUnpaidSection(),
                const SizedBox(height: 24),
                _buildTodaySection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnpaidSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'الديون النشطة',
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.danger,
          badge: stats.unpaidCount > 0 ? '${stats.unpaidCount}' : null,
          badgeColor: AppColors.danger,
        ),
        const SizedBox(height: 12),
        if (stats.unpaidInvoices.isEmpty)
          _EmptyCard(
            icon: Icons.check_circle_outline,
            message: 'لا توجد ديون مطلوبة 🎉',
            color: AppColors.success,
          )
        else
          _InvoiceList(invoices: stats.unpaidInvoices, showDebt: true),
      ],
    );
  }

  Widget _buildTodaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'نشاط اليوم',
          icon: Icons.today_outlined,
          badge: stats.todayInvoices.isNotEmpty
              ? '${stats.todayInvoices.length}'
              : null,
          badgeColor: AppColors.primary,
        ),
        const SizedBox(height: 12),
        if (stats.todayInvoices.isEmpty)
          _EmptyCard(
            icon: Icons.receipt_long_outlined,
            message: 'لم يتم تسجيل أي فواتير اليوم',
            color: AppColors.textDisabled,
          )
        else
          _InvoiceList(invoices: stats.todayInvoices, showDebt: false),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reports Button
// ─────────────────────────────────────────────────────────────────────────────

class _ReportsButton extends StatelessWidget {
  const _ReportsButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.analytics_outlined,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سجل التقارير والأرباح',
                    style: GoogleFonts.almarai(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'فترات مخصصة • PDF مشاركة',
                    style: GoogleFonts.almarai(
                        color: Colors.white.withOpacity(0.75), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting Header
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.stats});
  final DashboardStats stats;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'صباح الخير 🌅';
    if (h < 17) return 'مساء النور 🌤';
    return 'مساء الخير 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF083830), Color(0xFF0D4C3F), Color(0xFF1A7060)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF083830).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: GoogleFonts.almarai(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now()),
                  style: GoogleFonts.almarai(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _HeaderStat(
                      label: 'إجمالي الفواتير',
                      value: '${stats.totalInvoicesCount}',
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.white.withOpacity(0.25),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    _HeaderStat(
                      label: 'مبيعات اليوم',
                      value: _fmt(stats.todaySales),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child:
                const Icon(Icons.store_outlined, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.almarai(
            color: Colors.white.withOpacity(0.65),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.almarai(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI Grid
// ─────────────────────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cards = [
      _KpiData(
        title: 'مبيعات اليوم',
        value: _fmt(stats.todaySales),
        icon: Icons.today_rounded,
        color: colorScheme.primary,
        bgColor: colorScheme.primaryContainer.withValues(alpha: 0.8),
        sub: '${stats.todayInvoices.length} فاتورة',
      ),
      _KpiData(
        title: 'مبيعات الشهر',
        value: _fmt(stats.monthSales),
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF0369A1),
        bgColor: const Color(0xFFE0F2FE),
        sub: DateFormat('MMMM', 'ar').format(DateTime.now()),
      ),
      _KpiData(
        title: 'إجمالي الديون',
        value: _fmt(stats.totalDebt),
        icon: Icons.account_balance_wallet_outlined,
        color: colorScheme.error,
        bgColor: colorScheme.errorContainer.withValues(alpha: 0.8),
        sub: stats.totalDebt > 0 ? 'يجب تحصيلها' : 'لا ديون 🎉',
      ),
      _KpiData(
        title: 'فواتير معلّقة',
        value: '${stats.unpaidCount}',
        icon: Icons.pending_actions_outlined,
        color: AppColors.warning,
        bgColor: AppColors.warningSurface,
        sub: stats.unpaidCount > 0 ? 'بحاجة متابعة' : 'مسدّدة ✓',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        double ratio = 1.65;
        if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
          ratio = 2.2;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
          ratio = 2.0;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: ratio,
          ),
          itemCount: cards.length,
          itemBuilder: (_, i) => _KpiCard(data: cards[i]),
        );
      },
    );
  }
}

class _KpiData {
  const _KpiData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.sub,
  });
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String sub;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});
  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? data.color.withOpacity(0.1)
            : data.bgColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: data.color.withOpacity(isDark ? 0.3 : 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Subtle indicator circle
            Positioned(
              top: -20,
              left: -20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: data.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(data.icon, color: data.color, size: 20),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: data.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data.sub,
                          style: GoogleFonts.almarai(
                            fontSize: 10,
                            color: data.color,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    data.value,
                    style: GoogleFonts.almarai(
                      color: isDark ? Colors.white : data.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.title,
                    style: GoogleFonts.almarai(
                      color:
                          isDark ? Colors.white70 : data.color.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Title
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
    this.iconColor,
    this.badge,
    this.badgeColor,
  });
  final String title;
  final IconData icon;
  final Color? iconColor;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.almarai(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (badgeColor ?? AppColors.danger).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badge!,
              style: GoogleFonts.almarai(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeColor ?? AppColors.danger,
              ),
            ),
          ),
        ],
        const Spacer(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invoice List
// ─────────────────────────────────────────────────────────────────────────────

class _InvoiceList extends StatelessWidget {
  const _InvoiceList({required this.invoices, required this.showDebt});
  final List<InvoiceModel> invoices;
  final bool showDebt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: invoices.map((inv) {
        return _InvoiceRow(invoice: inv, showDebt: showDebt);
      }).toList(),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.invoice, required this.showDebt});
  final InvoiceModel invoice;
  final bool showDebt;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    switch (invoice.status) {
      case 'paid':
        statusColor = AppColors.success;
        statusLabel = 'مسدد';
      case 'partial':
        statusColor = AppColors.warning;
        statusLabel = 'جزئي';
      default:
        statusColor = Theme.of(context).colorScheme.error;
        statusLabel = 'دين';
    }

    final colorScheme = Theme.of(context).colorScheme;
    final amountColor = showDebt ? colorScheme.error : colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go('/invoices/details/${invoice.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // ── Status indicator ──
                Container(
                  width: 3.5,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),

                // ── Invoice ID + Customer ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'فاتورة ${invoice.formattedNum}',
                            style: GoogleFonts.almarai(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusLabel,
                              style: GoogleFonts.almarai(
                                  fontSize: 9,
                                  color: statusColor,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 11, color: AppColors.textDisabled),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              invoice.customerName,
                              style: GoogleFonts.almarai(
                                  fontSize: 11, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Amount & Date ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      showDebt ? _fmt(invoice.debt) : _fmt(invoice.grandTotal),
                      style: GoogleFonts.almarai(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _dateFmt.format(invoice.date),
                      style: GoogleFonts.almarai(
                          fontSize: 10,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5)),
                    ),
                  ],
                ),

                const SizedBox(width: 6),
                Icon(Icons.chevron_left,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State Card
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.message,
    required this.color,
  });
  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: color.withOpacity(0.5)),
          const SizedBox(height: 10),
          Text(
            message,
            style: GoogleFonts.almarai(
              color: color.withOpacity(0.75),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error View
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.dangerSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.error_outline,
                  size: 40, color: AppColors.danger),
            ),
            const SizedBox(height: 16),
            Text(
              'تعذّر تحميل البيانات',
              style: GoogleFonts.almarai(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.almarai(
                  fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
