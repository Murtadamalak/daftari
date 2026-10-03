import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../local/offline_database.dart';
import '../../core/services/connectivity_service.dart';

// ─── Expense Categories ────────────────────────────────────────────────────────
const kExpenseCategories = [
  'مواد خام',
  'رواتب',
  'إيجار',
  'كهرباء ومياه',
  'نقل وتوصيل',
  'صيانة',
  'تسويق وإعلان',
  'مصاريف إدارية',
  'أخرى',
];

// ─── ExpenseModel ─────────────────────────────────────────────────────────────
class ExpenseModel {
  final String id;
  final String userId;
  final String title;
  final String category;
  final double amount;
  final String date; // yyyy-MM-dd
  final String? note;
  final String? invoiceId;
  final String? invoiceNum;
  final DateTime createdAt;

  const ExpenseModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
    this.invoiceId,
    this.invoiceNum,
    required this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> j) {
    double toD(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return ExpenseModel(
      id: j['id']?.toString() ?? '',
      userId: j['user_id']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      category: j['category']?.toString() ?? 'أخرى',
      amount: toD(j['amount']),
      date: j['date']?.toString() ?? '',
      note: j['note']?.toString(),
      invoiceId: (j['invoice_id'] as String?)?.isEmpty == true
          ? null
          : j['invoice_id']?.toString(),
      invoiceNum: (j['invoice_num'] as String?)?.isEmpty == true
          ? null
          : j['invoice_num']?.toString(),
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'category': category,
        'amount': amount,
        'date': date,
        'note': note,
        'invoice_id': invoiceId,
        'invoice_num': invoiceNum,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  ExpenseModel copyWith({
    String? title,
    String? category,
    double? amount,
    String? date,
    String? note,
    String? invoiceId,
    String? invoiceNum,
  }) =>
      ExpenseModel(
        id: id,
        userId: userId,
        title: title ?? this.title,
        category: category ?? this.category,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        note: note ?? this.note,
        invoiceId: invoiceId ?? this.invoiceId,
        invoiceNum: invoiceNum ?? this.invoiceNum,
        createdAt: createdAt,
      );
}

// ─── ExpenseRepository ────────────────────────────────────────────────────────
class ExpenseRepository {
  final _supabase = Supabase.instance.client;
  final _db = OfflineDatabase.instance;
  final _uuid = const Uuid();

  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Create ────────────────────────────────────────────────────────────────
  Future<ExpenseModel> create({
    required String title,
    required String category,
    required double amount,
    required DateTime date,
    String? note,
    String? invoiceId,
    String? invoiceNum,
  }) async {
    final uid = _userId;
    if (uid == null) throw Exception('المستخدم غير مسجّل الدخول');

    final expense = ExpenseModel(
      id: _uuid.v4(),
      userId: uid,
      title: title.trim(),
      category: category,
      amount: amount,
      date: '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      note: (note?.trim().isEmpty ?? true) ? null : note!.trim(),
      invoiceId: (invoiceId?.isEmpty ?? true) ? null : invoiceId,
      invoiceNum: (invoiceNum?.isEmpty ?? true) ? null : invoiceNum,
      createdAt: DateTime.now(),
    );

    await _db.upsert('expenses', expense.toJson());

    final isOnline = ConnectivityService.instance.isOnline;
    if (isOnline) {
      try {
        await _supabase
            .from('user_expenses')
            .upsert(expense.toJson(), onConflict: 'id');
      } catch (e) {
        debugPrint('[ExpenseRepo] create online failed: $e');
        await _db.addPendingOperation(
          tableName: 'user_expenses',
          operation: 'upsert',
          recordId: expense.id,
          payload: expense.toJson(),
        );
      }
    } else {
      await _db.addPendingOperation(
        tableName: 'user_expenses',
        operation: 'upsert',
        recordId: expense.id,
        payload: expense.toJson(),
      );
    }

    return expense;
  }

  // ── Update ────────────────────────────────────────────────────────────────
  Future<ExpenseModel> update(ExpenseModel expense) async {
    await _db.upsert('expenses', expense.toJson());

    final isOnline = ConnectivityService.instance.isOnline;
    if (isOnline) {
      try {
        await _supabase
            .from('user_expenses')
            .upsert(expense.toJson(), onConflict: 'id');
      } catch (e) {
        debugPrint('[ExpenseRepo] update online failed: $e');
        await _db.addPendingOperation(
          tableName: 'user_expenses',
          operation: 'upsert',
          recordId: expense.id,
          payload: expense.toJson(),
        );
      }
    } else {
      await _db.addPendingOperation(
        tableName: 'user_expenses',
        operation: 'upsert',
        recordId: expense.id,
        payload: expense.toJson(),
      );
    }
    return expense;
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> delete(String id) async {
    await _db.deleteById('expenses', id);

    final isOnline = ConnectivityService.instance.isOnline;
    if (isOnline) {
      try {
        await _supabase.from('user_expenses').delete().eq('id', id);
      } catch (e) {
        debugPrint('[ExpenseRepo] delete online failed: $e');
        await _db.addPendingOperation(
          tableName: 'user_expenses',
          operation: 'delete',
          recordId: id,
          payload: {'id': id},
        );
      }
    } else {
      await _db.addPendingOperation(
        tableName: 'user_expenses',
        operation: 'delete',
        recordId: id,
        payload: {'id': id},
      );
    }
  }

  // ── Read All ──────────────────────────────────────────────────────────────
  Future<List<ExpenseModel>> getAll() async {
    final uid = _userId;
    if (uid == null) return [];

    final isOnline = ConnectivityService.instance.isOnline;
    if (isOnline) {
      try {
        final data = await _supabase
            .from('user_expenses')
            .select()
            .eq('user_id', uid)
            .order('date', ascending: false);
        final expenses = (data as List).map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>)).toList();
        if (!kIsWeb) {
          await _db.upsertAll('expenses', expenses.map((e) => e.toJson()).toList());
        }
        return expenses;
      } catch (e) {
        debugPrint('[ExpenseRepo] getAll online failed: $e');
      }
    }

    if (kIsWeb) return [];
    final rows = await _db.getAll('expenses', uid);
    final expenses = rows.map((e) => ExpenseModel.fromJson(e)).toList();
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  // ── Read by Invoice ID ─────────────────────────────────────────────────────
  Future<List<ExpenseModel>> getByInvoiceId(String invoiceId) async {
    final uid = _userId;
    if (uid == null) return [];

    final isOnline = ConnectivityService.instance.isOnline;
    if (isOnline) {
      try {
        final data = await _supabase
            .from('user_expenses')
            .select()
            .eq('user_id', uid)
            .eq('invoice_id', invoiceId)
            .order('date', ascending: false);
        return (data as List)
            .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('[ExpenseRepo] getByInvoice online failed: $e');
      }
    }

    if (kIsWeb) return [];
    final rows = await _db.query(
      'expenses',
      where: 'user_id = ? AND invoice_id = ?',
      whereArgs: [uid, invoiceId],
    );
    return rows.map((e) => ExpenseModel.fromJson(e)).toList();
  }

  // ── Total in date range ────────────────────────────────────────────────────
  Future<double> getTotalInRange(DateTime from, DateTime to) async {
    final expenses = await getAll();
    double total = 0.0;
    for (final e in expenses) {
      final d = DateTime.tryParse(e.date);
      if (d != null && !d.isBefore(from) && !d.isAfter(to)) {
        total += e.amount;
      }
    }
    return total;
  }

  // ── Total by category ──────────────────────────────────────────────────────
  Future<Map<String, double>> getTotalByCategory({
    DateTime? from,
    DateTime? to,
  }) async {
    final expenses = await getAll();
    final filtered = expenses.where((e) {
      final d = DateTime.tryParse(e.date);
      if (d == null) return true;
      if (from != null && d.isBefore(from)) return false;
      if (to != null && d.isAfter(to)) return false;
      return true;
    });

    final Map<String, double> map = {};
    for (final e in filtered) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }
}
