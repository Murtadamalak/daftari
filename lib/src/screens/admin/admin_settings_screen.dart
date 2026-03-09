import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  
  final _zainCashController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _monthlyPriceController = TextEditingController();
  final _yearlyPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchConfig();
  }

  Future<void> _fetchConfig() async {
    final res = await _supabase.from('app_config').select('*');
    for (var row in res) {
      if (row['key'] == 'payment_info') {
        _zainCashController.text = row['value']['zain_cash_number']?.toString() ?? '';
        _accountHolderController.text = row['value']['account_holder']?.toString() ?? '';
      } else if (row['key'] == 'pricing') {
        _monthlyPriceController.text = row['value']['monthly']?.toString() ?? '';
        _yearlyPriceController.text = row['value']['yearly']?.toString() ?? '';
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isLoading = true);
    try {
      final paymentInfo = {
        'zain_cash_number': _zainCashController.text.trim(),
        'account_holder': _accountHolderController.text.trim()
      };
      final pricing = {
        'monthly': int.tryParse(_monthlyPriceController.text.trim()) ?? 10000,
        'yearly': int.tryParse(_yearlyPriceController.text.trim()) ?? 99000,
      };

      await _supabase.from('app_config').upsert({
        'key': 'payment_info',
        'value': paymentInfo,
        'updated_at': DateTime.now().toIso8601String()
      });

      await _supabase.from('app_config').upsert({
        'key': 'pricing',
        'value': pricing,
        'updated_at': DateTime.now().toIso8601String()
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('معلومات الدفع والتسعير', style: GoogleFonts.tajawal(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),

          _buildSection('إعدادات زين كاش', [
            _buildField('رقم الهاتف للاستلام', _zainCashController, isNumber: true, textDirection: TextDirection.ltr),
            _buildField('اسم صاحب الحساب', _accountHolderController),
          ]),
          
          const SizedBox(height: 24),

          _buildSection('أسعار الباقات (د.ع)', [
            _buildField('سعر الباقة الشهرية', _monthlyPriceController, isNumber: true, textDirection: TextDirection.ltr),
            _buildField('سعر الباقة السنوية', _yearlyPriceController, isNumber: true, textDirection: TextDirection.ltr),
          ]),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveConfig,
              child: Text('حفظ التغييرات', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isNumber = false, TextDirection? textDirection}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        textDirection: textDirection,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF0F172A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
