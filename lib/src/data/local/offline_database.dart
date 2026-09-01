import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

/// قاعدة بيانات SQLite المحلية للعمل بدون إنترنت.
///
/// تحتوي على جداول مطابقة لبيانات Supabase:
/// - customers, products, invoices, invoice_items
/// - pending_operations: عمليات لم تُرفع بعد للسحابة
class OfflineDatabase {
  static OfflineDatabase? _instance;
  static Database? _db;

  OfflineDatabase._();

  static OfflineDatabase get instance {
    _instance ??= OfflineDatabase._();
    return _instance!;
  }

  /// فتح أو إنشاء قاعدة البيانات المحلية
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'daftar_offline_v2.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE invoice_items ADD COLUMN note TEXT');
          } catch (e) {
            debugPrint('Error altering invoice_items table: $e');
          }
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ── الزبائن ──
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        total_debt REAL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // ── المنتجات ──
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        unit TEXT DEFAULT 'قطعة',
        barcode TEXT,
        retail_price REAL DEFAULT 0,
        wholesale_price REAL,
        stock REAL,
        created_at TEXT NOT NULL
      )
    ''');

    // ── الفواتير ──
    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        num INTEGER NOT NULL,
        date TEXT NOT NULL,
        customer_id TEXT,
        customer_name TEXT NOT NULL,
        customer_phone TEXT,
        subtotal REAL DEFAULT 0,
        discount REAL DEFAULT 0,
        grand_total REAL DEFAULT 0,
        paid REAL DEFAULT 0,
        debt REAL DEFAULT 0,
        pay_type TEXT DEFAULT 'cash',
        note TEXT,
        status TEXT DEFAULT 'paid',
        shop_name TEXT DEFAULT '',
        shop_phone TEXT,
        owner_name TEXT,
        shop_logo_path TEXT
      )
    ''');

    // ── بنود الفاتورة ──
    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoice_items (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        unit TEXT DEFAULT 'قطعة',
        qty REAL DEFAULT 1,
        unit_price REAL DEFAULT 0,
        price_type TEXT DEFAULT 'retail',
        total REAL DEFAULT 0,
        note TEXT,
        FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
      )
    ''');

    // ── العمليات المعلقة (لم ترفع للسحابة بعد) ──
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        operation TEXT NOT NULL,
        record_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    // ── آخر وقت مزامنة ──
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // فهارس لتسريع البحث
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_invoices_user ON invoices(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_invoices_customer ON invoices(customer_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_items_invoice ON invoice_items(invoice_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_user ON products(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_customers_user ON customers(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_pending_created ON pending_operations(created_at)');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  عمليات عامة (CRUD) على الجداول
  // ═══════════════════════════════════════════════════════════════════════════

  /// إدخال أو تحديث صف في جدول ما
  Future<void> upsert(String table, Map<String, dynamic> data) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// إدخال أو تحديث مجموعة صفوف دفعة واحدة
  Future<void> upsertAll(
      String table, List<Map<String, dynamic>> rows) async {
    if (kIsWeb) return;
    final db = await database;
    final batch = db.batch();
    for (final row in rows) {
      batch.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// حذف صف بحسب المعرف
  Future<void> deleteById(String table, String id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  /// حذف جميع الصفوف التي تطابق userId في جدول معين
  Future<void> clearTable(String table, String userId) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete(table, where: 'user_id = ?', whereArgs: [userId]);
  }

  /// جلب جميع صفوف الجدول لمستخدم معين
  Future<List<Map<String, dynamic>>> getAll(
      String table, String userId) async {
    if (kIsWeb) return [];
    final db = await database;
    return db.query(table, where: 'user_id = ?', whereArgs: [userId]);
  }

  /// جلب صف واحد بمعرفه
  Future<Map<String, dynamic>?> getById(String table, String id) async {
    if (kIsWeb) return null;
    final db = await database;
    final rows = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? rows.first : null;
  }

  /// استعلام حسب شرط مخصص
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    if (kIsWeb) return [];
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  عمليات الفواتير وبنودها (خاصة)
  // ═══════════════════════════════════════════════════════════════════════════

  /// حذف جميع بنود فاتورة معينة
  Future<void> deleteInvoiceItems(String invoiceId, String userId) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete(
      'invoice_items',
      where: 'invoice_id = ? AND user_id = ?',
      whereArgs: [invoiceId, userId],
    );
  }

  /// جلب بنود فاتورة معينة
  Future<List<Map<String, dynamic>>> getInvoiceItems(
      String invoiceId, String userId) async {
    if (kIsWeb) return [];
    final db = await database;
    return db.query(
      'invoice_items',
      where: 'invoice_id = ? AND user_id = ?',
      whereArgs: [invoiceId, userId],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  عمليات pending_operations (العمليات المعلقة)
  // ═══════════════════════════════════════════════════════════════════════════

  /// إضافة عملية معلقة ليتم مزامنتها لاحقاً
  Future<void> addPendingOperation({
    required String tableName,
    required String operation,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert('pending_operations', {
      'table_name': tableName,
      'operation': operation,
      'record_id': recordId,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'retry_count': 0,
    });
  }

  /// جلب جميع العمليات المعلقة مرتبة حسب وقت الإنشاء
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    if (kIsWeb) return [];
    final db = await database;
    return db.query('pending_operations', orderBy: 'created_at ASC');
  }

  /// عدد العمليات المعلقة
  Future<int> getPendingCount() async {
    if (kIsWeb) return 0;
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM pending_operations');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// حذف عملية معلقة بعد مزامنتها بنجاح
  Future<void> deletePendingOperation(int id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('pending_operations', where: 'id = ?', whereArgs: [id]);
  }

  /// تحديث عدد المحاولات الفاشلة
  Future<void> incrementRetryCount(int id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.rawUpdate(
      'UPDATE pending_operations SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  /// حذف عمليات فشلت أكثر من الحد المسموح
  Future<void> pruneFailedOperations({int maxRetries = 10}) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete(
      'pending_operations',
      where: 'retry_count >= ?',
      whereArgs: [maxRetries],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  بيانات المزامنة (sync_meta)
  // ═══════════════════════════════════════════════════════════════════════════

  /// حفظ وقت آخر مزامنة ناجحة
  Future<void> setLastSyncTime(String tableName, DateTime time) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert(
      'sync_meta',
      {
        'key': 'last_sync_$tableName',
        'value': time.toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// جلب وقت آخر مزامنة ناجحة
  Future<DateTime?> getLastSyncTime(String tableName) async {
    if (kIsWeb) return null;
    final db = await database;
    final rows = await db.query(
      'sync_meta',
      where: 'key = ?',
      whereArgs: ['last_sync_$tableName'],
    );
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['value'] as String);
  }

  /// تنظيف جميع البيانات عند تسجيل الخروج
  Future<void> clearAllData() async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('invoice_items');
    await db.delete('invoices');
    await db.delete('customers');
    await db.delete('products');
    await db.delete('pending_operations');
    await db.delete('sync_meta');
    debugPrint('[OfflineDB] All local data cleared.');
  }

  /// إغلاق قاعدة البيانات
  Future<void> close() async {
    if (kIsWeb) return;
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
