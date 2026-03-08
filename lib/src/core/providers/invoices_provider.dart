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

// ─── State Providers ──────────────────────────────────────────────────────────

final invoiceSearchQueryProvider = StateProvider<String>((ref) => '');
final invoiceStatusFilterProvider =
    StateProvider<InvoiceStatusFilter>((ref) => InvoiceStatusFilter.all);

// ─── Data Provider ────────────────────────────────────────────────────────────

/// All invoices from Supabase.
final allInvoicesProvider =
    FutureProvider.autoDispose<List<InvoiceModel>>((ref) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getAllInvoices();
});

/// Filtered invoices applying search + status filter.
final filteredInvoicesProvider =
    Provider.autoDispose<AsyncValue<List<InvoiceModel>>>((ref) {
  final invoicesAsync = ref.watch(allInvoicesProvider);
  final query = ref.watch(invoiceSearchQueryProvider).trim().toLowerCase();
  final statusFilter = ref.watch(invoiceStatusFilterProvider);

  return invoicesAsync.whenData((invoices) {
    return invoices.where((inv) {
      final passesStatus = statusFilter == InvoiceStatusFilter.all ||
          inv.status == statusFilter.dbValue;
      final passesSearch = query.isEmpty ||
          inv.id.toLowerCase().contains(query) ||
          inv.customerName.toLowerCase().contains(query);
      return passesStatus && passesSearch;
    }).toList();
  });
});
