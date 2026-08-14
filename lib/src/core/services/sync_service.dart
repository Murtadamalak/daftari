import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/offline_database.dart';
import 'connectivity_service.dart';

/// محرك المزامنة بين القاعدة المحلية و Supabase.
///
/// ■ عند توفر الإنترنت:
///   1. يرفع العمليات المعلقة (pending_operations) → Supabase
///   2. يسحب أحدث البيانات من Supabase → SQLite
///
/// ■ عند فقدان الإنترنت:
///   كل العمليات تُكتب في pending_operations وتُحفظ محلياً فقط
class SyncService {
  static SyncService? _instance;
  SyncService._();

  static SyncService get instance {
    _instance ??= SyncService._();
    return _instance!;
  }

  final _offlineDb = OfflineDatabase.instance;
  final _connectivity = ConnectivityService.instance;

  SupabaseClient get _supabase => Supabase.instance.client;
  String get _userId => _supabase.auth.currentUser?.id ?? '';

  StreamSubscription<bool>? _connectivitySub;
  Timer? _periodicSync;

  bool _isSyncing = false;
  bool _initialized = false;

  // Stream لإعلام الـ UI بحالة المزامنة
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  SyncStatus _lastStatus = SyncStatus.idle;
  SyncStatus get lastStatus => _lastStatus;

  /// تهيئة المزامنة: الاشتراك بتغيّرات الاتصال + مزامنة دورية
  Future<void> initialize() async {
    if (_initialized || _userId.isEmpty) return;
    _initialized = true;

    // مراقبة تغيّر حالة الاتصال
    _connectivitySub = _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        debugPrint('[Sync] Internet returned – starting sync...');
        syncAll();
      }
    });

    // مزامنة دورية كل 3 دقائق إذا كان متصلاً
    _periodicSync = Timer.periodic(const Duration(minutes: 3), (_) {
      if (_connectivity.isOnline && !_isSyncing) {
        syncAll();
      }
    });

    // مزامنة أولية فوراً إذا كان متصلاً
    if (_connectivity.isOnline) {
      await syncAll();
    }
  }

  /// تشغيل مزامنة كاملة (رفع المعلقات + سحب من السحابة)
  Future<void> syncAll() async {
    if (_isSyncing || _userId.isEmpty) return;
    _isSyncing = true;
    _emitStatus(SyncStatus.syncing);

    try {
      // 1. رفع العمليات المعلقة أولاً
      await _pushPendingOperations();

      // 2. سحب أحدث البيانات من Supabase
      await _pullFromCloud();

      _emitStatus(SyncStatus.synced);
      debugPrint('[Sync] ✓ Full sync completed successfully.');
    } catch (e) {
      debugPrint('[Sync] ✗ Sync failed: $e');
      _emitStatus(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  رفع العمليات المعلقة إلى Supabase
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _pushPendingOperations() async {
    final pending = await _offlineDb.getPendingOperations();
    if (pending.isEmpty) return;

    debugPrint('[Sync] Pushing ${pending.length} pending operations...');

    for (final op in pending) {
      final id = op['id'] as int;
      final tableName = op['table_name'] as String;
      final operation = op['operation'] as String;
      final recordId = op['record_id'] as String;
      final payload =
          jsonDecode(op['payload'] as String) as Map<String, dynamic>;

      try {
        switch (operation) {
          case 'insert':
            await _supabase.from(tableName).upsert(payload);
            break;
          case 'update':
            await _supabase
                .from(tableName)
                .update(payload)
                .eq('id', recordId)
                .eq('user_id', _userId);
            break;
          case 'delete':
            await _supabase
                .from(tableName)
                .delete()
                .eq('id', recordId)
                .eq('user_id', _userId);
            break;
          case 'delete_where':
            // حذف بنود فاتورة محددة (مثال)
            final invoiceId = payload['invoice_id'] as String?;
            if (invoiceId != null) {
              await _supabase
                  .from(tableName)
                  .delete()
                  .eq('user_id', _userId)
                  .eq('invoice_id', invoiceId);
            }
            break;
        }

        // نجحت العملية – نحذفها من قائمة الانتظار
        await _offlineDb.deletePendingOperation(id);
      } catch (e) {
        debugPrint('[Sync] Failed to push op $id ($operation on $tableName): $e');
        await _offlineDb.incrementRetryCount(id);
      }
    }

    // تنظيف العمليات التي فشلت كثيراً
    await _offlineDb.pruneFailedOperations();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  سحب البيانات من Supabase إلى القاعدة المحلية
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _pullFromCloud() async {
    if (_userId.isEmpty) return;

    try {
      await Future.wait([
        _pullCustomers(),
        _pullProducts(),
        _pullInvoices(),
      ]);
    } catch (e) {
      debugPrint('[Sync] Pull from cloud error: $e');
      rethrow;
    }
  }

  Future<void> _pullCustomers() async {
    final res = await _supabase
        .from('user_customers')
        .select()
        .eq('user_id', _userId);

    final rows = (res as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    // نمسح القديم ونضع الجديد
    await _offlineDb.clearTable('customers', _userId);
    if (rows.isNotEmpty) {
      await _offlineDb.upsertAll('customers', rows.map((r) => {
        'id': r['id'],
        'user_id': r['user_id'],
        'name': r['name'],
        'phone': r['phone'],
        'total_debt': (r['total_debt'] as num?)?.toDouble() ?? 0,
        'created_at': r['created_at'],
      }).toList());
    }

    await _offlineDb.setLastSyncTime('customers', DateTime.now().toUtc());
  }

  Future<void> _pullProducts() async {
    final res = await _supabase
        .from('user_products')
        .select()
        .eq('user_id', _userId);

    final rows = (res as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    await _offlineDb.clearTable('products', _userId);
    if (rows.isNotEmpty) {
      await _offlineDb.upsertAll('products', rows.map((r) => {
        'id': r['id'],
        'user_id': r['user_id'],
        'name': r['name'],
        'unit': r['unit'] ?? 'قطعة',
        'barcode': r['barcode'],
        'retail_price': (r['retail_price'] as num?)?.toDouble() ?? 0,
        'wholesale_price': (r['wholesale_price'] as num?)?.toDouble(),
        'stock': (r['stock'] as num?)?.toDouble(),
        'created_at': r['created_at'],
      }).toList());
    }

    await _offlineDb.setLastSyncTime('products', DateTime.now().toUtc());
  }

  Future<void> _pullInvoices() async {
    // جلب الفواتير
    final invRes = await _supabase
        .from('user_invoices')
        .select()
        .eq('user_id', _userId);

    final invoices = (invRes as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    await _offlineDb.clearTable('invoices', _userId);
    if (invoices.isNotEmpty) {
      await _offlineDb.upsertAll('invoices', invoices.map((r) => {
        'id': r['id'],
        'user_id': r['user_id'],
        'num': r['num'],
        'date': r['date'],
        'customer_id': r['customer_id'],
        'customer_name': r['customer_name'],
        'customer_phone': r['customer_phone'],
        'subtotal': (r['subtotal'] as num?)?.toDouble() ?? 0,
        'discount': (r['discount'] as num?)?.toDouble() ?? 0,
        'grand_total': (r['grand_total'] as num?)?.toDouble() ?? 0,
        'paid': (r['paid'] as num?)?.toDouble() ?? 0,
        'debt': (r['debt'] as num?)?.toDouble() ?? 0,
        'pay_type': r['pay_type'] ?? 'cash',
        'note': r['note'],
        'status': r['status'] ?? 'paid',
        'shop_name': r['shop_name'] ?? '',
        'shop_phone': r['shop_phone'],
        'owner_name': r['owner_name'],
        'shop_logo_path': r['shop_logo_path'],
      }).toList());
    }

    // جلب جميع بنود الفواتير
    final itemsRes = await _supabase
        .from('user_invoice_items')
        .select()
        .eq('user_id', _userId);

    final items = (itemsRes as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();

    // حذف بنود المستخدم القديمة
    final db = await _offlineDb.database;
    await db.delete('invoice_items', where: 'user_id = ?', whereArgs: [_userId]);

    if (items.isNotEmpty) {
      await _offlineDb.upsertAll('invoice_items', items.map((r) => {
        'id': r['id'],
        'invoice_id': r['invoice_id'],
        'user_id': r['user_id'],
        'product_name': r['product_name'],
        'unit': r['unit'] ?? 'قطعة',
        'qty': (r['qty'] as num?)?.toDouble() ?? 1,
        'unit_price': (r['unit_price'] as num?)?.toDouble() ?? 0,
        'price_type': r['price_type'] ?? 'retail',
        'total': (r['total'] as num?)?.toDouble() ?? 0,
        'note': r['note'] as String? ?? '',
      }).toList());
    }

    await _offlineDb.setLastSyncTime('invoices', DateTime.now().toUtc());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  أدوات مساعدة
  // ═══════════════════════════════════════════════════════════════════════════

  void _emitStatus(SyncStatus status) {
    _lastStatus = status;
    _syncStatusController.add(status);
  }

  /// تنظيف الموارد
  void dispose() {
    _connectivitySub?.cancel();
    _periodicSync?.cancel();
    _syncStatusController.close();
    _initialized = false;
    _instance = null;
  }
}

/// حالة المزامنة
enum SyncStatus {
  idle,     // لم تبدأ بعد
  syncing,  // جارٍ المزامنة
  synced,   // تمت المزامنة بنجاح
  error,    // حدث خطأ أثناء المزامنة
}
