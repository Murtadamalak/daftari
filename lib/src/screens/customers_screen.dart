import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/providers/app_providers.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/whatsapp_launcher.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/invoice_repository.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/widgets/refresh_action_button.dart';

// Formatter for currency
final _amtFmt = NumberFormat('#,###', 'en');
String _fmt(double v) => '${_amtFmt.format(v)} د.ع';

// ── Data and Search Providers ──

final debtSearchDataProvider = FutureProvider.autoDispose((ref) async {
  final custRepo = ref.watch(customerRepositoryProvider);
  final invRepo = ref.watch(invoiceRepositoryProvider);

  final allCustomers = await custRepo.getCustomersWithDebt();
  final unpaidInvoices = await invRepo.getUnpaidInvoices();
  final unpaidIds = unpaidInvoices.map((e) => e.id).toList();
  final unpaidItems = await invRepo.getItemsByInvoiceIds(unpaidIds);

  return (
    customers: allCustomers,
    invoices: unpaidInvoices,
    items: unpaidItems,
  );
});

final debtSearchQueryProvider = StateProvider<String>((ref) => '');

// Provider to watch customers with debt (Filtered)
final customersWithDebtProvider =
    FutureProvider.autoDispose<List<CustomerModel>>((ref) async {
  final data = await ref.watch(debtSearchDataProvider.future);
  final query = ref.watch(debtSearchQueryProvider).trim().toLowerCase();

  if (query.isEmpty) return data.customers;

  return data.customers.where((c) {
    if (c.name.toLowerCase().contains(query)) return true;
    if (c.phone != null && c.phone!.toLowerCase().contains(query)) return true;
    if (c.totalDebt.toString().contains(query)) return true;

    final cInvs = data.invoices.where((i) => i.customerId == c.id);
    for (final inv in cInvs) {
      if (inv.num.toString().contains(query) ||
          inv.formattedNum.toLowerCase().contains(query)) return true;
      final items = data.items.where((it) => it.invoiceId == inv.id);
      if (items.any((it) => it.productName.toLowerCase().contains(query))) {
        return true;
      }
    }

    return false;
  }).toList();
});

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersWithDebtProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الديون (المساجين)'),
        centerTitle: true,
        actions: [
          RefreshActionButton(
            onPressed: () => ref.invalidate(debtSearchDataProvider),
          ),
          customersAsync.when(
            data: (list) => Padding(
              padding: const EdgeInsets.only(left: 8, right: 4),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${list.length} مسجون',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) {
                return TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      ref.read(debtSearchQueryProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم، الباركود، الفاتورة أو المنتج...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(debtSearchQueryProvider.notifier).state =
                                  '';
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('حدث خطأ: $e')),
        data: (customers) {
          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 64, color: AppColors.success),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد ديون مطابقة',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Calculate total outstanding debts
          final totalDebt =
              customers.fold<double>(0, (sum, c) => sum + c.totalDebt);

          return Column(
            children: [
              // Summary Header
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.danger,
                      Color(0xFFB91C1C)
                    ], // Red gradient for debts
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'مجموع الديون المطلوبة',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fmt(totalDebt),
                      style: GoogleFonts.cairo(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Debts List
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return _DebtCard(customer: customer);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DebtCard extends ConsumerWidget {
  const _DebtCard({required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        context.push('/customers/details/${customer.id}');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                color: AppColors.danger,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Middle Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (customer.phone != null && customer.phone!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final invoices = await ref
                            .read(invoiceRepositoryProvider)
                            .getUnpaidByCustomer(customer.id);
                        if (invoices.isEmpty) return;

                        String productsStr = 'مشتريات سابقة';
                        try {
                          final List<InvoiceItemModel> items = await ref
                              .read(invoiceRepositoryProvider)
                              .getItemsByInvoiceId(invoices.first.id);
                          if (items.isNotEmpty) {
                            productsStr = items.first.productName;
                            if (items.length > 1) {
                              productsStr += ' وغيرها';
                            }
                          }
                        } catch (_) {}

                        await WhatsAppLauncher.sendReminder(
                          phone: customer.phone!,
                          customerName: customer.name,
                          products: productsStr,
                          remainingBalance: _fmt(customer.totalDebt),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF25D366), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(FontAwesomeIcons.whatsapp,
                                color: Color(0xFF25D366), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'إرسال تذكير واتساب',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF25D366),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Right Debt amount & View Details button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'المبلغ المطلوب',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _fmt(customer.totalDebt),
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      context.push('/customers/details/${customer.id}'),
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  label: const Text('التفاصيل وتسديد'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 36),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
