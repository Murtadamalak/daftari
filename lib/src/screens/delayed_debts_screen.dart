import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:daftar_debt_manager/src/core/theme/google_fonts_mock.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/providers/app_providers.dart';
import '../core/providers/settings_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/whatsapp_launcher.dart';
import '../data/repositories/customer_repository.dart';

final _amtFmt = NumberFormat('#,###', 'en');
String _fmt(double v) => '${_amtFmt.format(v)} د.ع';

// ── Models & Providers ──

class DelayedCustomerModel {
  final CustomerModel customer;
  final int delayedDays;
  final DateTime? lastPaymentDate;

  DelayedCustomerModel({
    required this.customer,
    required this.delayedDays,
    this.lastPaymentDate,
  });
}

final delayedCustomersProvider = FutureProvider.autoDispose<List<DelayedCustomerModel>>((ref) async {
  final custRepo = ref.watch(customerRepositoryProvider);
  final invRepo = ref.watch(invoiceRepositoryProvider);

  final customers = await custRepo.getCustomersWithDebt();
  if (customers.isEmpty) return [];

  final allInvoices = await invRepo.getAllInvoices();
  final now = DateTime.now();
  final List<DelayedCustomerModel> list = [];

  for (final customer in customers) {
    // Get all invoices for this customer
    final customerInvs = allInvoices.where((i) => i.customerId == customer.id).toList();
    if (customerInvs.isEmpty) continue;

    // Determine last payment date (payType == 'تسديد دين' or paid > 0)
    DateTime? lastPaymentDate;
    for (final inv in customerInvs) {
      final hasPayment = inv.payType == 'تسديد دين' || inv.paid > 0.0001;
      if (hasPayment) {
        if (lastPaymentDate == null || inv.date.isAfter(lastPaymentDate)) {
          lastPaymentDate = inv.date;
        }
      }
    }

    int delayedDays = 0;
    if (lastPaymentDate != null) {
      delayedDays = now.difference(lastPaymentDate).inDays;
    } else {
      // No payments: oldest unpaid invoice date
      DateTime? oldestUnpaidDate;
      for (final inv in customerInvs) {
        final isUnpaidOrPartial = inv.status == 'unpaid' || inv.status == 'partial';
        if (isUnpaidOrPartial) {
          if (oldestUnpaidDate == null || inv.date.isBefore(oldestUnpaidDate)) {
            oldestUnpaidDate = inv.date;
          }
        }
      }
      if (oldestUnpaidDate != null) {
        delayedDays = now.difference(oldestUnpaidDate).inDays;
      } else {
        delayedDays = now.difference(customer.createdAt).inDays;
      }
    }

    if (delayedDays >= 28) {
      list.add(DelayedCustomerModel(
        customer: customer,
        delayedDays: delayedDays,
        lastPaymentDate: lastPaymentDate,
      ));
    }
  }

  // Sort by delayed days descending (longest delay first)
  list.sort((a, b) => b.delayedDays.compareTo(a.delayedDays));
  return list;
});

final delayedSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final filteredDelayedCustomersProvider = Provider.autoDispose<AsyncValue<List<DelayedCustomerModel>>>((ref) {
  final listAsync = ref.watch(delayedCustomersProvider);
  final query = ref.watch(delayedSearchQueryProvider).trim().toLowerCase();

  return listAsync.whenData((list) {
    if (query.isEmpty) return list;
    return list.where((item) {
      final name = item.customer.name.toLowerCase();
      final phone = item.customer.phone?.toLowerCase() ?? '';
      return name.contains(query) || phone.contains(query);
    }).toList();
  });
});

// ── Screen Widget ──

class DelayedDebtsScreen extends ConsumerStatefulWidget {
  const DelayedDebtsScreen({super.key});

  @override
  ConsumerState<DelayedDebtsScreen> createState() => _DelayedDebtsScreenState();
}

class _DelayedDebtsScreenState extends ConsumerState<DelayedDebtsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSendWhatsAppReminder(BuildContext context, CustomerModel customer) async {
    // Show a quick non-blocking loading status dialog to prevent double clicks
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const CircularProgressIndicator(),
        ),
      ),
    );

    try {
      final invoices = await ref.read(invoiceRepositoryProvider).getUnpaidByCustomer(customer.id);
      
      // Close the loading dialog
      if (context.mounted) Navigator.pop(context);

      if (invoices.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لا يوجد فواتير غير مسددة حالياً', style: GoogleFonts.almarai()),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      // Collect all products
      final allItems = <String>{};
      for (final inv in invoices) {
        try {
          final items = await ref.read(invoiceRepositoryProvider).getItemsByInvoiceId(inv.id);
          for (final it in items) {
            allItems.add(it.productName);
          }
        } catch (_) {}
      }

      String productsStr = allItems.join('، ');
      if (productsStr.length > 200) {
        productsStr = '${productsStr.substring(0, 197)}...';
      }
      if (productsStr.isEmpty) productsStr = 'مشتريات سابقة';

      final AppSettings? settings = ref.read(settingsProvider).valueOrNull;
      final String shopName = settings?.shopName ?? 'دفتري';
      final String todayDate = DateFormat('yyyy/MM/dd', 'ar').format(DateTime.now());

      await WhatsAppLauncher.sendReminder(
        phone: customer.phone!,
        customerName: customer.name,
        products: productsStr,
        totalDebt: _fmt(customer.totalDebt),
        date: todayDate,
        shopName: shopName,
      );
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) Navigator.pop(context);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحضير التذكير: $e', style: GoogleFonts.almarai()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(filteredDelayedCustomersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'المستحقين للدفع (28+ يوم)',
          style: GoogleFonts.almarai(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: (isDark ? const Color(0xFF0A1612) : const Color(0xFFF7F5F0)).withOpacity(0.4),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.refresh_outlined,
                  color: isDark ? Colors.white : AppColors.primary,
                  size: 18,
                ),
              ),
              tooltip: 'تحديث',
              onPressed: () {
                ref.invalidate(delayedCustomersProvider);
              },
            ),
          ),
          listAsync.when(
            data: (list) => Padding(
              padding: const EdgeInsets.only(left: 16, right: 4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${list.length} مستحق',
                    style: TextStyle(
                      fontFamily: 'KOMedia',
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0A1612), const Color(0xFF13211D)]
                : [const Color(0xFFF7F5F0), const Color(0xFFEEEBE1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // ── Search Card ──
            Container(
              margin: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + kToolbarHeight - 8,
                16,
                12,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101D1A) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (isDark ? const Color(0xFF1E3C36) : const Color(0xFFD0DCDA)).withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, _) {
                  return TextField(
                    controller: _searchController,
                    onChanged: (v) => ref.read(delayedSearchQueryProvider.notifier).state = v,
                    style: TextStyle(
                      fontFamily: 'KOMedia',
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0A221F),
                    ),
                    decoration: InputDecoration(
                      hintText: 'بحث باسم الزبون المتأخر...',
                      hintStyle: TextStyle(
                        fontFamily: 'KOMedia',
                        fontSize: 13,
                        color: isDark ? const Color(0xFF85AFA7).withOpacity(0.6) : const Color(0xFF9CA3AF),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? const Color(0xFF85AFA7) : const Color(0xFF9CA3AF),
                      ),
                      suffixIcon: value.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: isDark ? const Color(0xFF85AFA7) : const Color(0xFF9CA3AF),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(delayedSearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF162A26) : const Color(0xFFF4F6F5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── List View Content ──
            Expanded(
              child: listAsync.when(
                loading: () => const DelayedListSkeleton(),
                error: (e, _) => Center(child: Text('حدث خطأ: $e', style: GoogleFonts.almarai())),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              size: 72,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'كل الزبائن سددوا خلال الـ 28 يوماً الماضية!',
                            style: GoogleFonts.almarai(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'عمل ممتاز في المتابعة 👍',
                            style: GoogleFonts.almarai(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(delayedCustomersProvider);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return _DelayedCard(
                          item: item,
                          onWhatsApp: () => _handleSendWhatsAppReminder(context, item.customer),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DelayedCard extends StatelessWidget {
  const _DelayedCard({
    required this.item,
    required this.onWhatsApp,
  });

  final DelayedCustomerModel item;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customer = item.customer;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            context.push('/customers/details/${customer.id}');
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning icon badge
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time_filled_rounded,
                        color: AppColors.warning,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Customer details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: GoogleFonts.almarai(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 12,
                                color: isDark ? Colors.white60 : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.lastPaymentDate != null
                                    ? 'آخر تسديد: منذ ${item.delayedDays} يوم'
                                    : 'لم يسدد أبداً: منذ ${item.delayedDays} يوم',
                                style: GoogleFonts.almarai(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Debt amount display
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'الدين الكلي',
                          style: GoogleFonts.almarai(
                            fontSize: 11,
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _fmt(customer.totalDebt),
                          style: GoogleFonts.almarai(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Actions row
                Row(
                  children: [
                    // WhatsApp reminder button (shown if phone exists)
                    if (customer.phone != null && customer.phone!.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onWhatsApp,
                          icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                          label: Text(
                            'تذكير بالواتساب',
                            style: GoogleFonts.almarai(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF25D366),
                            side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'لا يوجد رقم هاتف مسجل',
                            style: GoogleFonts.almarai(
                              fontSize: 12,
                              color: AppColors.textDisabled,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),

                    // View details button
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          context.push('/customers/details/${customer.id}');
                        },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: Text(
                          'عرض وتفاصيل',
                          style: GoogleFonts.almarai(fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Skeleton Widgets for Premium Loading ──

class SkeletonWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonWidget> createState() => _SkeletonWidgetState();
}

class _SkeletonWidgetState extends State<SkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

class DelayedListSkeleton extends StatelessWidget {
  const DelayedListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : AppColors.primary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonWidget(width: 42, height: 42, borderRadius: 21),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonWidget(width: 130, height: 16),
                        const SizedBox(height: 8),
                        const SkeletonWidget(width: 170, height: 12),
                      ],
                    ),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SkeletonWidget(width: 45, height: 10),
                      SizedBox(height: 6),
                      SkeletonWidget(width: 75, height: 16),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Expanded(
                    child: SkeletonWidget(width: double.infinity, height: 38, borderRadius: 12),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: SkeletonWidget(width: double.infinity, height: 38, borderRadius: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
