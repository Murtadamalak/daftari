import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final res = await _supabase
        .from('payment_requests')
        .select('*, profiles(full_name, shop_name, phone)')
        .eq('status', 'pending')
        .order('submitted_at', ascending: false);

    if (mounted) {
      setState(() {
        _requests = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    }
  }

  Future<void> _activate(Map<String, dynamic> req) async {
    try {
      await _supabase.rpc<void>('activate_subscription', params: {
        'p_user_id': req['user_id'],
        'p_plan': req['plan_type'],
        'p_admin_id': _supabase.auth.currentUser!.id,
        'p_payment_request_id': req['id']
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('تم التفعيل بنجاح', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green));
      }
      _fetchRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _reject(Map<String, dynamic> req) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title:
            Text('سبب الرفض', style: GoogleFonts.tajawal(color: Colors.white)),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'اكتب السبب هنا...',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('إلغاء', style: GoogleFonts.tajawal(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: Text('رفض الطلب',
                style: GoogleFonts.tajawal(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await _supabase.from('payment_requests').update({
          'status': 'rejected',
          'rejection_reason': reason,
          'reviewed_at': DateTime.now().toIso8601String()
        }).eq('id', req['id'] as Object);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('تم الرفض بنجاح'), backgroundColor: Colors.orange));
        }
        _fetchRequests();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('خطأ: ${e.toString()}'),
              backgroundColor: Colors.red));
        }
      }
    }
  }

  void _showReceipt(String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(url, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_requests.isEmpty) {
      return const Center(
          child: Text('لا توجد طلبات معلقة',
              style: TextStyle(color: Colors.grey, fontSize: 18)));
    }

    return RefreshIndicator(
      onRefresh: _fetchRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final Map<String, dynamic> req = _requests[index];
          final dynamic profileData = req['profiles'];
          final Map<String, dynamic> profile = profileData is List
              ? (profileData.isNotEmpty
                  ? profileData[0] as Map<String, dynamic>
                  : {})
              : profileData as Map<String, dynamic>? ?? {};

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(profile['full_name']?.toString() ?? 'مجهول',
                        style: GoogleFonts.tajawal(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text('${req['amount']} د.ع',
                        style: GoogleFonts.tajawal(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('المحل: ${profile['shop_name'] ?? '-'}',
                    style: GoogleFonts.tajawal(color: Colors.grey[400])),
                Text('الهاتف: ${profile['phone'] ?? '-'}',
                    style: GoogleFonts.tajawal(color: Colors.grey[400])),
                Text('رقم العملية: ${req['transfer_number'] ?? 'غير متوفر'}',
                    style: GoogleFonts.tajawal(color: Colors.grey[400])),
                Text(
                    'الباقة: ${req['plan_type'] == 'yearly' ? 'سنوية' : 'شهرية'}',
                    style: GoogleFonts.tajawal(color: Colors.orange)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (req['receipt_url'] != null)
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                          ),
                          onPressed: () =>
                              _showReceipt(req['receipt_url'] as String),
                          child: const Text('عرض الإيصال'),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => _reject(req),
                        child: const Text('رفض',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        onPressed: () => _activate(req),
                        child: const Text('تفعيل',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
