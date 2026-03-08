import 'package:supabase_flutter/supabase_flutter.dart';

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

  String get _userId => _db.auth.currentUser!.id;

  Future<List<CustomerModel>> getAllCustomers() async {
    final res = await _db
        .from('user_customers')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return res.map((e) => CustomerModel.fromJson(e)).toList();
  }

  Future<List<CustomerModel>> getCustomersWithDebt() async {
    final res = await _db
        .from('user_customers')
        .select()
        .eq('user_id', _userId)
        .gt('total_debt', 0)
        .order('name');
    return res.map((e) => CustomerModel.fromJson(e)).toList();
  }

  Future<CustomerModel?> getById(String id) async {
    final res = await _db
        .from('user_customers')
        .select()
        .eq('user_id', _userId)
        .eq('id', id)
        .maybeSingle();
    if (res == null) return null;
    return CustomerModel.fromJson(res);
  }

  Future<CustomerModel> upsertCustomer({
    String? id,
    required String name,
    String? phone,
    double totalDebt = 0,
  }) async {
    final data = <String, dynamic>{
      'user_id': _userId,
      'name': name,
      'phone': phone,
      'total_debt': totalDebt,
    };
    if (id != null) data['id'] = id;

    final res = await _db.from('user_customers').upsert(data).select().single();
    return CustomerModel.fromJson(res);
  }

  Future<void> deleteCustomer(String id) async {
    await _db
        .from('user_customers')
        .delete()
        .eq('user_id', _userId)
        .eq('id', id);
  }

  Future<void> updateDebt(String customerId, double newDebt) async {
    await _db
        .from('user_customers')
        .update({'total_debt': newDebt < 0 ? 0 : newDebt})
        .eq('user_id', _userId)
        .eq('id', customerId);
  }
}
