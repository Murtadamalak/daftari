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

  // ── Accurate Collection-based Sales logic ──────────────────────────────
  // We want to count:
  // 1. Every 'تسديد دين' (Debt Payment) record on the day it occurred.
  // 2. The INITIAL payment of every regular invoice on the day it was created.
  // To get the Initial payment of an old invoice (which might have been updated),
  // we subtract all debt payments linked to it.

  final invoicePmtsSum = <String, double>{};
  for (final inv in invoices) {
    if (inv.payType == 'تسديد دين') {
      if (inv.note != null && inv.note!.startsWith('تسديد دين للفاتورة ')) {
        final origId = inv.note!.replaceAll('تسديد دين للفاتورة ', '');
        invoicePmtsSum[origId] = (invoicePmtsSum[origId] ?? 0) + inv.paid;
      }
    }
  }

  for (final inv in invoices) {
    double cashIn = 0;
    if (inv.payType == 'تسديد دين') {
      cashIn = inv.paid;
    } else {
      // Regular invoice: count the initial pay only.
      // If the invoice was updated in the past (before we stopped updating paid),
      // we subtract those payments to get the original.
      cashIn = inv.paid - (invoicePmtsSum[inv.id] ?? 0);
    }

    if (!inv.date.isBefore(todayStart)) {
      todaySales += cashIn;
      if (inv.payType != 'تسديد دين') todayInvoices.add(inv);
    }
    if (!inv.date.isBefore(monthStart)) {
      monthSales += cashIn;
    }

    // Debt and unpaid counts
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
