import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/offline_database.dart';
import '../../core/services/connectivity_service.dart';

/// Simple model — mirrors Supabase row in user_customers
class CustomerModel {
  final String id;
  final String name;
  final String? phone;
  final double totalDebt;
  final DateTime createdAt;

  const CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    required this.totalDebt,
    required this.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> j) => CustomerModel(
        id: j['id'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String?,
        totalDebt: (j['total_debt'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  Map<String, dynamic> toInsertJson(String userId) => {
        'user_id': userId,
        'name': name,
        'phone': phone,
        'total_debt': totalDebt,
      };

  /// تحويل إلى صف للقاعدة المحلية
  Map<String, dynamic> toLocalJson(String userId) => {
        'id': id,
        'user_id': userId,
        'name': name,
        'phone': phone,
        'total_debt': totalDebt,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class CustomerRepository {
  final SupabaseClient _db = Supabase.instance.client;
  final _localDb = OfflineDatabase.instance;

  String get _userId => _db.auth.currentUser!.id;
  bool get _isOnline => ConnectivityService.instance.isOnline;

  Future<List<CustomerModel>> getAllCustomers() async {
    if (_isOnline) {
      try {
        final res = await _db
            .from('user_customers')
            .select()
            .eq('user_id', _userId)
            .order('created_at', ascending: false);
        final customers = res.map((e) => CustomerModel.fromJson(e)).toList();

        // حفظ في الكاش المحلي
        await _cacheCustomers(customers);

        return customers;
      } catch (e) {
        // إذا فشل حتى وهو أونلاين (timeout مثلاً) → نقرأ من الكاش
        return _getFromCache();
      }
    } else {
      return _getFromCache();
    }
  }

  Future<List<CustomerModel>> getCustomersWithDebt() async {
    if (_isOnline) {
      try {
        final res = await _db
            .from('user_customers')
            .select()
            .eq('user_id', _userId)
            .gt('total_debt', 0)
            .order('name');
        return res.map((e) => CustomerModel.fromJson(e)).toList();
      } catch (_) {
        // fallback إلى الكاش مع فلتر الديون
        final all = await _getFromCache();
        return all.where((c) => c.totalDebt > 0).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
      }
    } else {
      final all = await _getFromCache();
      return all.where((c) => c.totalDebt > 0).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    }
  }

  Future<CustomerModel?> getById(String id) async {
    if (_isOnline) {
      try {
        final res = await _db
            .from('user_customers')
            .select()
            .eq('user_id', _userId)
            .eq('id', id)
            .maybeSingle();
        if (res == null) return null;
        return CustomerModel.fromJson(res);
      } catch (_) {
        return _getByIdFromCache(id);
      }
    } else {
      return _getByIdFromCache(id);
    }
  }

  Future<CustomerModel> upsertCustomer({
    String? id,
    required String name,
    String? phone,
    double totalDebt = 0,
  }) async {
    // عند التعديل نحتاج لاحقاً لتحديث جميع الفواتير المرتبطة بنفس الزبون
    // حتى ينعكس الاسم/الهاتف الجديد في كل مكان (التفاصيل، التقارير، PDF...).
    final data = <String, dynamic>{
      'user_id': _userId,
      'name': name,
      'phone': phone,
      'total_debt': totalDebt,
    };
    if (id != null) data['id'] = id;

    if (_isOnline) {
      try {
        final res =
            await _db.from('user_customers').upsert(data).select().single();
        final customer = CustomerModel.fromJson(res);

        // تحديث الكاش المحلي
        await _localDb.upsert('customers', customer.toLocalJson(_userId));

        // ── Propagate name/phone changes to all invoices of this customer ──
        if (id != null) {
          try {
            await _db
                .from('user_invoices')
                .update({
                  'customer_name': name,
                  'customer_phone': phone,
                })
                .eq('user_id', _userId)
                .eq('customer_id', id);
          } catch (_) {
            // لو فشل التحديث على الفواتير لا نمنع حفظ الزبون نفسه
          }
        }

        return customer;
      } catch (_) {
        // أونلاين لكن فشل → نحفظ محلياً + pending
        return _upsertOffline(data, id);
      }
    } else {
      return _upsertOffline(data, id);
    }
  }

  Future<void> deleteCustomer(String id) async {
    // حذف من الكاش المحلي فوراً
    await _localDb.deleteById('customers', id);

    if (_isOnline) {
      try {
        await _db
            .from('user_customers')
            .delete()
            .eq('user_id', _userId)
            .eq('id', id);
        return;
      } catch (_) {
        // فشل الحذف من السحابة → نضيف pending
      }
    }

    // حفظ عملية الحذف كمعلقة
    await _localDb.addPendingOperation(
      tableName: 'user_customers',
      operation: 'delete',
      recordId: id,
      payload: {'id': id},
    );
  }

  Future<void> updateDebt(String customerId, double newDebt) async {
    final debt = newDebt < 0 ? 0.0 : newDebt;

    // تحديث محلي فوري
    final db = await _localDb.database;
    await db.update(
      'customers',
      {'total_debt': debt},
      where: 'id = ? AND user_id = ?',
      whereArgs: [customerId, _userId],
    );

    if (_isOnline) {
      try {
        await _db
            .from('user_customers')
            .update({'total_debt': debt})
            .eq('user_id', _userId)
            .eq('id', customerId);
        return;
      } catch (_) {
        // فشل → pending
      }
    }

    await _localDb.addPendingOperation(
      tableName: 'user_customers',
      operation: 'update',
      recordId: customerId,
      payload: {'total_debt': debt, 'user_id': _userId},
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  عمليات الكاش المحلي
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _cacheCustomers(List<CustomerModel> customers) async {
    await _localDb.clearTable('customers', _userId);
    if (customers.isNotEmpty) {
      await _localDb.upsertAll(
        'customers',
        customers.map((c) => c.toLocalJson(_userId)).toList(),
      );
    }
  }

  Future<List<CustomerModel>> _getFromCache() async {
    final rows = await _localDb.getAll('customers', _userId);
    final customers = rows.map((r) => CustomerModel.fromJson(r)).toList();
    customers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return customers;
  }

  Future<CustomerModel?> _getByIdFromCache(String id) async {
    final row = await _localDb.getById('customers', id);
    if (row == null) return null;
    return CustomerModel.fromJson(row);
  }

  Future<CustomerModel> _upsertOffline(
      Map<String, dynamic> data, String? id) async {
    // إنشاء معرف جديد إذا لم يُوفَّر
    final effectiveId = id ?? 'LOCAL-${DateTime.now().millisecondsSinceEpoch}';
    data['id'] = effectiveId;
    data['created_at'] = DateTime.now().toIso8601String();

    final customer = CustomerModel.fromJson(data);
    await _localDb.upsert('customers', customer.toLocalJson(_userId));

    // إضافة عملية معلقة
    await _localDb.addPendingOperation(
      tableName: 'user_customers',
      operation: id != null ? 'update' : 'insert',
      recordId: effectiveId,
      payload: data,
    );

    return customer;
  }
}
