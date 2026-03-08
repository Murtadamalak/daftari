import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/invoice_repository.dart';
import 'app_providers.dart';

class DashboardStats {
  const DashboardStats({
    required this.todaySales,
    required this.monthSales,
    required this.totalDebt,
    required this.unpaidCount,
    required this.unpaidInvoices,
    required this.todayInvoices,
    required this.totalInvoicesCount,
  });

  final double todaySales;
  final double monthSales;
  final double totalDebt;
  final int unpaidCount;
  final List<InvoiceModel> unpaidInvoices;
  final List<InvoiceModel> todayInvoices;
  final int totalInvoicesCount;
}

final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final invoiceRepo = ref.watch(invoiceRepositoryProvider);
  final invoices = await invoiceRepo.getAllInvoices();

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final monthStart = DateTime(now.year, now.month, 1);

  double todaySales = 0;
  double monthSales = 0;
  double totalDebt = 0;
  int unpaidCount = 0;
  final List<InvoiceModel> unpaidInvoices = [];
  final List<InvoiceModel> todayInvoices = [];

  for (final inv in invoices) {
    if (!inv.date.isBefore(todayStart)) {
      todaySales += inv.grandTotal;
      todayInvoices.add(inv);
    }
    if (!inv.date.isBefore(monthStart)) {
      monthSales += inv.grandTotal;
    }
    if (inv.debt > 0) {
      totalDebt += inv.debt;
    }
    if (inv.status == 'unpaid' || inv.status == 'partial') {
      unpaidCount++;
      if (unpaidInvoices.length < 5) {
        unpaidInvoices.add(inv);
      }
    }
  }

  return DashboardStats(
    todaySales: todaySales,
    monthSales: monthSales,
    totalDebt: totalDebt,
    unpaidCount: unpaidCount,
    unpaidInvoices: unpaidInvoices,
    todayInvoices: todayInvoices,
    totalInvoicesCount: invoices.length,
  );
});
