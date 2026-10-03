import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

import '../../data/repositories/product_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/expense_repository.dart';

/// Product repository — stateless, uses Supabase directly.
final productRepositoryProvider =
    Provider.autoDispose<ProductRepository>((ref) {
  ref.watch(authProvider);
  return ProductRepository();
});

/// Customer repository — stateless, uses Supabase directly.
final customerRepositoryProvider =
    Provider.autoDispose<CustomerRepository>((ref) {
  ref.watch(authProvider);
  return CustomerRepository();
});

/// Invoice repository — stateless, uses Supabase directly.
final invoiceRepositoryProvider =
    Provider.autoDispose<InvoiceRepository>((ref) {
  ref.watch(authProvider);
  return InvoiceRepository();
});

/// Expense repository — stateless, uses Supabase + SQLite.
final expenseRepositoryProvider =
    Provider.autoDispose<ExpenseRepository>((ref) {
  ref.watch(authProvider);
  return ExpenseRepository();
});

/// All expenses (refreshable)
final allExpensesProvider = FutureProvider.autoDispose<List<ExpenseModel>>((ref) {
  return ref.watch(expenseRepositoryProvider).getAll();
});

/// Expenses linked to a specific invoice (refreshable)
final invoiceExpensesProvider =
    FutureProvider.family.autoDispose<List<ExpenseModel>, String>((ref, invoiceId) {
  return ref.watch(expenseRepositoryProvider).getByInvoiceId(invoiceId);
});
