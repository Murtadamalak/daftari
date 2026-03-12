import 'package:supabase_flutter/supabase_flutter.dart';

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

  String get _userId => _db.auth.currentUser!.id;

  Future<List<ProductModel>> getAllProducts() async {
    final res = await _db
        .from('user_products')
        .select()
        .eq('user_id', _userId)
        .order('name');
    return res.map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<ProductModel?> getById(String id) async {
    final res = await _db
        .from('user_products')
        .select()
        .eq('user_id', _userId)
        .eq('id', id)
        .maybeSingle();
    if (res == null) return null;
    return ProductModel.fromJson(res);
  }

  Future<ProductModel?> findByBarcode(String barcode) async {
    final res = await _db
        .from('user_products')
        .select()
        .eq('user_id', _userId)
        .eq('barcode', barcode)
        .maybeSingle();
    if (res == null) return null;
    return ProductModel.fromJson(res);
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

    final res = await _db.from('user_products').upsert(data).select().single();
    final updated = ProductModel.fromJson(res);

    // ── Propagate name/unit changes to existing invoice items ───────────────
    // Many الشاشات (التقارير، تفاصيل الفاتورة) تعتمد على حقل product_name
    // المخزون داخل جدول user_invoice_items. حتى تظهر التسمية الجديدة في كل
    // مكان، نحدّث كل البنود القديمة التي كانت تستخدم الاسم السابق.
    if (oldProduct != null &&
        (oldProduct.name != updated.name || oldProduct.unit != updated.unit)) {
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
  }

  Future<void> deleteProduct(String id) async {
    await _db
        .from('user_products')
        .delete()
        .eq('user_id', _userId)
        .eq('id', id);
  }

  /// Bulk decrease stock for multiple products
  Future<void> decreaseStockBulk(
      List<Map<String, dynamic>> productsAndQuantities) async {
    // productsAndQuantities should have 'productId' and 'quantity'
    for (var item in productsAndQuantities) {
      final productId = item['productId'] as String;
      final quantity = item['quantity'] as double;

      // Call supabase RPC instead to ensure atomicity, or we fetch and update individually.
      // Easiest is to fetch and update since user has their own row
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
      }
    }
  }
}
