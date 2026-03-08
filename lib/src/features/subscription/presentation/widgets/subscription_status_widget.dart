import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../data/subscription_provider.dart';
import '../subscription_plans_screen.dart';

class SubscriptionStatusWidget extends ConsumerStatefulWidget {
  const SubscriptionStatusWidget({super.key});

  @override
  ConsumerState<SubscriptionStatusWidget> createState() =>
      _SubscriptionStatusWidgetState();
}

class _SubscriptionStatusWidgetState
    extends ConsumerState<SubscriptionStatusWidget> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to confetti trigger
    ref.listen<bool>(showConfettiProvider, (previous, next) {
      if (next && !(previous ?? false)) {
        _confettiController.play();
        // Reset the provider after showing
        Future.delayed(const Duration(seconds: 4), () {
          ref.read(showConfettiProvider.notifier).state = false;
        });
      }
    });

    final status = ref.watch(subscriptionProvider);

    if (status == null) {
      // Loading state or offline
      return const SizedBox.shrink();
    }

    if (status.plan == 'free') {
      return _buildBanner(
        context: context,
        color: const Color(0xFF1E293B), // Dark slate
        icon: Icons.info_outline,
        iconColor: Colors.grey[400]!,
        title:
            'الباقة المجانية — ${status.customersRemaining} زبون متبقي / ${status.invoicesRemaining} فاتورة متبقية هذا الشهر',
        textColor: Colors.white,
        actionWidget: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1), // Primary
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onPressed: () => _navigateToPlans(context),
          child: Text('ترقية',
              style: GoogleFonts.tajawal(color: Colors.white, fontSize: 12)),
        ),
      );
    }

    if (status.currentStatus == 'pending') {
      return _buildBanner(
        context: context,
        color: const Color(0xFFB45309).withOpacity(0.3), // Pending
        icon: Icons.hourglass_bottom,
        iconColor: const Color(0xFFF59E0B),
        title: 'طلبك قيد المراجعة...',
        textColor: Colors.white,
        actionWidget: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFFF59E0B)),
        ),
      );
    }

    if (status.currentStatus == 'expired' || !status.isActive) {
      return _buildBanner(
        context: context,
        color: const Color(0xFFEF4444).withOpacity(0.8), // Red
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.white,
        title: 'انتهى اشتراكك — جدد الآن',
        textColor: Colors.white,
        actionWidget: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white, // White button for red background
            foregroundColor: const Color(0xFFEF4444),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onPressed: () => _navigateToPlans(context),
          child: Text('جدد الآن',
              style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      );
    }

    // Active status
    return Stack(
      children: [
        _buildBanner(
          context: context,
          color: const Color(0xFF22C55E)
              .withOpacity(0.15), // Light transparent green
          icon: Icons.check_circle,
          iconColor: const Color(0xFF22C55E),
          title: 'اشتراك نشط — يتجدد بعد ${status.daysRemaining} يوم',
          textColor: const Color(0xFF22C55E),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBanner({
    required BuildContext context,
    required Color color,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color textColor,
    Widget? actionWidget,
  }) {
    return GestureDetector(
      onTap: () {
        if (actionWidget == null) {
          _navigateToPlans(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            if (actionWidget != null) ...[
              const SizedBox(width: 8),
              actionWidget,
            ]
          ],
        ),
      ),
    );
  }

  void _navigateToPlans(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SubscriptionPlansScreen(),
      ),
    );
  }
}
