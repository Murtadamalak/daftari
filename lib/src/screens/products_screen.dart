import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/providers/products_provider.dart';
import '../core/widgets/soft_card.dart';
import '../data/repositories/product_repository.dart';
import '../core/widgets/refresh_action_button.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(filteredProductsProvider);
    final searchQuery = ref.watch(productSearchQueryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتجات'),
        actions: [
          RefreshActionButton(
            onPressed: () => ref.invalidate(productsProvider),
          ),
          productsAsync.when(
            data: (list) => Padding(
              padding: const EdgeInsets.only(left: 8, right: 4),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${list.length} منتج',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) {
                return TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      ref.read(productSearchQueryProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم أو الباركود...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(productSearchQueryProvider.notifier)
                                  .state = '';
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('حدث خطأ: $err')),
        data: (products) {
          if (products.isEmpty) {
            return _EmptyProductsState(hasSearch: searchQuery.isNotEmpty);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ProductCard(
                  product: products[index],
                  onTap: () async {
                    await context.push('/products/edit/${products[index].id}');
                    if (context.mounted) ref.invalidate(productsProvider);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/products/add');
          if (context.mounted) ref.invalidate(productsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('منتج جديد'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  static final _fmt = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLowStock =
        product.stock != null && product.stock! < 5 && product.stock! >= 0;
    final isOutOfStock = product.stock != null && product.stock! <= 0;

    return SoftCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          // ── Icon ──
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // ── Info ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Retail price
                    Text(
                      '${_fmt.format(product.retailPrice)} IQD',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if (product.wholesalePrice != null) ...[
                      Text(
                        ' • جملة: ${_fmt.format(product.wholesalePrice!)} IQD',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
                if (product.stock != null) ...[
                  const SizedBox(height: 4),
                  _StockBadge(
                    stock: product.stock!,
                    unit: product.unit,
                    isOutOfStock: isOutOfStock,
                    isLow: hasLowStock,
                  ),
                ],
              ],
            ),
          ),

          // ── Chevron ──
          Icon(Icons.chevron_left, color: theme.colorScheme.outline, size: 20),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({
    required this.stock,
    required this.unit,
    required this.isOutOfStock,
    required this.isLow,
  });
  final double stock;
  final String unit;
  final bool isOutOfStock;
  final bool isLow;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String text;
    if (isOutOfStock) {
      color = const Color(0xFFEF4444);
      text = 'نفد المخزون';
    } else if (isLow) {
      color = const Color(0xFFF59E0B);
      text =
          'مخزون منخفض: ${stock.toStringAsFixed(stock == stock.truncate() ? 0 : 1)} $unit';
    } else {
      color = const Color(0xFF22C55E);
      text =
          'المخزون: ${stock.toStringAsFixed(stock == stock.truncate() ? 0 : 1)} $unit';
    }

    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(text,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState({required this.hasSearch});
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearch ? Icons.search_off_rounded : Icons.inventory_2_outlined,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'لا توجد نتائج' : 'لا توجد منتجات بعد',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'جرّب كلمة بحث مختلفة'
                  : 'اضغط على الزر + لإضافة أول منتج',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
