import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'customer_repository.dart';
import 'product_repository.dart';

class InvoiceItemModel {
  final String id;
  final String invoiceId;
  final String productName;
  final String unit;
  final double qty;
  final double unitPrice;
  final String priceType;
  final double total;

  const InvoiceItemModel({
    required this.id,
    required this.invoiceId,
    required this.productName,
    required this.unit,
    required this.qty,
    required this.unitPrice,
    required this.priceType,
    required this.total,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> j) => InvoiceItemModel(
        id: j['id'] as String,
        invoiceId: j['invoice_id'] as String,
        productName: j['product_name'] as String,
        unit: j['unit'] as String? ?? 'قطعة',
        qty: (j['qty'] as num?)?.toDouble() ?? 1.0,
        unitPrice: (j['unit_price'] as num?)?.toDouble() ?? 0.0,
        priceType: j['price_type'] as String? ?? 'retail',
        total: (j['total'] as num?)?.toDouble() ?? 0.0,
      );
}

class InvoiceModel {
  final String id;
  final int num;
  final DateTime date;
  final String? customerId;
  final String customerName;
  final String? customerPhone;
  final double subtotal;
  final double discount;
  final double grandTotal;
  final double paid;
  final double debt;
  final String payType;
  final String? note;
  final String status;
  final String shopName;
  final String? shopPhone;
  final String? ownerName;
  final String? shopLogoPath;

  const InvoiceModel({
    required this.id,
    required this.num,
    required this.date,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
    required this.paid,
    required this.debt,
    required this.payType,
    this.note,
    required this.status,
    required this.shopName,
    this.shopPhone,
    this.ownerName,
    this.shopLogoPath,
  });

  String get formattedNum {
    final prefix = id.length >= 4 ? id.substring(0, 4).toUpperCase() : 'INV';
    final nStr = num.toString().padLeft(4, '0');
    return '$prefix-$nStr';
  }

  /// The true total paid to date for this invoice (calculated from debt)
  double get currentPaid => grandTotal - debt;

  factory InvoiceModel.fromJson(Map<String, dynamic> j) {
    double toDouble(String key) {
      final v = j[key];
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    final rawNum = j['num'];
    return InvoiceModel(
      id: j['id'] as String,
      num:
          rawNum is int ? rawNum : int.tryParse(rawNum?.toString() ?? '0') ?? 0,
      date: DateTime.parse(j['date'] as String),
      customerId: j['customer_id'] as String?,
      customerName: j['customer_name'] as String,
      customerPhone: j['customer_phone'] as String?,
      subtotal: toDouble('subtotal'),
      discount: toDouble('discount'),
      grandTotal: toDouble('grand_total'),
      paid: toDouble('paid'),
      debt: toDouble('debt'),
      payType: j['pay_type'] as String? ?? 'cash',
      note: j['note'] as String?,
      status: j['status'] as String? ?? 'paid',
      shopName: j['shop_name'] as String? ?? '',
      shopPhone: j['shop_phone'] as String?,
      ownerName: j['owner_name'] as String?,
      shopLogoPath: j['shop_logo_path'] as String?,
    );
  }
}

class InvoiceRepository {
  final SupabaseClient _db = Supabase.instance.client;

  String get _userId => _db.auth.currentUser!.id;

  // ── Read ─────────────────────────────────────────────────────────────────

  Future<List<InvoiceModel>> getAllInvoices() async {
    final res = await _db
        .from('user_invoices')
        .select()
        .eq('user_id', _userId)
        .order('num', ascending: false);
    return (res as List)
        .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<InvoiceModel>> getUnpaidInvoices() async {
    final res = await _db
        .from('user_invoices')
        .select()
        .eq('user_id', _userId)
        .inFilter('status', ['partial', 'unpaid']).order('date');
    return (res as List)
        .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<InvoiceModel>> getUnpaidByCustomer(String customerId) async {
    final res = await _db
        .from('user_invoices')
        .select()
        .eq('user_id', _userId)
        .eq('customer_id', customerId)
        .inFilter('status', ['partial', 'unpaid']).order('date');
    return (res as List)
        .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InvoiceModel?> getById(String id) async {
    final res = await _db
        .from('user_invoices')
        .select()
        .eq('user_id', _userId)
        .eq('id', id)
        .maybeSingle();
    if (res == null) return null;
    return InvoiceModel.fromJson(res);
  }

  Future<List<InvoiceItemModel>> getItemsByInvoiceId(String invoiceId) async {
    final res = await _db
        .from('user_invoice_items')
        .select()
        .eq('invoice_id', invoiceId)
        .eq('user_id', _userId);
    return (res as List)
        .map((e) => InvoiceItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<InvoiceModel>> getByDateRange(
      DateTime start, DateTime end) async {
    final res = await _db
        .from('user_invoices')
        .select()
        .eq('user_id', _userId)
        .gte('date', start.toIso8601String())
        .lte('date', end.toIso8601String())
        .order('date', ascending: false);
    return (res as List)
        .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<InvoiceItemModel>> getItemsByInvoiceIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final res = await _db
        .from('user_invoice_items')
        .select()
        .eq('user_id', _userId)
        .inFilter('invoice_id', ids);
    return (res as List)
        .map((e) => InvoiceItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Next Invoice Number ───────────────────────────────────────────────────

  Future<int> _nextInvoiceNumber() async {
    final res = await _db
        .from('user_invoices')
        .select('num')
        .eq('user_id', _userId)
        .order('num', ascending: false)
        .limit(1)
        .maybeSingle();
    if (res == null) return 1;
    return (res['num'] as int) + 1;
  }

  // ── Create Invoice ────────────────────────────────────────────────────────

  Future<(InvoiceModel, List<InvoiceItemModel>)> createInvoice({
    required String customerName,
    String? customerId,
    String? customerPhone,
    required double subtotal,
    required double discount,
    required double grandTotal,
    required double paid,
    required double debt,
    required String payType,
    String? note,
    required String status,
    required String shopName,
    String? shopPhone,
    String? ownerName,
    String? shopLogoPath,
    required List<Map<String, dynamic>> items,
    double? additionalDebt,
  }) async {
    final invoiceNum = await _nextInvoiceNumber();
    final id = const Uuid().v4();

    // Insert invoice
    final invData = {
      'id': id,
      'user_id': _userId,
      'num': invoiceNum,
      'date': DateTime.now().toIso8601String(),
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'subtotal': subtotal,
      'discount': discount,
      'grand_total': grandTotal,
      'paid': paid,
      'debt': debt,
      'pay_type': payType,
      'note': note,
      'status': status,
      'shop_name': shopName,
      'shop_phone': shopPhone,
      'owner_name': ownerName,
      'shop_logo_path': shopLogoPath,
    };
    final insertedInv =
        await _db.from('user_invoices').insert(invData).select().single();
    final invoice = InvoiceModel.fromJson(insertedInv);

    // Insert items
    final insertedItems = <InvoiceItemModel>[];
    for (final item in items) {
      item['invoice_id'] = id;
      item['user_id'] = _userId;
      final insertedItem =
          await _db.from('user_invoice_items').insert(item).select().single();
      insertedItems.add(InvoiceItemModel.fromJson(insertedItem));
    }

    // Update customer debt if needed
    if (customerId != null && additionalDebt != null && additionalDebt > 0) {
      final custRepo = CustomerRepository();
      final cust = await custRepo.getById(customerId);
      if (cust != null) {
        await custRepo.updateDebt(customerId, cust.totalDebt + additionalDebt);
      }
    }

    return (invoice, insertedItems);
  }

  // ── Delete Invoice ────────────────────────────────────────────────────────

  Future<void> deleteInvoice(String id) async {
    await _db
        .from('user_invoices')
        .delete()
        .eq('user_id', _userId)
        .eq('id', id);
  }

  // ── Pay Invoice Debt ──────────────────────────────────────────────────────

  Future<void> payInvoiceDebt({
    required String invoiceId,
    required double amountPaid,
  }) async {
    final inv = await getById(invoiceId);
    if (inv == null) throw StateError('Invoice not found');

    final newDebt = inv.debt - amountPaid;
    final newStatus = newDebt <= 0.01 ? 'paid' : 'partial';

    await _db
        .from('user_invoices')
        .update({
          'debt': newDebt < 0 ? 0 : newDebt,
          'status': newStatus,
        })
        .eq('id', invoiceId)
        .eq('user_id', _userId);

    if (inv.customerId != null) {
      final custRepo = CustomerRepository();
      final cust = await custRepo.getById(inv.customerId!);
      if (cust != null) {
        await custRepo.updateDebt(inv.customerId!, cust.totalDebt - amountPaid);
      }
    }

    // Create receipt entry
    await _createReceiptRecord(
      inv.customerName,
      inv.customerId,
      inv.customerPhone,
      amountPaid,
      'تسديد دين للفاتورة ${inv.id}',
      inv.shopName,
      inv.shopPhone,
      inv.ownerName,
      inv.shopLogoPath,
    );
  }

  // ── Pay Customer Total Debt ───────────────────────────────────────────────

  Future<void> payCustomerDebt({
    required String customerId,
    required double amountPaid,
  }) async {
    final custRepo = CustomerRepository();
    final cust = await custRepo.getById(customerId);
    if (cust == null) throw StateError('Customer not found');

    // 1. Reduce customer total debt
    await custRepo.updateDebt(customerId, cust.totalDebt - amountPaid);

    // 2. Apply to unpaid invoices oldest first
    final unpaid = await getUnpaidByCustomer(customerId);
    double remaining = amountPaid;
    String? shopName;
    String? shopPhone;
    String? ownerName;
    String? shopLogoPath;

    for (var inv in unpaid) {
      if (remaining <= 0) break;
      shopName ??= inv.shopName;
      shopPhone ??= inv.shopPhone;
      ownerName ??= inv.ownerName;
      shopLogoPath ??= inv.shopLogoPath;
      final apply = remaining >= inv.debt ? inv.debt : remaining;
      final newDebt = inv.debt - apply;
      final newStatus = newDebt <= 0.01 ? 'paid' : 'partial';
      await _db
          .from('user_invoices')
          .update({
            'debt': newDebt < 0 ? 0 : newDebt,
            'status': newStatus,
          })
          .eq('id', inv.id)
          .eq('user_id', _userId);
      remaining -= apply;
    }

    // 3. Create receipt record
    await _createReceiptRecord(
      cust.name,
      customerId,
      cust.phone,
      amountPaid,
      'دفعة تسديد من الدين الكلي',
      shopName ?? 'مبيعات المحل',
      shopPhone,
      ownerName,
      shopLogoPath,
    );
  }

  // ── Internal: Create Receipt Record ──────────────────────────────────────

  Future<void> _createReceiptRecord(
    String customerName,
    String? customerId,
    String? customerPhone,
    double amount,
    String note,
    String shopName,
    String? shopPhone,
    String? ownerName,
    String? shopLogoPath,
  ) async {
    final receiptNum = await _nextInvoiceNumber();
    final pId = 'REC-${DateTime.now().millisecondsSinceEpoch}';
    await _db.from('user_invoices').insert({
      'id': pId,
      'user_id': _userId,
      'num': receiptNum,
      'date': DateTime.now().toIso8601String(),
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'subtotal': amount,
      'grand_total': amount,
      'discount': 0,
      'paid': amount,
      'debt': 0,
      'pay_type': 'تسديد دين',
      'note': note,
      'status': 'paid',
      'shop_name': shopName,
      'shop_phone': shopPhone,
      'owner_name': ownerName,
      'shop_logo_path': shopLogoPath,
    });
  }

  /// تحديث فاتورة قائمة (مبيعات) مع إعادة توليد البنود وضبط المخزون والديون.
  ///
  /// تُستخدم عند فتح الفاتورة في وضع التعديل من التطبيق. تعتمد على مقارنة
  /// البنود القديمة بالجديدة لتحديث المخزون بناءً على فرق الكميات لكل منتج،
  /// ثم تحديث مبلغ الدين للزبون حسب الفرق بين الدين القديم والجديد.
  ///
  /// ملاحظة: لا يُستخدم هذا التابع مع فواتير "تسديد دين" (pay_type = 'تسديد دين').
  Future<void> updateCashInvoiceWithItems({
    required InvoiceModel original,
    required List<InvoiceItemModel> originalItems,
    required double subtotal,
    required double discount,
    required double grandTotal,
    required double paid,
    required double debt,
    required String status,
    required String payType,
    required List<Map<String, dynamic>> items,
  }) async {
    // لا نسمح بتعديل فواتير التسديد، فهي ليست مبيعات.
    if (original.payType == 'تسديد دين') {
      throw StateError('Editing payment-only invoices is not supported');
    }

    // 1) احسب فروقات الكمية لكل منتج بالاسم بين البنود القديمة والجديدة
    final Map<String, double> oldQtyByName = {};
    for (final it in originalItems) {
      oldQtyByName.update(
        it.productName,
        (v) => v + it.qty,
        ifAbsent: () => it.qty,
      );
    }

    final Map<String, double> newQtyByName = {};
    for (final it in items) {
      final name = it['product_name'] as String? ?? '';
      final qty = (it['qty'] as num?)?.toDouble() ?? 0.0;
      if (name.isEmpty || qty == 0) continue;
      newQtyByName.update(
        name,
        (v) => v + qty,
        ifAbsent: () => qty,
      );
    }

    final Map<String, double> deltaByName = {};
    final allNames = <String>{
      ...oldQtyByName.keys,
      ...newQtyByName.keys,
    };
    for (final name in allNames) {
      final oldQty = oldQtyByName[name] ?? 0;
      final newQty = newQtyByName[name] ?? 0;
      final diff = newQty - oldQty; // + يعني بيع أكثر، - يعني تقليل بيع
      if (diff.abs() > 0.0001) {
        deltaByName[name] = diff;
      }
    }

    final client = Supabase.instance.client;

    // 2) ضبط المخزون بناءً على الفروقات المحسوبة
    if (deltaByName.isNotEmpty) {
      final productRepo = ProductRepository();
      final allProducts = await productRepo.getAllProducts();

      for (final entry in deltaByName.entries) {
        final name = entry.key;
        final diff = entry.value;

        final product = allProducts
            .where((p) => p.name == name)
            .cast<ProductModel?>()
            .firstWhere((p) => p != null, orElse: () => null);

        if (product != null && product.stock != null) {
          final currentStock = product.stock!;
          final newStock = currentStock - diff;
          await client
              .from('user_products')
              .update({
                'stock': newStock < 0 ? 0 : newStock,
              })
              .eq('user_id', _userId)
              .eq('id', product.id);
        }
      }
    }

    // 3) تحديث سجل الفاتورة نفسه
    await client
        .from('user_invoices')
        .update({
          'subtotal': subtotal,
          'discount': discount,
          'grand_total': grandTotal,
          'paid': paid,
          'debt': debt,
          'status': status,
          'pay_type': payType,
        })
        .eq('user_id', _userId)
        .eq('id', original.id);

    // 4) تحديث دين الزبون إن وجد
    if (original.customerId != null && (debt - original.debt).abs() > 0.0001) {
      final custRepo = CustomerRepository();
      final cust = await custRepo.getById(original.customerId!);
      if (cust != null) {
        final newTotalDebt = cust.totalDebt + (debt - original.debt);
        await custRepo.updateDebt(original.customerId!, newTotalDebt);
      }
    }

    // 5) حذف البنود القديمة ثم إدخال البنود الجديدة
    await client
        .from('user_invoice_items')
        .delete()
        .eq('user_id', _userId)
        .eq('invoice_id', original.id);

    for (final item in items) {
      final data = {
        ...item,
        'invoice_id': original.id,
        'user_id': _userId,
      };
      await client.from('user_invoice_items').insert(data);
    }
  }
}
