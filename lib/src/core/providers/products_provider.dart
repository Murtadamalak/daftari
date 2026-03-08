import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/product_repository.dart';
import 'app_providers.dart';

/// Search query state (by name or barcode).
final productSearchQueryProvider = StateProvider<String>((ref) => '');

/// Async list of all products (Future-based, no stream – Supabase).
final productsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getAllProducts();
});

/// Filtered products based on search query.
final filteredProductsProvider =
    Provider.autoDispose<AsyncValue<List<ProductModel>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final query = ref.watch(productSearchQueryProvider);

  return productsAsync.whenData((products) {
    if (query.isEmpty) return products;
    final lower = query.trim().toLowerCase();
    return products.where((p) {
      final nameMatch = p.name.toLowerCase().contains(lower);
      final barcodeMatch =
          p.barcode != null && p.barcode!.toLowerCase().contains(lower);
      return nameMatch || barcodeMatch;
    }).toList();
  });
});
