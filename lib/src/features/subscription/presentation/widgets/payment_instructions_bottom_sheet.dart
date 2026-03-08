import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/subscription_provider.dart';

class PaymentInstructionsBottomSheet extends ConsumerWidget {
  final String planType;

  const PaymentInstructionsBottomSheet({super.key, required this.planType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(paymentConfigProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'طريقة الدفع',
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          configAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1))),
            error: (err, stack) => Center(
              child: Text(
                'حدث خطأ في تحميل المعلومات',
                style: GoogleFonts.tajawal(color: const Color(0xFFEF4444)),
              ),
            ),
            data: (config) {
              final amount = planType == 'monthly'
                  ? config.monthlyPrice
                  : config.yearlyPrice;

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'رقم زين كاش',
                              style:
                                  GoogleFonts.tajawal(color: Colors.grey[400]),
                            ),
                            Row(
                              children: [
                                Text(
                                  config.zainCashNumber,
                                  style: GoogleFonts.tajawal(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy,
                                      color: Color(0xFF6366F1), size: 20),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                        text: config.zainCashNumber));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('تم النسخ',
                                            style: GoogleFonts.tajawal()),
                                        backgroundColor:
                                            const Color(0xFF22C55E),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF1E293B)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'اسم صاحب الحساب',
                              style:
                                  GoogleFonts.tajawal(color: Colors.grey[400]),
                            ),
                            Text(
                              config.accountHolder,
                              style: GoogleFonts.tajawal(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF1E293B)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'المبلغ المطلوب',
                              style:
                                  GoogleFonts.tajawal(color: Colors.grey[400]),
                            ),
                            Text(
                              '$amount دينار',
                              style: GoogleFonts.tajawal(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._buildSteps([
                    'افتح تطبيق زين كاش',
                    'اضغط على "تحويل أموال"',
                    'أدخل رقم الهاتف الموضح أعلاه',
                    'أدخل المبلغ المطلوب بالضبط ($amount دينار)',
                    'أرسل الأموال وخذ لقطة شاشة للوصل'
                  ]),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'حسناً، فهمت',
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSteps(List<String> steps) {
    return List.generate(steps.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                steps[index],
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: Colors.grey[300],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
