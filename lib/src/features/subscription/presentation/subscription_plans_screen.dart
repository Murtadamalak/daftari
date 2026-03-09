import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/subscription_models.dart';
import '../data/subscription_provider.dart';
import '../../../core/providers/auth_provider.dart';
import 'payment_submission_screen.dart';
import 'widgets/payment_instructions_bottom_sheet.dart';
import '../../../core/theme/app_theme.dart';

class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  const SubscriptionPlansScreen({super.key, this.isWall = false});
  final bool isWall;

  @override
  ConsumerState<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState
    extends ConsumerState<SubscriptionPlansScreen> {
  String? _selectedPlan;

  final List<SubscriptionPlan> _plans = [
    const SubscriptionPlan(
      type: 'monthly',
      title: 'باقة شهرية',
      price: '10,000 دينار / شهر',
      subtitle: 'اشتراك شهري مرن',
      features: ['زبائن لا محدود', 'فواتير لا محدودة', 'إشعارات تنبيه'],
      missingFeatures: [],
    ),
    const SubscriptionPlan(
      type: 'yearly',
      title: 'باقة سنوية',
      price: '99,000 دينار / سنة',
      subtitle: 'وفّرت أكثر من شهرين!',
      features: [
        'زبائن لا محدود',
        'فواتير لا محدودة',
        'إشعارات تنبيه',
        'دعم فني أولوية'
      ],
      missingFeatures: [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(subscriptionProvider);
    final currentPlan = status?.plan ?? 'free';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          leading: widget.isWall
              ? const SizedBox()
              : null, // Hide back button if it's a wall
          title: Text(
            'تفعيل التطبيق',
            style: GoogleFonts.almarai(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (widget.isWall)
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                onPressed: () => ref.read(authProvider.notifier).logout(),
              ),
          ],
        ),
        body: status?.currentStatus == 'pending'
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hourglass_empty,
                          size: 80, color: Color(0xFFF59E0B)),
                      const SizedBox(height: 24),
                      Text(
                        'طلبك قيد المراجعة',
                        style: GoogleFonts.tajawal(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'يرجى الانتظار لحين قيام الإدارة بتفعيل حسابك.\nهذا قد يستغرق بعض الوقت.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                            fontSize: 16, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Text(
                      'ادعم المحلات العراقية',
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      itemCount: _plans.length,
                      itemBuilder: (context, index) {
                        final plan = _plans[index];
                        final isSelected = _selectedPlan == plan.type;
                        final isCurrent = currentPlan == plan.type;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPlan = plan.type;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              gradient: _getPlanGradient(plan.type, isSelected),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : Colors.white.withValues(alpha: 0.1),
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF6366F1)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            plan.title,
                                            style: GoogleFonts.tajawal(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          if (isCurrent)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                'توفير',
                                                style: GoogleFonts.tajawal(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        plan.price,
                                        style: GoogleFonts.tajawal(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (plan.type == 'yearly')
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            plan.subtitle,
                                            style: GoogleFonts.tajawal(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF22C55E),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 16),
                                      ...plan.features.map(
                                        (String f) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.check_circle,
                                                  color: Color(0xFF22C55E),
                                                  size: 18),
                                              const SizedBox(width: 8),
                                              Text(f,
                                                  style: GoogleFonts.tajawal(
                                                      color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      ...plan.missingFeatures.map(
                                        (String f) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.cancel,
                                                  color: Color(0xFFEF4444),
                                                  size: 18),
                                              const SizedBox(width: 8),
                                              Text(f,
                                                  style: GoogleFonts.tajawal(
                                                      color: Colors.grey[400])),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (plan.type == 'monthly')
                                  Positioned(
                                    top: -12,
                                    left: 20,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'الأكثر شيوعاً',
                                        style: GoogleFonts.tajawal(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Technical Support Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'للتواصل مع المطور والدعم الفني',
                                style: GoogleFonts.tajawal(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[300],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final Uri url = Uri.parse(
                                            'https://wa.me/9647813938267');
                                        await launchUrl(url,
                                            mode:
                                                LaunchMode.externalApplication);
                                      },
                                      icon: const Icon(
                                          Icons.chat_bubble_outline,
                                          size: 18),
                                      label: const Text('واتساب'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[700],
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final Uri url =
                                            Uri.parse('tel:07813938267');
                                        await launchUrl(url);
                                      },
                                      icon: const Icon(Icons.phone_outlined,
                                          size: 18),
                                      label: const Text('اتصال'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(
                                            color: Colors.white24),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextButton(
                          onPressed: () {
                            if (_selectedPlan != null &&
                                _selectedPlan != 'free') {
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) =>
                                    PaymentInstructionsBottomSheet(
                                        planType: _selectedPlan!),
                              );
                            }
                          },
                          child: Text(
                            'تعرف او على هذا الرقم 07876007620',
                            style: GoogleFonts.tajawal(
                              fontSize: 14,
                              color: const Color(0xFF6366F1),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              disabledBackgroundColor: Colors.grey[800],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: (_selectedPlan == null ||
                                    _selectedPlan == 'free')
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => PaymentSubmissionScreen(
                                            planType: _selectedPlan!),
                                      ),
                                    );
                                  },
                            child: Text(
                              'اشترك الآن',
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
                  ),
                ],
              ),
      ),
    );
  }

  Gradient _getPlanGradient(String type, bool isSelected) {
    if (type == 'free') {
      return LinearGradient(
        colors: [const Color(0xFF1E293B), const Color(0xFF334155)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (type == 'monthly') {
      return LinearGradient(
        colors: isSelected
            ? [AppColors.primary, AppColors.primaryLight]
            : [
                AppColors.primary.withOpacity(0.4),
                AppColors.primaryDark.withOpacity(0.4)
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (type == 'yearly') {
      return LinearGradient(
        colors: isSelected
            ? [AppColors.accent, const Color(0xFFB45309)]
            : [
                AppColors.accent.withOpacity(0.4),
                const Color(0xFFB45309).withOpacity(0.4)
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return LinearGradient(
        colors: [const Color(0xFF1E293B), const Color(0xFF1E293B)]);
  }
}
