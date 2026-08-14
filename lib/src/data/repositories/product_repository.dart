import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        unit: j['unit']?.toString() ?? 'قطعة',
        barcode: j['barcode']?.toString(),
        retailPrice: (j['retail_price'] as num?)?.toDouble() ?? 0.0,
        wholesalePrice: (j['wholesale_price'] as num?)?.toDouble(),
        stock: (j['stock'] as num?)?.toDouble(),
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'barcode': barcode,
        'retail_price': retailPrice,
        'wholesale_price': wholesalePrice,
        'stock': stock,
        'created_at': createdAt.toIso8601String(),
      };

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

  String get _userId => _db.auth.currentUser?.id ?? '';
  bool get _isOnline => ConnectivityService.instance.isOnline;

  Future<List<ProductModel>> getAllProducts() async {
    if (_userId.isEmpty) {
      return _getFromCache();
    }

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
        debugPrint('[ProductRepo] Error fetching products: $e');
        return _getFromCache();
      }
    } else {
      return _getFromCache();
    }
  }

  Future<ProductModel?> getById(String id) async {
    if (_userId.isEmpty) {
      return _getByIdFromCache(id);
    }

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
    if (_userId.isEmpty) {
      return _findByBarcodeFromCache(barcode);
    }

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
    if (id != null && id.isNotEmpty) {
      return updateProduct(
        id: id,
        name: name,
        unit: unit,
        barcode: barcode,
        retailPrice: retailPrice,
        wholesalePrice: wholesalePrice,
        stock: stock,
      );
    } else {
      return createProduct(
        name: name,
        unit: unit,
        barcode: barcode,
        retailPrice: retailPrice,
        wholesalePrice: wholesalePrice,
        stock: stock,
      );
    }
  }

  Future<ProductModel> createProduct({
    required String name,
    required String unit,
    String? barcode,
    required double retailPrice,
    double? wholesalePrice,
    double? stock,
  }) async {
    final payload = {
      'user_id': _userId,
      'name': name,
      'unit': unit,
      'barcode': barcode,
      'retail_price': retailPrice,
      'wholesale_price': wholesalePrice,
      'stock': stock,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (_isOnline && _userId.isNotEmpty) {
      try {
        final res = await _db
            .from('user_products')
            .insert(payload)
            .select()
            .single();
        final product = ProductModel.fromJson(res);
        if (!kIsWeb) {
          await _localDb.upsert('products', product.toLocalJson(_userId));
        }
        return product;
      } catch (e) {
        return _upsertOffline(payload, null);
      }
    } else {
      return _upsertOffline(payload, null);
    }
  }

  Future<ProductModel> updateProduct({
    required String id,
    required String name,
    required String unit,
    String? barcode,
    required double retailPrice,
    double? wholesalePrice,
    double? stock,
  }) async {
    final payload = {
      'name': name,
      'unit': unit,
      'barcode': barcode,
      'retail_price': retailPrice,
      'wholesale_price': wholesalePrice,
      'stock': stock,
    };

    if (_isOnline && _userId.isNotEmpty) {
      try {
        final res = await _db
            .from('user_products')
            .update(payload)
            .eq('id', id)
            .eq('user_id', _userId)
            .select()
            .single();
        final product = ProductModel.fromJson(res);
        if (!kIsWeb) {
          await _localDb.upsert('products', product.toLocalJson(_userId));
        }
        return product;
      } catch (_) {
        return _upsertOffline({'id': id, ...payload}, id);
      }
    } else {
      return _upsertOffline({'id': id, ...payload}, id);
    }
  }

  Future<void> deleteProduct(String id) async {
    if (_isOnline && _userId.isNotEmpty) {
      try {
        await _db
            .from('user_products')
            .delete()
            .eq('id', id)
            .eq('user_id', _userId);
      } catch (_) {
        if (!kIsWeb) {
          await _localDb.deleteById('products', id);
          await _localDb.addPendingOperation(
            tableName: 'user_products',
            operation: 'delete',
            recordId: id,
            payload: {'id': id, 'user_id': _userId},
          );
        }
      }
    } else {
      if (!kIsWeb) {
        await _localDb.deleteById('products', id);
        await _localDb.addPendingOperation(
          tableName: 'user_products',
          operation: 'delete',
          recordId: id,
          payload: {'id': id, 'user_id': _userId},
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  عمليات الكاش المحلي
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _cacheProducts(List<ProductModel> products) async {
    if (_userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = products.map((p) => p.toJson()).toList();
      await prefs.setString('cached_products_$_userId', jsonEncode(jsonList));
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await _localDb.clearTable('products', _userId);
        if (products.isNotEmpty) {
          await _localDb.upsertAll(
            'products',
            products.map((p) => p.toLocalJson(_userId)).toList(),
          );
        }
      } catch (_) {}
    }
  }

  Future<List<ProductModel>> _getFromCache() async {
    if (_userId.isEmpty) return [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cached_products_$_userId');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        final list = decoded
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
        list.sort((a, b) => a.name.compareTo(b.name));
        return list;
      }
    } catch (_) {}

    if (!kIsWeb) {
      try {
        final rows = await _localDb.getAll('products', _userId);
        final products = rows.map((r) => ProductModel.fromJson(r)).toList();
        products.sort((a, b) => a.name.compareTo(b.name));
        return products;
      } catch (_) {}
    }

    return [];
  }

  Future<ProductModel?> _getByIdFromCache(String id) async {
    final all = await _getFromCache();
    final match = all.where((p) => p.id == id);
    return match.isNotEmpty ? match.first : null;
  }

  Future<ProductModel?> _findByBarcodeFromCache(String barcode) async {
    final all = await _getFromCache();
    final match = all.where((p) => p.barcode == barcode);
    return match.isNotEmpty ? match.first : null;
  }

  /// Bulk decrease stock for multiple products
  Future<void> decreaseStockBulk(
      List<Map<String, dynamic>> productsAndQuantities) async {
    for (var item in productsAndQuantities) {
      final productId = item['productId'] as String;
      final quantity = item['quantity'] as double;

      if (_isOnline && _userId.isNotEmpty) {
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

            if (!kIsWeb) {
              final db = await _localDb.database;
              await db.update(
                'products',
                {'stock': newStock},
                where: 'id = ? AND user_id = ?',
                whereArgs: [productId, _userId],
              );
            }
          }
        } catch (_) {
          if (!kIsWeb) {
            await _decreaseStockOffline(productId, quantity);
          }
        }
      } else {
        if (!kIsWeb) {
          await _decreaseStockOffline(productId, quantity);
        }
      }
    }
  }

  Future<ProductModel> _upsertOffline(
      Map<String, dynamic> data, String? id) async {
    final effectiveId = id ?? const Uuid().v4();
    data['id'] = effectiveId;
    data['created_at'] = DateTime.now().toIso8601String();

    final product = ProductModel.fromJson(data);
    if (!kIsWeb) {
      await _localDb.upsert('products', product.toLocalJson(_userId));
      await _localDb.addPendingOperation(
        tableName: 'user_products',
        operation: id != null ? 'update' : 'insert',
        recordId: effectiveId,
        payload: data,
      );
    }

    return product;
  }

  Future<void> _decreaseStockOffline(String productId, double quantity) async {
    if (kIsWeb) return;
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
    if (kIsWeb) return;
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
