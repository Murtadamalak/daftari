import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/subscription_models.dart';

class SubscriptionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<SubscriptionStatus?> getCurrentSubscription() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase.rpc<dynamic>(
        'get_user_subscription_status',
        params: {'target_user_id': userId},
      );

      if (response != null && response is List && response.isNotEmpty) {
        final Map<String, dynamic> data =
            response.first as Map<String, dynamic>;
        final status = SubscriptionStatus.fromJson(data);

        // If free, get the free tier limits
        if (status.plan == 'free') {
          final invoicesLimit = await _supabase.rpc<Map<String, dynamic>>(
              'check_free_limit',
              params: {'p_user_id': userId, 'p_action_type': 'invoice'});
          final customersLimit = await _supabase.rpc<Map<String, dynamic>>(
              'check_free_limit',
              params: {'p_user_id': userId, 'p_action_type': 'customer'});

          return SubscriptionStatus(
            plan: status.plan,
            currentStatus: status.currentStatus,
            daysRemaining: status.daysRemaining,
            isActive: status.isActive,
            invoicesRemaining:
                (invoicesLimit['remaining'] as num?)?.toInt() ?? 0,
            customersRemaining:
                (customersLimit['remaining'] as num?)?.toInt() ?? 0,
          );
        }

        return status;
      }
    } catch (e) {
      print('Error fetching subscription status: $e');
    }
    return null;
  }

  Future<PaymentConfig> getPaymentConfig() async {
    try {
      final response = await _supabase.from('app_config').select();
      final Map<String, dynamic> configMap = {};

      for (var row in response) {
        final Map<String, dynamic> rowData = row;
        configMap[rowData['key'].toString()] = rowData['value'];
      }

      return PaymentConfig.fromJson(configMap);
    } catch (e) {
      print('Error fetching payment config: $e');
      throw Exception('فشل في جلب إعدادات الدفع');
    }
  }

  Future<void> submitPaymentRequest({
    required String planType,
    required String? transferNum,
    required Uint8List receiptBytes,
    required String fileExtension,
    required String? note,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل الدخول');

    String step = 'upload_file';
    try {
      // 1. Upload the receipt file
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = '${user.id}/$fileName';

      await _supabase.storage
          .from('payment_receipts')
          .uploadBinary(filePath, receiptBytes);

      final receiptUrl =
          _supabase.storage.from('payment_receipts').getPublicUrl(filePath);

      // 2. Insert the payment request
      step = 'insert_request';
      final config = await getPaymentConfig();
      final amount =
          planType == 'monthly' ? config.monthlyPrice : config.yearlyPrice;

      await _supabase.from('payment_requests').insert({
        'user_id': user.id,
        'plan_type': planType,
        'amount': amount,
        'transfer_number': transferNum,
        'receipt_url': receiptUrl,
        'note': note, // Including the note
      });

      // 3. Update subscription status
      step = 'update_subscription';
      await _supabase.from('subscriptions').update({
        'status': 'pending',
      }).eq('user_id', user.id);
    } catch (e) {
      print('Error at step $step: $e');
      String msg = 'حدث خطأ';
      if (step == 'upload_file')
        msg = 'خطأ في رفع الملف';
      else if (step == 'insert_request')
        msg = 'خطأ في حفظ بيانات الطلب';
      else if (step == 'update_subscription')
        msg = 'خطأ في تحديث حالة الاشتراك';

      throw Exception('$msg: $e');
    }
  }
}
