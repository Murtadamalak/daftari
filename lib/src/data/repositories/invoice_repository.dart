import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'customer_repository.dart';
import 'product_repository.dart';
import '../local/offline_database.dart';
import '../../core/services/connectivity_service.dart';

class InvoiceItemModel {
  final String id;
  final String invoiceId;
  final String productName;
  final String unit;
  final double qty;
  final double unitPrice;
  final String priceType;
  final double total;
  final String note;

  const InvoiceItemModel({
    required this.id,
    required this.invoiceId,
    required this.productName,
    required this.unit,
    required this.qty,
    required this.unitPrice,
    required this.priceType,
    required this.total,
    required this.note,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> j) {
    final rawName = j['product_name'] as String? ?? '';
    String baseName = rawName;
    String note = j['note'] as String? ?? '';

    if (note.isEmpty && rawName.contains(' [') && rawName.endsWith(']')) {
      final idx = rawName.lastIndexOf(' [');
      baseName = rawName.substring(0, idx);
      note = rawName.substring(idx + 2, rawName.length - 1);
    }

    return InvoiceItemModel(
      id: j['id'] as String? ?? '',
      invoiceId: j['invoice_id'] as String? ?? '',
      productName: baseName,
      unit: j['unit'] as String? ?? 'قطعة',
      qty: (j['qty'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (j['unit_price'] as num?)?.toDouble() ?? 0.0,
      priceType: j['price_type'] as String? ?? 'retail',
      total: (j['total'] as num?)?.toDouble() ?? 0.0,
      note: note,
    );
  }
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
  final _localDb = OfflineDatabase.instance;

  String get _userId => _db.auth.currentUser!.id;
  bool get _isOnline => ConnectivityService.instance.isOnline;

  // ── Read ─────────────────────────────────────────────────────────────────

  Future<List<InvoiceModel>> getAllInvoices() async {
    if (_isOnline) {
      try {
        final res = await _db
            .from('user_invoices')
            .select()
            .eq('user_id', _userId)
            .order('num', ascending: false);
        final invoices = (res as List)
            .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
            .toList();

        // تخزين في الكاش المحلي
        await _cacheInvoices(invoices);

        return invoices;
      } catch (e) {
        // فشل حتى وهو أونلاين → نقرأ من الكاش
        return _getInvoicesFromCache();
      }
    } else {
      return _getInvoicesFromCache();
    }
  }

  Future<List<InvoiceModel>> getUnpaidInvoices() async {
    if (_isOnline) {
      try {
        final res = await _db
            .from('user_invoices')
            .select()
            .eq('user_id', _userId)
            .inFilter('status', ['partial', 'unpaid']).order('date');
        return (res as List)
            .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        final all = await _getInvoicesFromCache();
        return all.where((i) => i.status == 'partial' || i.status == 'unpaid').toList();
      }
    } else {
      final all = await _getInvoicesFromCache();
      return all.where((i) => i.status == 'partial' || i.status == 'unpaid').toList();
    }
  }

  Future<List<InvoiceModel>> getUnpaidByCustomer(String customerId) async {
    if (_isOnline) {
      try {
        final res = await _db
            .from('user_invoices')
            .select()
            .eq('user_id', _userId)
            .eq('customer_id', customerId)
            .inFilter('status', ['partial', 'unpaid']).order('date');
        return (res as List)
            .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        final all = await _getInvoicesFromCache();
        return all.where((i) => i.customerId == customerId && (i.status == 'partial' || i.status == 'unpaid')).toList();
      }
    } else {
      final all = await _getInvoicesFromCache();
      return all.where((i) => i.customerId == customerId && (i.status == 'partial' || i.status == 'unpaid')).toList();
    }
  }

  Future<InvoiceModel?> getById(String id) async {
    if (_isOnline) {
      try {
        final res = await _db
            .from('user_invoices')
            .select()
            .eq('user_id', _userId)
            .eq('id', id)
            .maybeSingle();
        if (res == null) return null;
        return InvoiceModel.fromJson(res);
      } catch (_) {
        return _getInvoiceByIdFromCache(id);
      }
    } else {
      return _getInvoiceByIdFromCache(id);
    }
  }

  Future<List<InvoiceItemModel>> getItemsByInvoiceId(String invoiceId) async {
    if (_isOnline) {
      try {
        final res = await _db
            .from('user_invoice_items')
            .select()
            .eq('invoice_id', invoiceId)
            .eq('user_id', _userId);
        return (res as List)
            .map((e) => InvoiceItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return _getItemsFromCache(invoiceId);
      }
    } else {
      return _getItemsFromCache(invoiceId);
    }
  }

  /// جميع الفواتير المبيعات لزبون محدد (بدون إدخالات التسديد)
  Future<List<InvoiceModel>> getInvoicesByCustomer(String customerId) async {
    if (_isOnline) {
      try {
        final res = await _db
            .from('user_invoices')
            .select()
            .eq('user_id', _userId)
            .eq('customer_id', customerId)
            .neq('pay_type', 'تسديد دين')
            .order('date', ascending: false);
        return (res as List)
            .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        final all = await _getInvoicesFromCache();
        return all.where((i) => i.customerId == customerId && i.payType != 'تسديد دين').toList();
      }
    } else {
      final all = await _getInvoicesFromCache();
      return all.where((i) => i.customerId == customerId && i.payType != 'تسديد دين').toList();
    }
  }

  /// دفعات التسديد والمدفوعات لزبون محدد
  Future<List<InvoiceModel>> getPaymentsByCustomer(String customerId) async {
    if (_isOnline) {
      try {
        final res = await _db
            .from('user_invoices')
            .select()
            .eq('user_id', _userId)
            .eq('customer_id', customerId)
            .gt('paid', 0)
            .order('date', ascending: false);
        return (res as List)
            .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        final all = await _getInvoicesFromCache();
        return all.where((i) => i.customerId == customerId && i.paid > 0).toList();
      }
    } else {
      final all = await _getInvoicesFromCache();
      return all.where((i) => i.customerId == customerId && i.paid > 0).toList();
    }
  }

  /// سجلات تسديد الدين فقط لزبون محدد (pay_type = 'تسديد دين')
  Future<List<InvoiceModel>> getPaymentRecordsByCustomer(String customerId) async {
    if (_isOnline) {
      try {
        final res = await _db
            .from('user_invoices')
            .select()
            .eq('user_id', _userId)
            .eq('customer_id', customerId)
            .eq('pay_type', 'تسديد دين')
            .order('date', ascending: true);
        return (res as List)
            .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        final all = await _getInvoicesFromCache();
        return all.where((i) => i.customerId == customerId && i.payType == 'تسديد دين').toList();
      }
    } else {
      final all = await _getInvoicesFromCache();
      return all.where((i) => i.customerId == customerId && i.payType == 'تسديد دين').toList();
    }
  }

  /// إعادة احتساب ديون العميل بالكامل وتحديث حالة الفواتير
  Future<void> recalculateCustomerDebt(String customerId) async {
    // 1. تشغيل الحساب المحلي وتحديث قاعدة البيانات المحلية فوراً
    await _recalculateCustomerDebtLocal(customerId);

    if (_isOnline) {
      try {
        // 2. جلب جميع فواتير المبيعات للعميل سحابياً
        final invoicesRes = await _db
            .from('user_invoices')
            .select()
            .eq('user_id', _userId)
            .eq('customer_id', customerId)
            .neq('pay_type', 'تسديد دين')
            .order('date', ascending: true);
            
        final salesInvoices = (invoicesRes as List)
            .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
            .toList();

        // 3. جلب جميع سجلات الدفع للعميل سحابياً
        final paymentsRes = await _db
            .from('user_invoices')
            .select()
            .eq('user_id', _userId)
            .eq('customer_id', customerId)
            .eq('pay_type', 'تسديد دين')
            .order('date', ascending: true);

        final payments = (paymentsRes as List)
            .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
            .toList();

        // حساب إجمالي الدفعات
        double totalPayments = payments.fold(0.0, (sum, p) => sum + p.paid);

        double newTotalDebt = 0.0;

        // مراجعة الفواتير من الأقدم للأحدث لتسوية الديون
        for (final inv in salesInvoices) {
          final initialPaid = inv.paid;
          final initialDebt = inv.grandTotal - initialPaid;

          if (initialDebt <= 0.0001) {
            if (inv.debt.abs() > 0.0001 || inv.status != 'paid') {
              await _db
                  .from('user_invoices')
                  .update({'debt': 0, 'status': 'paid'})
                  .eq('id', inv.id)
                  .eq('user_id', _userId);
            }
            continue;
          }

          double currentInvDebt = initialDebt;
          String currentStatus = 'unpaid';

          if (totalPayments >= currentInvDebt) {
            totalPayments -= currentInvDebt;
            currentInvDebt = 0;
            currentStatus = 'paid';
          } else if (totalPayments > 0) {
            currentInvDebt -= totalPayments;
            totalPayments = 0;
            currentStatus = 'partial';
          } else {
            currentInvDebt = initialDebt;
            currentStatus = initialPaid > 0.0001 ? 'partial' : 'unpaid';
          }

          newTotalDebt += currentInvDebt;

          if ((inv.debt - currentInvDebt).abs() > 0.0001 || inv.status != currentStatus) {
            await _db
                .from('user_invoices')
                .update({
                  'debt': currentInvDebt,
                  'status': currentStatus,
                })
                .eq('id', inv.id)
                .eq('user_id', _userId);
          }
        }

        // 4. تحديث إجمالي دين العميل سحابياً
        final custRepo = CustomerRepository();
        await custRepo.updateDebt(customerId, newTotalDebt);
      } catch (_) {
        // نكتفي بالتحديث المحلي إذا حدث خطأ في الاتصال
      }
    }
  }


  Future<List<InvoiceModel>> getByDateRange(
      DateTime start, DateTime end) async {
    if (_isOnline) {
      try {
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
      } catch (_) {
        final all = await _getInvoicesFromCache();
        return all.where((i) => !i.date.isBefore(start) && !i.date.isAfter(end)).toList();
      }
    } else {
      final all = await _getInvoicesFromCache();
      return all.where((i) => !i.date.isBefore(start) && !i.date.isAfter(end)).toList();
    }
  }

  Future<List<InvoiceItemModel>> getItemsByInvoiceIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    if (_isOnline) {
      try {
        final res = await _db
            .from('user_invoice_items')
            .select()
            .eq('user_id', _userId)
            .inFilter('invoice_id', ids);
        return (res as List)
            .map((e) => InvoiceItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        final List<InvoiceItemModel> result = [];
        for (final id in ids) {
          result.addAll(await _getItemsFromCache(id));
        }
        return result;
      }
    } else {
      final List<InvoiceItemModel> result = [];
      for (final id in ids) {
        result.addAll(await _getItemsFromCache(id));
      }
      return result;
    }
  }

  // ── Next Invoice Number ───────────────────────────────────────────────────

  Future<int> _nextInvoiceNumber() async {
    if (_isOnline) {
      try {
        final res = await _db
            .from('user_invoices')
            .select('num')
            .eq('user_id', _userId)
            .order('num', ascending: false)
            .limit(1)
            .maybeSingle();
        if (res == null) return 1;
        return (res['num'] as int) + 1;
      } catch (_) {
        return _nextInvoiceNumberLocal();
      }
    } else {
      return _nextInvoiceNumberLocal();
    }
  }

  Future<int> _nextInvoiceNumberLocal() async {
    final db = await _localDb.database;
    final res = await db.rawQuery(
      'SELECT num FROM invoices WHERE user_id = ? ORDER BY num DESC LIMIT 1',
      [_userId],
    );
    if (res.isEmpty) return 1;
    return (res.first['num'] as int) + 1;
  }

  // ── Renumber Invoices ───────────────────────────────────────────────────

  /// إعادة ترقيم جميع الفواتير والمقبوضات بالتسلسل من 1 حسب تاريخ الإنشاء.
  /// تستخدم لمعالجة الفجوات في الأرقام الناتجة عن الحذف.
  Future<void> renumberAllInvoices() async {
    // 1. جلب معرفات وأرقام جميع السجلات مرتبة حسب التاريخ تصاعدياً محلياً
    final db = await _localDb.database;
    final localRows = await db.query(
      'invoices',
      columns: ['id', 'num'],
      where: 'user_id = ?',
      orderBy: 'date ASC',
    );

    if (localRows.isEmpty) return;

    // 2. تحديث الأرقام محلياً مع إزاحة لمنع التعارض
    const offset = 1000000;
    for (final inv in localRows) {
      final id = inv['id'] as String;
      final currentNum = inv['num'] as int;
      await db.update(
        'invoices',
        {'num': currentNum + offset},
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, _userId],
      );
    }

    for (int i = 0; i < localRows.length; i++) {
      final id = localRows[i]['id'] as String;
      final newNum = i + 1;
      await db.update(
        'invoices',
        {'num': newNum},
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, _userId],
      );

      // إضافة عملية معلقة للتحديث السحابي
      await _localDb.addPendingOperation(
        tableName: 'user_invoices',
        operation: 'update',
        recordId: id,
        payload: {'num': newNum, 'user_id': _userId},
      );
    }

    if (_isOnline) {
      try {
        final res = await _db
            .from('user_invoices')
            .select('id, num')
            .eq('user_id', _userId)
            .order('date', ascending: true);

        final invoices =
            (res as List).map((e) => e as Map<String, dynamic>).toList();
        if (invoices.isEmpty) return;

        for (final inv in invoices) {
          final id = inv['id'] as String;
          final currentNum = inv['num'] as int;
          await _db
              .from('user_invoices')
              .update({'num': currentNum + offset})
              .eq('id', id)
              .eq('user_id', _userId);
        }

        for (int i = 0; i < invoices.length; i++) {
          final id = invoices[i]['id'] as String;
          await _db
              .from('user_invoices')
              .update({'num': i + 1})
              .eq('id', id)
              .eq('user_id', _userId);
        }
      } catch (_) {
        // نكتفي بالتحديث المحلي والعملية المعلقة
      }
    }
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

    // تجهيز الفاتورة محلياً
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

    final insertedItems = <InvoiceItemModel>[];
    final itemsToInsert = <Map<String, dynamic>>[];

    for (final item in items) {
      final itemId = item['id'] as String? ?? const Uuid().v4();
      final String rawName = item['product_name'] as String? ?? '';
      String baseName = rawName;
      // Use note field directly if provided, otherwise extract from product_name (backward compat)
      String note = item['note'] as String? ?? '';
      if (note.isEmpty && rawName.contains(' [') && rawName.endsWith(']')) {
        final idx = rawName.lastIndexOf(' [');
        baseName = rawName.substring(0, idx);
        note = rawName.substring(idx + 2, rawName.length - 1);
      }
      final localItem = {
        'id': itemId,
        'invoice_id': id,
        'user_id': _userId,
        'product_name': baseName.isNotEmpty ? baseName : rawName,
        'unit': item['unit'] as String? ?? 'قطعة',
        'qty': (item['qty'] as num?)?.toDouble() ?? 1.0,
        'unit_price': (item['unit_price'] as num?)?.toDouble() ?? 0.0,
        'price_type': item['price_type'] as String? ?? 'retail',
        'total': (item['total'] as num?)?.toDouble() ?? 0.0,
        'note': note,
      };
      itemsToInsert.add(localItem);
      insertedItems.add(InvoiceItemModel.fromJson(localItem));
    }

    final invoice = InvoiceModel.fromJson(invData);

    // 1. الحفظ محلياً
    await _localDb.upsert('invoices', invData);
    for (final localItem in itemsToInsert) {
      await _localDb.upsert('invoice_items', localItem);
    }

    // 2. تحديث المخزون محلياً
    if (payType != 'تسديد دين' && itemsToInsert.isNotEmpty) {
      final productRepo = ProductRepository();
      for (final item in itemsToInsert) {
        await productRepo.decreaseStockOfflineByName(
            item['product_name'] as String, item['qty'] as double);
      }
    }

    // 3. محاولة الرفع السحابي أو التسجيل في pending_operations
    if (_isOnline) {
      try {
        await _db.from('user_invoices').insert(invData);
        for (final localItem in itemsToInsert) {
          await _db.from('user_invoice_items').insert(localItem);
        }
        if (customerId != null) {
          await recalculateCustomerDebt(customerId);
        }
      } catch (_) {
        await _queueInvoiceOffline(id, invData, itemsToInsert, customerId);
      }
    } else {
      await _queueInvoiceOffline(id, invData, itemsToInsert, customerId);
    }

    return (invoice, insertedItems);
  }

  Future<void> _queueInvoiceOffline(
    String id,
    Map<String, dynamic> invData,
    List<Map<String, dynamic>> items,
    String? customerId,
  ) async {
    await _localDb.addPendingOperation(
      tableName: 'user_invoices',
      operation: 'insert',
      recordId: id,
      payload: invData,
    );
    for (final item in items) {
      await _localDb.addPendingOperation(
        tableName: 'user_invoice_items',
        operation: 'insert',
        recordId: item['id'] as String,
        payload: item,
      );
    }
    if (customerId != null) {
      await _recalculateCustomerDebtLocal(customerId);
    }
  }

  // ── Delete Invoice ────────────────────────────────────────────────────────

  Future<void> deleteInvoice(String id) async {
    final inv = await getById(id);
    if (inv == null) return;

    final items = await getItemsByInvoiceId(id);

    // 1. استعادة المخزون محلياً
    if (inv.payType != 'تسديد دين' && items.isNotEmpty) {
      final db = await _localDb.database;
      for (final item in items) {
        final prodRows = await db.query('products',
            where: 'name = ? AND user_id = ?',
            whereArgs: [item.productName, _userId]);
        if (prodRows.isNotEmpty) {
          final p = prodRows.first;
          final currentStock = (p['stock'] as num?)?.toDouble() ?? 0.0;
          final newStock = currentStock + item.qty;
          await db.update('products', {'stock': newStock},
              where: 'id = ?', whereArgs: [p['id']]);

          await _localDb.addPendingOperation(
            tableName: 'user_products',
            operation: 'update',
            recordId: p['id'] as String,
            payload: {'stock': newStock, 'user_id': _userId},
          );
        }
      }
    }

    // 2. الحذف محلياً
    await _localDb.deleteInvoiceItems(id, _userId);
    await _localDb.deleteById('invoices', id);

    // 3. إعادة حساب الديون محلياً
    if (inv.customerId != null) {
      await _recalculateCustomerDebtLocal(inv.customerId!);
    }

    // 4. الحذف من السحابة أو pending
    if (_isOnline) {
      try {
        await _db
            .from('user_invoice_items')
            .delete()
            .eq('user_id', _userId)
            .eq('invoice_id', id);

        await _db
            .from('user_invoices')
            .delete()
            .eq('user_id', _userId)
            .eq('id', id);

        if (inv.customerId != null) {
          await recalculateCustomerDebt(inv.customerId!);
        }
      } catch (_) {
        await _queueDeleteOffline(id, inv.customerId);
      }
    } else {
      await _queueDeleteOffline(id, inv.customerId);
    }
  }

  Future<void> _queueDeleteOffline(String id, String? customerId) async {
    await _localDb.addPendingOperation(
      tableName: 'user_invoice_items',
      operation: 'delete_where',
      recordId: id,
      payload: {'invoice_id': id, 'user_id': _userId},
    );
    await _localDb.addPendingOperation(
      tableName: 'user_invoices',
      operation: 'delete',
      recordId: id,
      payload: {'id': id},
    );
  }

  // ── Pay Invoice Debt ──────────────────────────────────────────────────────

  Future<void> payInvoiceDebt({
    required String invoiceId,
    required double amountPaid,
  }) async {
    final inv = await getById(invoiceId);
    if (inv == null) throw StateError('Invoice not found');

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

    if (inv.customerId != null) {
      await recalculateCustomerDebt(inv.customerId!);
    }
  }

  // ── Pay Customer Total Debt ───────────────────────────────────────────────

  Future<void> payCustomerDebt({
    required String customerId,
    required double amountPaid,
  }) async {
    final custRepo = CustomerRepository();
    final cust = await custRepo.getById(customerId);
    if (cust == null) throw StateError('Customer not found');

    final unpaid = await getUnpaidByCustomer(customerId);
    String? shopName;
    String? shopPhone;
    String? ownerName;
    String? shopLogoPath;
    if (unpaid.isNotEmpty) {
      final inv = unpaid.first;
      shopName = inv.shopName;
      shopPhone = inv.shopPhone;
      ownerName = inv.ownerName;
      shopLogoPath = inv.shopLogoPath;
    }

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

    await recalculateCustomerDebt(customerId);
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

    final recData = {
      'id': pId,
      'user_id': _userId,
      'num': receiptNum,
      'date': DateTime.now().toIso8601String(),
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'subtotal': amount,
      'grand_total': amount,
      'discount': 0.0,
      'paid': amount,
      'debt': 0.0,
      'pay_type': 'تسديد دين',
      'note': note,
      'status': 'paid',
      'shop_name': shopName,
      'shop_phone': shopPhone,
      'owner_name': ownerName,
      'shop_logo_path': shopLogoPath,
    };

    // 1. حفظ محلي
    await _localDb.upsert('invoices', recData);

    // 2. تحديث الديون محلياً
    if (customerId != null) {
      await _recalculateCustomerDebtLocal(customerId);
    }

    // 3. رفع سحابي أو pending
    if (_isOnline) {
      try {
        await _db.from('user_invoices').insert(recData);
      } catch (_) {
        await _localDb.addPendingOperation(
          tableName: 'user_invoices',
          operation: 'insert',
          recordId: pId,
          payload: recData,
        );
      }
    } else {
      await _localDb.addPendingOperation(
        tableName: 'user_invoices',
        operation: 'insert',
        recordId: pId,
        payload: recData,
      );
    }
  }

  // ── Update Cash Invoice With Items ────────────────────────────────────────

  Future<void> updateCashInvoiceWithItems({
    required InvoiceModel original,
    required List<InvoiceItemModel> originalItems,
    String? customerId,
    required String customerName,
    String? customerPhone,
    required double subtotal,
    required double discount,
    required double grandTotal,
    required double paid,
    required double debt,
    required String status,
    required String payType,
    required List<Map<String, dynamic>> items,
  }) async {
    if (original.payType == 'تسديد دين') {
      throw StateError('Editing payment-only invoices is not supported');
    }

    // 1) حساب فروقات الكمية لتعديل المخزون
    final Map<String, double> oldQtyByName = {};
    for (final it in originalItems) {
      oldQtyByName.update(it.productName, (v) => v + it.qty,
          ifAbsent: () => it.qty);
    }

    final Map<String, double> newQtyByName = {};
    for (final it in items) {
      final name = it['product_name'] as String? ?? '';
      final qty = (it['qty'] as num?)?.toDouble() ?? 0.0;
      if (name.isEmpty || qty == 0) continue;
      newQtyByName.update(name, (v) => v + qty, ifAbsent: () => qty);
    }

    final Map<String, double> deltaByName = {};
    final allNames = {...oldQtyByName.keys, ...newQtyByName.keys};
    for (final name in allNames) {
      final oldQty = oldQtyByName[name] ?? 0;
      final newQty = newQtyByName[name] ?? 0;
      final diff = newQty - oldQty;
      if (diff.abs() > 0.0001) {
        deltaByName[name] = diff;
      }
    }

    // 2) ضبط المخزون محلياً
    if (deltaByName.isNotEmpty) {
      final db = await _localDb.database;
      for (final entry in deltaByName.entries) {
        final name = entry.key;
        final diff = entry.value;

        final prodRows = await db.query('products',
            where: 'name = ? AND user_id = ?',
            whereArgs: [name, _userId]);
        if (prodRows.isNotEmpty) {
          final p = prodRows.first;
          final currentStock = (p['stock'] as num?)?.toDouble() ?? 0.0;
          final newStock = currentStock - diff;
          await db.update(
            'products',
            {'stock': newStock < 0 ? 0 : newStock},
            where: 'id = ?',
            whereArgs: [p['id']],
          );

          await _localDb.addPendingOperation(
            tableName: 'user_products',
            operation: 'update',
            recordId: p['id'] as String,
            payload: {
              'stock': newStock < 0 ? 0 : newStock,
              'user_id': _userId
            },
          );
        }
      }
    }

    // 3) تحديث الفاتورة محلياً وحذف البنود القديمة وإدخال الجديدة
    final invData = {
      'id': original.id,
      'user_id': _userId,
      'num': original.num,
      'date': original.date.toIso8601String(),
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'subtotal': subtotal,
      'discount': discount,
      'grand_total': grandTotal,
      'paid': paid,
      'debt': debt,
      'status': status,
      'pay_type': payType,
      'shop_name': original.shopName,
      'shop_phone': original.shopPhone,
      'owner_name': original.ownerName,
      'shop_logo_path': original.shopLogoPath,
    };

    await _localDb.upsert('invoices', invData);
    await _localDb.deleteInvoiceItems(original.id, _userId);

    final itemsToInsert = <Map<String, dynamic>>[];
    for (final item in items) {
      final itemId = item['id'] as String? ?? const Uuid().v4();
      final String rawName = item['product_name'] as String? ?? '';
      String baseName = rawName;
      // Use note field directly if provided, otherwise extract from product_name (backward compat)
      String note = item['note'] as String? ?? '';
      if (note.isEmpty && rawName.contains(' [') && rawName.endsWith(']')) {
        final idx = rawName.lastIndexOf(' [');
        baseName = rawName.substring(0, idx);
        note = rawName.substring(idx + 2, rawName.length - 1);
      }
      final localItem = {
        'id': itemId,
        'invoice_id': original.id,
        'user_id': _userId,
        'product_name': baseName.isNotEmpty ? baseName : rawName,
        'unit': item['unit'] as String? ?? 'قطعة',
        'qty': (item['qty'] as num?)?.toDouble() ?? 1.0,
        'unit_price': (item['unit_price'] as num?)?.toDouble() ?? 0.0,
        'price_type': item['price_type'] as String? ?? 'retail',
        'total': (item['total'] as num?)?.toDouble() ?? 0.0,
        'note': note,
      };
      itemsToInsert.add(localItem);
      await _localDb.upsert('invoice_items', localItem);
    }

    // 4) إعادة احتساب الديون محلياً
    if (original.customerId != null) {
      await _recalculateCustomerDebtLocal(original.customerId!);
    }
    if (customerId != null && customerId != original.customerId) {
      await _recalculateCustomerDebtLocal(customerId);
    }

    // 5) الرفع السحابي أو pending
    if (_isOnline) {
      try {
        await _db
            .from('user_invoices')
            .update({
              'customer_id': customerId,
              'customer_name': customerName,
              'customer_phone': customerPhone,
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

        await _db
            .from('user_invoice_items')
            .delete()
            .eq('user_id', _userId)
            .eq('invoice_id', original.id);

        for (final localItem in itemsToInsert) {
          await _db.from('user_invoice_items').insert(localItem);
        }

        if (original.customerId != null) {
          await recalculateCustomerDebt(original.customerId!);
        }
        if (customerId != null && customerId != original.customerId) {
          await recalculateCustomerDebt(customerId);
        }
      } catch (_) {
        await _queueUpdateOffline(original.id, invData, itemsToInsert, original.customerId, customerId);
      }
    } else {
      await _queueUpdateOffline(original.id, invData, itemsToInsert, original.customerId, customerId);
    }
  }

  Future<void> _queueUpdateOffline(
    String id,
    Map<String, dynamic> invData,
    List<Map<String, dynamic>> items,
    String? oldCustomerId,
    String? newCustomerId,
  ) async {
    await _localDb.addPendingOperation(
      tableName: 'user_invoices',
      operation: 'update',
      recordId: id,
      payload: invData,
    );
    await _localDb.addPendingOperation(
      tableName: 'user_invoice_items',
      operation: 'delete_where',
      recordId: id,
      payload: {'invoice_id': id, 'user_id': _userId},
    );
    for (final item in items) {
      await _localDb.addPendingOperation(
        tableName: 'user_invoice_items',
        operation: 'insert',
        recordId: item['id'] as String,
        payload: item,
      );
    }
  }

  // ── Recalculate Customer Debt Local ──

  Future<void> _recalculateCustomerDebtLocal(String customerId) async {
    final db = await _localDb.database;
    final invoicesRes = await db.query(
      'invoices',
      where: 'user_id = ? AND customer_id = ? AND pay_type != ?',
      whereArgs: [_userId, customerId, 'تسديد دين'],
      orderBy: 'date ASC',
    );
    final salesInvoices = invoicesRes
        .map((e) => InvoiceModel.fromJson({
              ...e,
              'grand_total': e['grand_total'] ?? 0.0,
            }))
        .toList();

    final paymentsRes = await db.query(
      'invoices',
      where: 'user_id = ? AND customer_id = ? AND pay_type = ?',
      whereArgs: [_userId, customerId, 'تسديد دين'],
      orderBy: 'date ASC',
    );
    final payments = paymentsRes
        .map((e) => InvoiceModel.fromJson({
              ...e,
              'grand_total': e['grand_total'] ?? 0.0,
            }))
        .toList();

    double totalPayments = payments.fold(0.0, (sum, p) => sum + p.paid);
    double newTotalDebt = 0.0;

    for (final inv in salesInvoices) {
      final initialPaid = inv.paid;
      final initialDebt = inv.grandTotal - initialPaid;

      if (initialDebt <= 0.0001) {
        if (inv.debt.abs() > 0.0001 || inv.status != 'paid') {
          await db.update(
            'invoices',
            {'debt': 0.0, 'status': 'paid'},
            where: 'id = ? AND user_id = ?',
            whereArgs: [inv.id, _userId],
          );
        }
        continue;
      }

      double currentInvDebt = initialDebt;
      String currentStatus = 'unpaid';

      if (totalPayments >= currentInvDebt) {
        totalPayments -= currentInvDebt;
        currentInvDebt = 0.0;
        currentStatus = 'paid';
      } else if (totalPayments > 0) {
        currentInvDebt -= totalPayments;
        totalPayments = 0.0;
        currentStatus = 'partial';
      } else {
        currentInvDebt = initialDebt;
        currentStatus = initialPaid > 0.0001 ? 'partial' : 'unpaid';
      }

      newTotalDebt += currentInvDebt;

      if ((inv.debt - currentInvDebt).abs() > 0.0001 ||
          inv.status != currentStatus) {
        await db.update(
          'invoices',
          {'debt': currentInvDebt, 'status': currentStatus},
          where: 'id = ? AND user_id = ?',
          whereArgs: [inv.id, _userId],
        );
      }
    }

    await db.update(
      'customers',
      {'total_debt': newTotalDebt},
      where: 'id = ? AND user_id = ?',
      whereArgs: [customerId, _userId],
    );
  }


  // ═══════════════════════════════════════════════════════════════════════════
  //  عمليات الكاش المحلي (للقراءة بدون إنترنت)
  // ═══════════════════════════════════════════════════════════════════════════

  /// تخزين جميع الفواتير في الكاش المحلي
  Future<void> _cacheInvoices(List<InvoiceModel> invoices) async {
    await _localDb.clearTable('invoices', _userId);
    if (invoices.isNotEmpty) {
      await _localDb.upsertAll(
        'invoices',
        invoices
            .map((inv) => {
                  'id': inv.id,
                  'user_id': _userId,
                  'num': inv.num,
                  'date': inv.date.toIso8601String(),
                  'customer_id': inv.customerId,
                  'customer_name': inv.customerName,
                  'customer_phone': inv.customerPhone,
                  'subtotal': inv.subtotal,
                  'discount': inv.discount,
                  'grand_total': inv.grandTotal,
                  'paid': inv.paid,
                  'debt': inv.debt,
                  'pay_type': inv.payType,
                  'note': inv.note,
                  'status': inv.status,
                  'shop_name': inv.shopName,
                  'shop_phone': inv.shopPhone,
                  'owner_name': inv.ownerName,
                  'shop_logo_path': inv.shopLogoPath,
                })
            .toList(),
      );
    }
  }

  /// جلب جميع الفواتير من الكاش المحلي
  Future<List<InvoiceModel>> _getInvoicesFromCache() async {
    final rows = await _localDb.getAll('invoices', _userId);
    final invoices = rows.map((r) {
      // نتأكد من أن الحقول المطلوبة موجودة بالشكل الصحيح
      return InvoiceModel.fromJson({
        ...r,
        'grand_total': r['grand_total'] ?? 0,
      });
    }).toList();
    // ترتيب حسب رقم الفاتورة تنازلياً
    invoices.sort((a, b) => b.num.compareTo(a.num));
    return invoices;
  }

  /// جلب فاتورة واحدة من الكاش المحلي بمعرفها
  Future<InvoiceModel?> _getInvoiceByIdFromCache(String id) async {
    final row = await _localDb.getById('invoices', id);
    if (row == null) return null;
    return InvoiceModel.fromJson({
      ...row,
      'grand_total': row['grand_total'] ?? 0,
    });
  }

  /// جلب بنود فاتورة من الكاش المحلي
  Future<List<InvoiceItemModel>> _getItemsFromCache(String invoiceId) async {
    final rows = await _localDb.getInvoiceItems(invoiceId, _userId);
    return rows.map((r) => InvoiceItemModel.fromJson(r)).toList();
  }
}
