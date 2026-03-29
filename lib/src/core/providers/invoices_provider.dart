import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/invoice_repository.dart';
import 'app_providers.dart';

// ─── Filter Enums ─────────────────────────────────────────────────────────────

enum InvoiceStatusFilter {
  all,
  paid,
  partial,
  unpaid;

  String get label {
    switch (this) {
      case InvoiceStatusFilter.all:
        return 'الكل';
      case InvoiceStatusFilter.paid:
        return 'مسدد';
      case InvoiceStatusFilter.partial:
        return 'جزئي';
      case InvoiceStatusFilter.unpaid:
        return 'دين';
    }
  }

  String? get dbValue {
    switch (this) {
      case InvoiceStatusFilter.all:
        return null;
      case InvoiceStatusFilter.paid:
        return 'paid';
      case InvoiceStatusFilter.partial:
        return 'partial';
      case InvoiceStatusFilter.unpaid:
        return 'unpaid';
    }
  }
}

// ─── Sort Enums ───────────────────────────────────────────────────────────────

enum InvoiceSortField {
  invoiceNumber,
  customerName,
  amount,
  date;

  String get label {
    switch (this) {
      case InvoiceSortField.invoiceNumber:
        return 'رقم الفاتورة';
      case InvoiceSortField.customerName:
        return 'اسم الزبون';
      case InvoiceSortField.amount:
        return 'المبلغ';
      case InvoiceSortField.date:
        return 'التاريخ';
    }
  }
}

// ─── State Providers ──────────────────────────────────────────────────────────

final invoiceSearchQueryProvider = StateProvider<String>((ref) => '');
final invoiceStatusFilterProvider =
    StateProvider<InvoiceStatusFilter>((ref) => InvoiceStatusFilter.all);
final invoiceSortFieldProvider =
    StateProvider<InvoiceSortField>((ref) => InvoiceSortField.invoiceNumber);
final invoiceSortAscendingProvider = StateProvider<bool>((ref) => false);

// ─── Data Provider ────────────────────────────────────────────────────────────

/// All invoices from Supabase.
final allInvoicesProvider =
    FutureProvider.autoDispose<List<InvoiceModel>>((ref) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getAllInvoices();
});

/// Filtered + sorted invoices.
final filteredInvoicesProvider =
    Provider.autoDispose<AsyncValue<List<InvoiceModel>>>((ref) {
  final invoicesAsync = ref.watch(allInvoicesProvider);
  final query = ref.watch(invoiceSearchQueryProvider).trim().toLowerCase();
  final statusFilter = ref.watch(invoiceStatusFilterProvider);
  final sortField = ref.watch(invoiceSortFieldProvider);
  final ascending = ref.watch(invoiceSortAscendingProvider);

  return invoicesAsync.whenData((invoices) {
    final filtered = invoices.where((inv) {
      final passesStatus = statusFilter == InvoiceStatusFilter.all ||
          inv.status == statusFilter.dbValue;
      final passesSearch = query.isEmpty ||
          inv.id.toLowerCase().contains(query) ||
          inv.customerName.toLowerCase().contains(query);
      return passesStatus && passesSearch;
    }).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (sortField) {
        case InvoiceSortField.invoiceNumber:
          cmp = a.num.compareTo(b.num);
          break;
        case InvoiceSortField.customerName:
          cmp = a.customerName.compareTo(b.customerName);
          break;
        case InvoiceSortField.amount:
          cmp = a.grandTotal.compareTo(b.grandTotal);
          break;
        case InvoiceSortField.date:
          cmp = a.date.compareTo(b.date);
          break;
      }
      return ascending ? cmp : -cmp;
    });

    return filtered;
  });
});
