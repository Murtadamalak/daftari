import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/providers/app_providers.dart';
import '../core/providers/settings_provider.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/whatsapp_launcher.dart';
import '../core/utils/pdf_debt_report_generator.dart';
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
        title: const Text('سجل الديون (الزبائن)'),
        centerTitle: true,
        actions: [
          RefreshActionButton(
            onPressed: () => ref.invalidate(debtSearchDataProvider),
          ),
          // Print Report Button
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () async {
              // Workaround for Flutter Web mouse_tracker crash with tooltips/dialogs
              await Future<void>.delayed(const Duration(milliseconds: 50));
              if (context.mounted) _handlePrintReport(context, ref);
            },
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
                    '${list.length} زبون',
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
                    style: GoogleFonts.almarai(
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
                      style: GoogleFonts.almarai(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fmt(totalDebt),
                      style: GoogleFonts.almarai(
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

  // ─────────────────────────────────────────────────────────────────────────
  // Print Report
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _handlePrintReport(BuildContext context, WidgetRef ref) async {
    // 1. اختيار الشهر
    final now = DateTime.now();
    DateTime selectedMonth = DateTime(now.year, now.month);

    final chosen = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => _MonthPickerDialog(initial: selectedMonth),
    );
    if (chosen == null || !context.mounted) return;
    selectedMonth = chosen;

    // Workaround for Flutter Web: wait a frame before showing the next dialog
    // to prevent MouseTracker assertion crashes after popping the previous dialog.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!context.mounted) return;

    // 2. عرض مؤشر التحميل
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primary)),
            const SizedBox(height: 24),
            Text('جاري إعداد التقرير...',
                style: GoogleFonts.almarai(
                    fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            Text('يرجى الانتظار',
                style: GoogleFonts.almarai(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );

    try {
      // 3. جلب البيانات
      final custRepo = ref.read(customerRepositoryProvider);
      final invRepo = ref.read(invoiceRepositoryProvider);

      final allCustomers = await custRepo.getAllCustomers();
      final allInvoices = await invRepo.getAllInvoices();

      // جلب جميع بنود الفواتير
      final allIds = allInvoices.map((i) => i.id).toList();
      final allItems = allIds.isEmpty
          ? <InvoiceItemModel>[]
          : await invRepo.getItemsByInvoiceIds(allIds);

      // 4. بناء الملخص
      final settings = ref.read(settingsProvider).valueOrNull;
      final summary = await PdfDebtReportGenerator.buildSummary(
        customers: allCustomers,
        allInvoices: allInvoices,
        allItems: allItems,
        forMonth: selectedMonth,
      );

      // 5. توليد PDF ومشاركته
      await PdfDebtReportGenerator.generateAndShare(
        summary: summary,
        shopName: settings?.shopName,
        ownerName: settings?.ownerName,
        shopPhone: settings?.shopPhone,
        shopLogoPath: settings?.logoPath,
      );

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('فشل إنشاء التقرير: $e', style: GoogleFonts.almarai()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
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
      onLongPress: () => _editCustomer(context, ref, customer),
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
                    style: GoogleFonts.almarai(
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

                        // Collect all products from all invoices
                        final allItems = <String>{};
                        for (final inv in invoices) {
                          try {
                            final items = await ref
                                .read(invoiceRepositoryProvider)
                                .getItemsByInvoiceId(inv.id);
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

                        final AppSettings? settings =
                            ref.read(settingsProvider).valueOrNull;
                        final String shopName = settings?.shopName ?? 'دفتري';
                        final String todayDate = DateFormat('yyyy/MM/dd', 'ar')
                            .format(DateTime.now());

                        await WhatsAppLauncher.sendReminder(
                          phone: customer.phone!,
                          customerName: customer.name,
                          products: productsStr,
                          totalDebt: _fmt(customer.totalDebt),
                          date: todayDate,
                          shopName: shopName,
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
                              'تذكير',
                              style: GoogleFonts.almarai(
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
                      onPressed: () =>
                          _confirmDeleteCustomer(context, ref, customer),
                      tooltip: 'حذف الزبون',
                    ),
                    Text(
                      'المبلغ المطلوب',
                      style: GoogleFonts.almarai(
                        fontSize: 11,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  _fmt(customer.totalDebt),
                  style: GoogleFonts.almarai(
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

  Future<void> _editCustomer(
      BuildContext context, WidgetRef ref, CustomerModel customer) async {
    final nameCtrl = TextEditingController(text: customer.name);
    final phoneCtrl = TextEditingController(text: customer.phone ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل بيانات الزبون'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم الزبون',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حفظ التعديلات'),
          ),
        ],
      ),
    );

    if (result == true) {
      final newName = nameCtrl.text.trim();
      final newPhone = phoneCtrl.text.trim();

      if (newName.isNotEmpty) {
        final repo = ref.read(customerRepositoryProvider);
        await repo.upsertCustomer(
          id: customer.id,
          name: newName,
          phone: newPhone.isEmpty ? null : newPhone,
          totalDebt: customer.totalDebt,
        );
        ref.invalidate(debtSearchDataProvider);
      }
    }
    nameCtrl.dispose();
    phoneCtrl.dispose();
  }

  Future<void> _confirmDeleteCustomer(
      BuildContext context, WidgetRef ref, CustomerModel customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الزبون'),
        content: Text(
            'هل أنت متأكد من حذف الزبون "${customer.name}"؟ سيتم حذف جميع بياناته المرتبطة ولن تظهر ديونه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف الآن'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(customerRepositoryProvider);
      await repo.deleteCustomer(customer.id);
      ref.invalidate(debtSearchDataProvider);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Month Picker Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({required this.initial});
  final DateTime initial;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;
  late int _month;

  static const _monthNames = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
    _month = widget.initial.month;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'اختر الشهر للتقرير',
        style: GoogleFonts.almarai(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Year selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _year--),
                ),
                Text(
                  '$_year',
                  style: GoogleFonts.almarai(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _year < DateTime.now().year
                      ? () => setState(() => _year++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Month grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (ctx, i) {
                final m = i + 1;
                final isSelected = m == _month;
                final isFuture =
                    _year == DateTime.now().year && m > DateTime.now().month;
                return GestureDetector(
                  onTap: isFuture ? null : () => setState(() => _month = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isFuture
                              ? Colors.grey.shade100
                              : AppColors.primary.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        _monthNames[i],
                        style: GoogleFonts.almarai(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : (isFuture
                                  ? Colors.grey.shade400
                                  : AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: GoogleFonts.almarai()),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.print_outlined, size: 18),
          label: Text(
            'طباعة ${_monthNames[_month - 1]} $_year',
            style: GoogleFonts.almarai(fontWeight: FontWeight.bold),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          onPressed: () => Navigator.pop(context, DateTime(_year, _month)),
        ),
      ],
    );
  }
}
