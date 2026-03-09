import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/invoice_repository.dart';
import 'app_providers.dart';

class ComprehensiveReportData {
  const ComprehensiveReportData({
    required this.dateRange,
    required this.invoices,
    required this.items,
    required this.totalSales,
    required this.totalPaid,
    required this.totalDebt,
    required this.totalDiscount,
    required this.itemQuantities,
  });

  final DateTimeRange dateRange;
  final List<InvoiceModel> invoices;
  final List<InvoiceItemModel> items;
  final double totalSales;
  final double totalPaid;
  final double totalDebt;
  final double totalDiscount;
  final List<MapEntry<String, double>> itemQuantities;
}

class ComprehensiveReportNotifier
    extends StateNotifier<AsyncValue<ComprehensiveReportData>> {
  ComprehensiveReportNotifier(this._ref) : super(const AsyncValue.loading()) {
    _initDefault();
  }

  final Ref _ref;
  late DateTimeRange _currentRange;
  String _currentPreset = 'اليوم';

  DateTimeRange get currentRange => _currentRange;
  String get currentPreset => _currentPreset;

  void _initDefault() {
    final now = DateTime.now();
    _currentRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
    loadData();
  }

  void setDateRange(DateTimeRange range, {String predefined = 'تحديد مخصص'}) {
    _currentPreset = predefined;
    _currentRange = DateTimeRange(
      start: DateTime(range.start.year, range.start.month, range.start.day),
      end: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
    );
    loadData();
  }

  void setPreset(String preset) {
    final now = DateTime.now();
    DateTime start;
    final DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (preset == 'اليوم') {
      start = DateTime(now.year, now.month, now.day);
    } else if (preset == 'هذا الأسبوع') {
      final diff = now.weekday % 7;
      start =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: diff));
    } else if (preset == 'هذا الشهر') {
      start = DateTime(now.year, now.month, 1);
    } else {
      return;
    }
    setDateRange(DateTimeRange(start: start, end: end), predefined: preset);
  }

  Future<void> loadData() async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(invoiceRepositoryProvider);
      final allInvoices = await repo.getAllInvoices();
      final invoicesInSelectedRange = allInvoices.where((inv) {
        return !inv.date.isBefore(_currentRange.start) &&
            !inv.date.isAfter(_currentRange.end);
      }).toList();

      final invoiceIdsInSelectedRange =
          invoicesInSelectedRange.map((e) => e.id).toList();
      final items = await repo.getItemsByInvoiceIds(invoiceIdsInSelectedRange);

      double sales = 0;
      double paid = 0;
      double debtValue = 0;
      double discount = 0;

      // 1. Build a global map of all debt payments for ANY invoice
      final invoicePmtsSum = <String, double>{};
      for (final inv in allInvoices) {
        if (inv.payType == 'تسديد دين') {
          if (inv.note != null && inv.note!.startsWith('تسديد دين للفاتورة ')) {
            final origId = inv.note!.replaceAll('تسديد دين للفاتورة ', '');
            invoicePmtsSum[origId] = (invoicePmtsSum[origId] ?? 0) + inv.paid;
          }
        }
      }

      // 2. Sum up for the selected range
      for (final inv in invoicesInSelectedRange) {
        double cashIn = 0;
        if (inv.payType == 'تسديد دين') {
          cashIn = inv.paid;
        } else {
          // Regular invoice: count the initial pay only.
          // Correctly handle updated 'paid' values from old transactions.
          cashIn = inv.paid - (invoicePmtsSum[inv.id] ?? 0);
        }

        sales += cashIn;
        paid += cashIn;
        debtValue += inv.debt;
        discount += inv.discount;
      }

      final map = <String, double>{};
      for (final it in items) {
        final key = '${it.productName} (${it.unit})';
        map[key] = (map[key] ?? 0) + it.qty;
      }

      final itemQuantities = map.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      state = AsyncValue.data(ComprehensiveReportData(
        dateRange: _currentRange,
        invoices: invoicesInSelectedRange,
        items: items,
        totalSales: sales,
        totalPaid: paid,
        totalDebt: debtValue,
        totalDiscount: discount,
        itemQuantities: itemQuantities,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final comprehensiveReportProvider = StateNotifierProvider.autoDispose<
    ComprehensiveReportNotifier, AsyncValue<ComprehensiveReportData>>((ref) {
  ref.watch(invoiceRepositoryProvider);
  return ComprehensiveReportNotifier(ref);
});
