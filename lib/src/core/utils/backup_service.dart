import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_io/io.dart';
import 'package:uuid/uuid.dart';

/// نوع مُعادًا من [BackupService.restore] لإعلام الـUI بالنتيجة
class RestoreResult {
  final int customers;
  final int products;
  final int invoices;
  final int invoiceItems;

  const RestoreResult({
    required this.customers,
    required this.products,
    required this.invoices,
    required this.invoiceItems,
  });
}

/// خدمة النسخ الاحتياطي والاسترداد
/// تعمل على خادم Supabase وتنتج ملف JSON منظّم قابل للاسترداد
class BackupService {
  static final SupabaseClient _db = Supabase.instance.client;
  static String get _userId => _db.auth.currentUser!.id;

  // ─────────────────────────────────────────────────────────────────────────
  // EXPORT
  // ─────────────────────────────────────────────────────────────────────────

  /// يجمع كل بيانات المستخدم من Supabase ويصدّرها كملف JSON
  static Future<void> exportBackup() async {
    // 1. جلب جميع البيانات بالتوازي
    final results = await Future.wait([
      _db.from('user_customers').select().eq('user_id', _userId),
      _db.from('user_products').select().eq('user_id', _userId),
      _db.from('user_invoices').select().eq('user_id', _userId).order('num'),
      _db.from('user_invoice_items').select().eq('user_id', _userId),
    ]);

    final customers = results[0] as List<dynamic>;
    final products = results[1] as List<dynamic>;
    final invoices = results[2] as List<dynamic>;
    final invoiceItems = results[3] as List<dynamic>;

    // 2. بناء الحزمة
    final payload = {
      'version': 2,
      'app': 'دفتري',
      'exported_at': DateTime.now().toIso8601String(),
      'user_id': _userId,
      'counts': {
        'customers': customers.length,
        'products': products.length,
        'invoices': invoices.length,
        'invoice_items': invoiceItems.length,
      },
      'data': {
        'customers': customers,
        'products': products,
        'invoices': invoices,
        'invoice_items': invoiceItems,
      },
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));
    final date = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final fileName = 'daftari_backup_$date.json';

    if (kIsWeb) {
      // على الويب نستخدم share_plus لتنزيل الملف
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: fileName, mimeType: 'application/json')],
        text: 'ملف النسخة الاحتياطية - دفتري',
      );
    } else {
      // على الموبايل / ديسكتوب نحفظ في مجلد مؤقت ثم نشارك
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'ملف النسخة الاحتياطية - دفتري',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IMPORT / RESTORE
  // ─────────────────────────────────────────────────────────────────────────

  /// يقرأ ملف JSON (bytes) ويُعيد رفع البيانات إلى Supabase
  /// [clearFirst] - عند true تُحذف البيانات القديمة قبل الاستيراد
  static Future<RestoreResult> restoreFromBytes(
    Uint8List bytes, {
    bool clearFirst = true,
  }) async {
    // 1. تحليل الملف
    final jsonStr = utf8.decode(bytes);
    final Map<String, dynamic> payload =
        jsonDecode(jsonStr) as Map<String, dynamic>;

    // التحقق من صيغة الملف
    if (payload['app'] != 'دفتري' && payload['app'] != 'Daftari') {
      throw const FormatException(
          'الملف غير صالح. يرجى اختيار ملف نسخة احتياطية من نظام دفتري.');
    }

    final data = payload['data'] as Map<String, dynamic>;
    final rawCustomers = ((data['customers'] as List?) ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final rawProducts = ((data['products'] as List?) ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final rawInvoices = ((data['invoices'] as List?) ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final rawItems = ((data['invoice_items'] as List?) ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();

    // 2. حذف البيانات القديمة (اختياري)
    if (clearFirst) {
      // الترتيب مهم: البنود أولاً ثم الفواتير ثم الزبائن والمنتجات
      await _db.from('user_invoice_items').delete().eq('user_id', _userId);
      await _db.from('user_invoices').delete().eq('user_id', _userId);
      await _db.from('user_customers').delete().eq('user_id', _userId);
      await _db.from('user_products').delete().eq('user_id', _userId);
    }

    // 3. حقن الزبائن
    int custCount = 0;
    for (final row in rawCustomers) {
      final clean = _sanitize(row, _userId);
      await _db.from('user_customers').upsert(clean, onConflict: 'id');
      custCount++;
    }

    // 4. حقن المنتجات
    int prodCount = 0;
    for (final row in rawProducts) {
      final clean = _sanitize(row, _userId);
      await _db.from('user_products').upsert(clean, onConflict: 'id');
      prodCount++;
    }

    // 5. حقن الفواتير
    int invCount = 0;
    for (final row in rawInvoices) {
      final clean = _sanitize(row, _userId);
      await _db.from('user_invoices').upsert(clean, onConflict: 'id');
      invCount++;
    }

    // 6. حقن بنود الفواتير
    int itemCount = 0;
    for (final row in rawItems) {
      final clean = _sanitize(row, _userId);
      // بنود الفواتير تحتاج uuid فريد لكل بند
      if (clean['id'] == null || (clean['id'] as String).isEmpty) {
        clean['id'] = const Uuid().v4();
      }
      await _db.from('user_invoice_items').upsert(clean, onConflict: 'id');
      itemCount++;
    }

    return RestoreResult(
      customers: custCount,
      products: prodCount,
      invoices: invCount,
      invoiceItems: itemCount,
    );
  }

  /// ينظّف صف بيانات: يزيل الحقول غير المرغوب بإعادتها ويضمن user_id صحيح
  static Map<String, dynamic> _sanitize(
      Map<String, dynamic> row, String userId) {
    final clean = Map<String, dynamic>.from(row);
    // تأكّد أن user_id دائماً يخص المستخدم الحالي
    clean['user_id'] = userId;
    return clean;
  }
}
