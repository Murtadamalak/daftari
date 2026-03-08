import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

import '../../data/repositories/product_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/invoice_repository.dart';

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
