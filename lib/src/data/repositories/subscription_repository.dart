import 'package:supabase_flutter/supabase_flutter.dart';

enum SubscriptionPlan { monthly, yearly }

class SubscriptionRepository {
  final _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;

  Future<void> submitPaymentRequest({
    required SubscriptionPlan plan,
    required double amount,
    String? transferNumber,
    String? receiptUrl,
  }) async {
    await _supabase.from('payment_requests').insert({
      'user_id': _userId,
      'plan_type': plan == SubscriptionPlan.monthly ? 'monthly' : 'yearly',
      'amount': amount,
      'transfer_number': transferNumber,
      'receipt_url': receiptUrl,
      'status': 'pending',
    });
  }

  Future<Map<String, dynamic>?> getLatestRequest() async {
    final res = await _supabase
        .from('payment_requests')
        .select()
        .eq('user_id', _userId)
        .order('submitted_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return res;
  }

  Future<void> refreshSubscriptionStatus() async {
    // This is handled by authProvider's listener,
    // but we can force a session refresh or just wait for the listener.
    await _supabase.auth.refreshSession();
  }
}
