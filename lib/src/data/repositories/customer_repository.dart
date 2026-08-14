import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        phone: j['phone']?.toString(),
        totalDebt: (j['total_debt'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'total_debt': totalDebt,
        'created_at': createdAt.toIso8601String(),
      };

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

  String get _userId => _db.auth.currentUser?.id ?? '';
  bool get _isOnline => ConnectivityService.instance.isOnline;

  Future<List<CustomerModel>> getAllCustomers() async {
    if (_userId.isEmpty) {
      return _getFromCache();
    }

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
        debugPrint('[CustomerRepo] Error fetching customers: $e');
        return _getFromCache();
      }
    } else {
      return _getFromCache();
    }
  }

  Future<List<CustomerModel>> getCustomersWithDebt() async {
    if (_userId.isEmpty) {
      final all = await _getFromCache();
      return all.where((c) => c.totalDebt > 0).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    }

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
    if (_userId.isEmpty) {
      return _getByIdFromCache(id);
    }

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
    if (id != null && id.isNotEmpty) {
      final updated = await updateCustomer(id: id, name: name, phone: phone);
      if (totalDebt > 0) {
        await updateDebt(id, totalDebt);
      }
      return updated;
    } else {
      return createCustomer(name: name, phone: phone, initialDebt: totalDebt);
    }
  }

  Future<CustomerModel> createCustomer({
    required String name,
    String? phone,
    double initialDebt = 0.0,
  }) async {
    final payload = {
      'user_id': _userId,
      'name': name,
      'phone': phone,
      'total_debt': initialDebt,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (_isOnline && _userId.isNotEmpty) {
      try {
        final res = await _db
            .from('user_customers')
            .insert(payload)
            .select()
            .single();
        final customer = CustomerModel.fromJson(res);
        if (!kIsWeb) {
          await _localDb.upsert('customers', customer.toLocalJson(_userId));
        }
        return customer;
      } catch (e) {
        return _upsertOffline(payload, null);
      }
    } else {
      return _upsertOffline(payload, null);
    }
  }

  Future<CustomerModel> updateCustomer({
    required String id,
    required String name,
    String? phone,
  }) async {
    final payload = {
      'name': name,
      'phone': phone,
    };

    if (_isOnline && _userId.isNotEmpty) {
      try {
        final res = await _db
            .from('user_customers')
            .update(payload)
            .eq('id', id)
            .eq('user_id', _userId)
            .select()
            .single();
        final customer = CustomerModel.fromJson(res);
        if (!kIsWeb) {
          await _localDb.upsert('customers', customer.toLocalJson(_userId));
        }
        return customer;
      } catch (_) {
        return _upsertOffline({'id': id, ...payload}, id);
      }
    } else {
      return _upsertOffline({'id': id, ...payload}, id);
    }
  }

  Future<void> updateDebt(String id, double newDebt) async {
    if (_isOnline && _userId.isNotEmpty) {
      try {
        await _db
            .from('user_customers')
            .update({'total_debt': newDebt})
            .eq('id', id)
            .eq('user_id', _userId);
      } catch (_) {
        if (!kIsWeb) {
          final db = await _localDb.database;
          await db.update(
            'customers',
            {'total_debt': newDebt},
            where: 'id = ? AND user_id = ?',
            whereArgs: [id, _userId],
          );
          await _localDb.addPendingOperation(
            tableName: 'user_customers',
            operation: 'update',
            recordId: id,
            payload: {'total_debt': newDebt, 'user_id': _userId},
          );
        }
      }
    } else {
      if (!kIsWeb) {
        final db = await _localDb.database;
        await db.update(
          'customers',
          {'total_debt': newDebt},
          where: 'id = ? AND user_id = ?',
          whereArgs: [id, _userId],
        );
        await _localDb.addPendingOperation(
          tableName: 'user_customers',
          operation: 'update',
          recordId: id,
          payload: {'total_debt': newDebt, 'user_id': _userId},
        );
      }
    }
  }

  Future<void> deleteCustomer(String id) async {
    if (_isOnline && _userId.isNotEmpty) {
      try {
        await _db
            .from('user_customers')
            .delete()
            .eq('id', id)
            .eq('user_id', _userId);
      } catch (_) {
        if (!kIsWeb) {
          await _localDb.deleteById('customers', id);
          await _localDb.addPendingOperation(
            tableName: 'user_customers',
            operation: 'delete',
            recordId: id,
            payload: {'id': id, 'user_id': _userId},
          );
        }
      }
    } else {
      if (!kIsWeb) {
        await _localDb.deleteById('customers', id);
        await _localDb.addPendingOperation(
          tableName: 'user_customers',
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

  Future<void> _cacheCustomers(List<CustomerModel> customers) async {
    if (_userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = customers.map((c) => c.toJson()).toList();
      await prefs.setString('cached_customers_$_userId', jsonEncode(jsonList));
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await _localDb.clearTable('customers', _userId);
        if (customers.isNotEmpty) {
          await _localDb.upsertAll(
            'customers',
            customers.map((c) => c.toLocalJson(_userId)).toList(),
          );
        }
      } catch (_) {}
    }
  }

  Future<List<CustomerModel>> _getFromCache() async {
    if (_userId.isEmpty) return [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cached_customers_$_userId');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        final list = decoded
            .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }
    } catch (_) {}

    if (!kIsWeb) {
      try {
        final rows = await _localDb.getAll('customers', _userId);
        final customers = rows.map((r) => CustomerModel.fromJson(r)).toList();
        customers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return customers;
      } catch (_) {}
    }

    return [];
  }

  Future<CustomerModel?> _getByIdFromCache(String id) async {
    final all = await _getFromCache();
    final match = all.where((c) => c.id == id);
    return match.isNotEmpty ? match.first : null;
  }

  Future<CustomerModel> _upsertOffline(
      Map<String, dynamic> data, String? id) async {
    final effectiveId = id ?? const Uuid().v4();
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
