import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/offline_database.dart';
import '../../core/services/connectivity_service.dart';

class ProductModel {
  final String id;
  final String name;
  final String unit;
  final String? barcode;
  final double retailPrice;
  final double? wholesalePrice;
  final double? stock;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.unit,
    this.barcode,
    required this.retailPrice,
    this.wholesalePrice,
    this.stock,
    required this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
        id: j['id'] as String,
        name: j['name'] as String,
        unit: j['unit'] as String? ?? 'قطعة',
        barcode: j['barcode'] as String?,
        retailPrice: (j['retail_price'] as num?)?.toDouble() ?? 0.0,
        wholesalePrice: (j['wholesale_price'] as num?)?.toDouble(),
        stock: (j['stock'] as num?)?.toDouble(),
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  /// تحويل إلى صف للقاعدة المحلية
  Map<String, dynamic> toLocalJson(String userId) => {
        'id': id,
        'user_id': userId,
        'name': name,
        'unit': unit,
        'barcode': barcode,
        'retail_price': retailPrice,
        'wholesale_price': wholesalePrice,
        'stock': stock,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ProductRepository {
  final SupabaseClient _db = Supabase.instance.client;
  final _localDb = OfflineDatabase.instance;

  String get _userId => _db.auth.currentUser!.id;
  bool get _isOnline => ConnectivityService.instance.isOnline;

  Future<List<ProductModel>> getAllProducts() async {
    if (_isOnline) {
      try {
        final res = await _db
            .from('user_products')
            .select()
            .eq('user_id', _userId)
            .order('name');
        final products = res.map((e) => ProductModel.fromJson(e)).toList();

        // تخزين مؤقت محلي
        await _cacheProducts(products);

        return products;
      } catch (e) {
        // فشل الاتصال → نقرأ من الكاش
        return _getFromCache();
      }
    } else {
      return _getFromCache();
    }
  }

  Future<ProductModel?> getById(String id) async {
    if (_isOnline) {
      try {
        final res = await _db
            .from('user_products')
            .select()
            .eq('user_id', _userId)
            .eq('id', id)
            .maybeSingle();
        if (res == null) return null;
        return ProductModel.fromJson(res);
      } catch (_) {
        return _getByIdFromCache(id);
      }
    } else {
      return _getByIdFromCache(id);
    }
  }

  Future<ProductModel?> findByBarcode(String barcode) async {
    if (_isOnline) {
      try {
        final res = await _db
            .from('user_products')
            .select()
            .eq('user_id', _userId)
            .eq('barcode', barcode)
            .maybeSingle();
        if (res == null) return null;
        return ProductModel.fromJson(res);
      } catch (_) {
        // fallback إلى الكاش
        return _findByBarcodeFromCache(barcode);
      }
    } else {
      return _findByBarcodeFromCache(barcode);
    }
  }

  Future<ProductModel> upsertProduct({
    String? id,
    required String name,
    required String unit,
    String? barcode,
    required double retailPrice,
    double? wholesalePrice,
    double? stock,
  }) async {
    // If we are editing an existing product, keep a copy of the old data
    // so we can propagate name/unit changes to all existing invoice items.
    ProductModel? oldProduct;
    if (id != null) {
      try {
        oldProduct = await getById(id);
      } catch (_) {
        oldProduct = null;
      }
    }

    final data = <String, dynamic>{
      'user_id': _userId,
      'name': name,
      'unit': unit,
      'barcode': barcode,
      'retail_price': retailPrice,
      'wholesale_price': wholesalePrice,
      'stock': stock,
    };
    if (id != null) data['id'] = id;

    if (_isOnline) {
      try {
        final res =
            await _db.from('user_products').upsert(data).select().single();
        final updated = ProductModel.fromJson(res);

        // تحديث الكاش
        await _localDb.upsert('products', updated.toLocalJson(_userId));

        // ── Propagate name/unit changes to existing invoice items ──
        if (oldProduct != null &&
            (oldProduct.name != updated.name ||
                oldProduct.unit != updated.unit)) {
          try {
            await _db
                .from('user_invoice_items')
                .update({
                  'product_name': updated.name,
                  'unit': updated.unit,
                })
                .eq('user_id', _userId)
                .eq('product_name', oldProduct.name);
          } catch (_) {
            // نتجاهل أي خطأ هنا حتى لا نفشل حفظ المنتج نفسه
          }
        }

        return updated;
      } catch (_) {
        // فشل → حفظ محلي + pending
        return _upsertOffline(data, id);
      }
    } else {
      return _upsertOffline(data, id);
    }
  }

  Future<void> deleteProduct(String id) async {
    // حذف من الكاش فوراً
    await _localDb.deleteById('products', id);

    if (_isOnline) {
      try {
        await _db
            .from('user_products')
            .delete()
            .eq('user_id', _userId)
            .eq('id', id);
        return;
      } catch (_) {
        // فشل → pending
      }
    }

    await _localDb.addPendingOperation(
      tableName: 'user_products',
      operation: 'delete',
      recordId: id,
      payload: {'id': id},
    );
  }

  /// Bulk decrease stock for multiple products
  Future<void> decreaseStockBulk(
      List<Map<String, dynamic>> productsAndQuantities) async {
    // productsAndQuantities should have 'productId' and 'quantity'
    for (var item in productsAndQuantities) {
      final productId = item['productId'] as String;
      final quantity = item['quantity'] as double;

      if (_isOnline) {
        try {
          final currentRes = await _db
              .from('user_products')
              .select('stock')
              .eq('user_id', _userId)
              .eq('id', productId)
              .maybeSingle();

          if (currentRes != null && currentRes['stock'] != null) {
            final currentStock = (currentRes['stock'] as num).toDouble();
            final newStock =
                currentStock - quantity < 0 ? 0.0 : currentStock - quantity;
            await _db
                .from('user_products')
                .update({'stock': newStock})
                .eq('user_id', _userId)
                .eq('id', productId);

            // تحديث الكاش
            final db = await _localDb.database;
            await db.update(
              'products',
              {'stock': newStock},
              where: 'id = ? AND user_id = ?',
              whereArgs: [productId, _userId],
            );
          }
        } catch (_) {
          // fallback إلى تحديث محلي + pending
          await _decreaseStockOffline(productId, quantity);
        }
      } else {
        await _decreaseStockOffline(productId, quantity);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  عمليات الكاش المحلي
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _cacheProducts(List<ProductModel> products) async {
    await _localDb.clearTable('products', _userId);
    if (products.isNotEmpty) {
      await _localDb.upsertAll(
        'products',
        products.map((p) => p.toLocalJson(_userId)).toList(),
      );
    }
  }

  Future<List<ProductModel>> _getFromCache() async {
    final rows = await _localDb.getAll('products', _userId);
    final products = rows.map((r) => ProductModel.fromJson(r)).toList();
    products.sort((a, b) => a.name.compareTo(b.name));
    return products;
  }

  Future<ProductModel?> _getByIdFromCache(String id) async {
    final row = await _localDb.getById('products', id);
    if (row == null) return null;
    return ProductModel.fromJson(row);
  }

  Future<ProductModel?> _findByBarcodeFromCache(String barcode) async {
    final rows = await _localDb.query(
      'products',
      where: 'user_id = ? AND barcode = ?',
      whereArgs: [_userId, barcode],
    );
    if (rows.isEmpty) return null;
    return ProductModel.fromJson(rows.first);
  }

  Future<ProductModel> _upsertOffline(
      Map<String, dynamic> data, String? id) async {
    final effectiveId = id ?? 'LOCAL-${DateTime.now().millisecondsSinceEpoch}';
    data['id'] = effectiveId;
    data['created_at'] = DateTime.now().toIso8601String();

    final product = ProductModel.fromJson(data);
    await _localDb.upsert('products', product.toLocalJson(_userId));

    await _localDb.addPendingOperation(
      tableName: 'user_products',
      operation: id != null ? 'update' : 'insert',
      recordId: effectiveId,
      payload: data,
    );

    return product;
  }

  Future<void> _decreaseStockOffline(String productId, double quantity) async {
    final db = await _localDb.database;
    final rows = await db.query(
      'products',
      columns: ['stock'],
      where: 'id = ? AND user_id = ?',
      whereArgs: [productId, _userId],
    );

    if (rows.isNotEmpty && rows.first['stock'] != null) {
      final currentStock = (rows.first['stock'] as num).toDouble();
      final newStock =
          currentStock - quantity < 0 ? 0.0 : currentStock - quantity;
      await db.update(
        'products',
        {'stock': newStock},
        where: 'id = ? AND user_id = ?',
        whereArgs: [productId, _userId],
      );

      await _localDb.addPendingOperation(
        tableName: 'user_products',
        operation: 'update',
        recordId: productId,
        payload: {'stock': newStock, 'user_id': _userId},
      );
    }
  }

  Future<void> decreaseStockOfflineByName(String productName, double quantity) async {
    String baseName = productName;
    if (productName.contains(' [') && productName.endsWith(']')) {
      final idx = productName.lastIndexOf(' [');
      baseName = productName.substring(0, idx);
    }

    final db = await _localDb.database;
    final rows = await db.query(
      'products',
      columns: ['id', 'stock'],
      where: 'name = ? AND user_id = ?',
      whereArgs: [baseName, _userId],
    );

    if (rows.isNotEmpty) {
      final productId = rows.first['id'] as String;
      if (rows.first['stock'] != null) {
        final currentStock = (rows.first['stock'] as num).toDouble();
        final newStock =
            currentStock - quantity < 0 ? 0.0 : currentStock - quantity;
        await db.update(
          'products',
          {'stock': newStock},
          where: 'id = ? AND user_id = ?',
          whereArgs: [productId, _userId],
        );

        await _localDb.addPendingOperation(
          tableName: 'user_products',
          operation: 'update',
          recordId: productId,
          payload: {'stock': newStock, 'user_id': _userId},
        );
      }
    }
  }
}
