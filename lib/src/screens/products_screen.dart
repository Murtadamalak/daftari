import 'dart:ui' show ImageFilter;
import 'package:daftar_debt_manager/src/core/widgets/app_bar_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/providers/app_providers.dart';
import '../core/providers/products_provider.dart';
import '../core/widgets/soft_card.dart';
import '../data/repositories/product_repository.dart';
import '../core/widgets/refresh_action_button.dart';
import '../core/theme/app_theme.dart';

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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const AppBarLogo(),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF0A1612)
                      : const Color(0xFFF7F5F0))
                  .withOpacity(0.4),
            ),
          ),
        ),
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
              onPressed: () => ref.invalidate(productsProvider),
            ),
          ),
          productsAsync.when(
            data: (list) => Padding(
              padding: const EdgeInsets.only(left: 8, right: 4),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppColors.primary)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${list.length} منتج',
                    style: TextStyle(
                        fontFamily: 'KOMedia',
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0A1612), const Color(0xFF13211D)]
                : [const Color(0xFFF7F5F0), const Color(0xFFEEEBE1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // ── Search Card ──
            Container(
              margin: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + kToolbarHeight - 8,
                16,
                12,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101D1A) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (isDark ? const Color(0xFF1E3C36) : const Color(0xFFD0DCDA))
                      .withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, _) {
                  return TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        ref.read(productSearchQueryProvider.notifier).state = v,
                    style: TextStyle(
                      fontFamily: 'KOMedia',
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0A221F),
                    ),
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو الباركود...',
                      hintStyle: TextStyle(
                        fontFamily: 'KOMedia',
                        fontSize: 13,
                        color: isDark ? const Color(0xFF85AFA7).withOpacity(0.6) : const Color(0xFF9CA3AF),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? const Color(0xFF85AFA7) : const Color(0xFF9CA3AF),
                      ),
                      suffixIcon: value.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: isDark ? const Color(0xFF85AFA7) : const Color(0xFF9CA3AF),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(productSearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF162A26) : const Color(0xFFF4F6F5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  );
                },
              ),
            ),
            // ── Main Content ──
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('حدث خطأ: $err')),
                data: (products) {
                  if (products.isEmpty) {
                    return _EmptyProductsState(hasSearch: searchQuery.isNotEmpty);
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
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
    ),
  ],
),
      ),
      floatingActionButtonLocation: AppTheme.customCenterFloat,
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

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  static final _fmt = NumberFormat('#,###');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

          // ── Actions ──
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
                onPressed: () => _confirmDeleteProduct(context, ref, product),
                tooltip: 'حذف',
              ),
              Icon(Icons.chevron_left,
                  color: theme.colorScheme.outline, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteProduct(
      BuildContext context, WidgetRef ref, ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: Text('هل أنت متأكد من حذف المنتج "${product.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(productRepositoryProvider).deleteProduct(product.id);
      ref.invalidate(productsProvider);
    }
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
