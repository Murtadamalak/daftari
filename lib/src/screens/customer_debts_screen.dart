import 'package:daftar_debt_manager/src/core/widgets/app_bar_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daftar_debt_manager/src/core/theme/google_fonts_mock.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/app_providers.dart';
import '../core/providers/settings_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';
import '../core/utils/pdf_payment_receipt_generator.dart';
import '../core/utils/whatsapp_launcher.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/invoice_repository.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/widgets/refresh_action_button.dart';

import '../core/providers/invoices_provider.dart';
import 'customers_screen.dart'; // To invalidate debtSearchDataProvider
import 'delayed_debts_screen.dart';

final _amtFmt = NumberFormat('#,###', 'en');
String _fmt(double v) => '${_amtFmt.format(v)} د.ع';

// Fetch a single customer by id
final customerProvider =
    FutureProvider.autoDispose.family<CustomerModel?, String>((ref, id) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getById(id);
});

// Fetch unpaid invoices for a customer
final customerUnpaidInvoicesProvider = FutureProvider.autoDispose
    .family<List<InvoiceModel>, String>((ref, customerId) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getUnpaidByCustomer(customerId);
});

// Fetch all sales invoices for a customer (excluding payments)
final customerAllInvoicesProvider = FutureProvider.autoDispose
    .family<List<InvoiceModel>, String>((ref, customerId) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getInvoicesByCustomer(customerId);
});

// Fetch payment records for a customer (pay_type == 'تسديد دين')
final customerPaymentsProvider = FutureProvider.autoDispose
    .family<List<InvoiceModel>, String>((ref, customerId) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return repo.getPaymentsByCustomer(customerId);
});

class CustomerDebtsScreen extends ConsumerWidget {
  const CustomerDebtsScreen({super.key, required this.customerId});

  final String customerId;

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

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(customerRepositoryProvider).deleteCustomer(customer.id);
        if (context.mounted) {
          AppSnackBar.success(context, 'تم حذف الزبون بنجاح');
          context.pop();
        }
        ref.invalidate(debtSearchDataProvider);
        ref.invalidate(delayedCustomersProvider);
        ref.invalidate(allInvoicesProvider);
      } catch (e) {
        if (context.mounted) AppSnackBar.error(context, 'فشل الحذف: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerProvider(customerId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A1612) : const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: const AppBarLogo(),
          centerTitle: true,
          actions: [
            RefreshActionButton(
              onPressed: () {
                ref.invalidate(customerProvider(customerId));
                ref.invalidate(customerUnpaidInvoicesProvider(customerId));
                ref.invalidate(customerAllInvoicesProvider(customerId));
                ref.invalidate(customerPaymentsProvider(customerId));
              },
            ),
            customerAsync.when(
              data: (c) => c == null
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDeleteCustomer(context, ref, c),
                      tooltip: 'حذف الزبون',
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        body: customerAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطأ: $e')),
          data: (customer) {
            if (customer == null) {
              return const Center(child: Text('لم يتم العثور على الزبون.'));
            }
  
            return Column(
              children: [
                // Summary Header
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.danger, Color(0xFFB91C1C)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(24),
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
                        customer.name,
                        style: GoogleFonts.almarai(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'الدين الكلي المتبقي',
                        style: GoogleFonts.almarai(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fmt(customer.totalDebt),
                        style: GoogleFonts.almarai(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Main Payment Button
                      if (customer.totalDebt > 0)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () =>
                                _showPayDialog(context, ref, customer),
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('تسديد من الدين الكلي'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.danger,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
  
                // TabBar
                TabBar(
                  labelColor: isDark ? Colors.white : AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: isDark ? Colors.white : AppColors.primary,
                  labelStyle: GoogleFonts.almarai(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.almarai(fontSize: 13),
                  tabs: const [
                    Tab(text: 'المستحقة'),
                    Tab(text: 'كل الفواتير'),
                    Tab(text: 'المدفوعات'),
                  ],
                ),
                const SizedBox(height: 8),
  
                // Tab Views
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildUnpaidInvoicesTab(context, ref, customer),
                      _buildAllInvoicesTab(context, ref, customer),
                      _buildPaymentsTab(context, ref, customer),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUnpaidInvoicesTab(BuildContext context, WidgetRef ref, CustomerModel customer) {
    final invoicesAsync = ref.watch(customerUnpaidInvoicesProvider(customerId));
    return invoicesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (invoices) {
        if (invoices.isEmpty) {
          return Center(
            child: Text(
              'لا يوجد فواتير دين غير مسددة لهذا الزبون',
              style: GoogleFonts.almarai(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: invoices.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final inv = invoices[index];
            return _buildInvoiceRow(context, ref, customer, inv, isUnpaidOnly: true);
          },
        );
      },
    );
  }

  Widget _buildAllInvoicesTab(BuildContext context, WidgetRef ref, CustomerModel customer) {
    final invoicesAsync = ref.watch(customerAllInvoicesProvider(customerId));
    return invoicesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (invoices) {
        if (invoices.isEmpty) {
          return Center(
            child: Text(
              'لا توجد فواتير مبيعات لهذا الزبون',
              style: GoogleFonts.almarai(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: invoices.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final inv = invoices[index];
            return _buildInvoiceRow(context, ref, customer, inv, isUnpaidOnly: false);
          },
        );
      },
    );
  }

  Widget _buildInvoiceRow(BuildContext context, WidgetRef ref, CustomerModel customer, InvoiceModel inv, {required bool isUnpaidOnly}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    ({String label, Color color}) statusInfo;
    switch (inv.status) {
      case 'paid':
        statusInfo = (label: 'مسدد', color: const Color(0xFF43A047));
        break;
      case 'partial':
        statusInfo = (label: 'جزئي', color: const Color(0xFFFB8C00));
        break;
      case 'unpaid':
      default:
        statusInfo = (label: 'دين', color: const Color(0xFFE53935));
        break;
    }

    return InkWell(
      onTap: () => context.push('/invoices/details/${inv.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.receipt_long,
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'فاتورة رقم ${inv.formattedNum}',
                        style: GoogleFonts.almarai(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusInfo.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusInfo.color.withOpacity(0.3), width: 1),
                        ),
                        child: Text(
                          statusInfo.label,
                          style: GoogleFonts.almarai(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusInfo.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('yyyy/MM/dd HH:mm').format(inv.date),
                    style: GoogleFonts.almarai(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (customer.phone != null && customer.phone!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 18),
                  onPressed: () async {
                    final allItems = <String>{};
                    try {
                      final items = await ref
                          .read(invoiceRepositoryProvider)
                          .getItemsByInvoiceId(inv.id);
                      for (final it in items) {
                        allItems.add(it.productName);
                      }
                    } catch (_) {}
                    String productsStr = allItems.join('، ');
                    if (productsStr.length > 200) {
                      productsStr = '${productsStr.substring(0, 197)}...';
                    }
                    if (productsStr.isEmpty) productsStr = 'مشتريات سابقة';

                    final String todayDate = DateFormat('yyyy/MM/dd', 'ar').format(DateTime.now());
                    await WhatsAppLauncher.sendReminder(
                      phone: customer.phone!,
                      customerName: customer.name,
                      products: productsStr,
                      totalDebt: _fmt(inv.debt),
                      date: todayDate,
                      shopName: inv.shopName,
                    );
                  },
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _confirmDeleteInvoice(context, ref, inv),
              tooltip: 'حذف الفاتورة',
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isUnpaidOnly ? 'مبلغ الدين' : 'الإجمالي',
                  style: GoogleFonts.almarai(
                    fontSize: 11,
                    color: isUnpaidOnly ? AppColors.danger : (isDark ? Colors.white60 : Colors.grey.shade600),
                  ),
                ),
                Text(
                  _fmt(isUnpaidOnly ? inv.debt : inv.grandTotal),
                  style: GoogleFonts.almarai(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isUnpaidOnly ? AppColors.danger : (isDark ? Colors.white : Colors.black),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsTab(BuildContext context, WidgetRef ref, CustomerModel customer) {
    final paymentsAsync = ref.watch(customerPaymentsProvider(customerId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return paymentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (payments) {
        if (payments.isEmpty) {
          return Center(
            child: Text(
              'لم يتم تسجيل أي دفعات تسديد لهذا الزبون',
              style: GoogleFonts.almarai(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: payments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final payment = payments[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Theme.of(context).colorScheme.outline.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.payType == 'تسديد دين'
                              ? (payment.note ?? 'دفعة تسديد')
                              : 'دفعة أولى - فاتورة رقم ${payment.formattedNum}',
                          style: GoogleFonts.almarai(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('yyyy/MM/dd HH:mm').format(payment.date),
                          style: GoogleFonts.almarai(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.print_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                    tooltip: 'طباعة الوصل',
                    onPressed: () async {
                      final settings = ref.read(settingsProvider).valueOrNull;
                      await PdfPaymentReceiptGenerator.generateAndShare(
                        customerName: customer.name,
                        amountPaid: payment.paid,
                        shopName: settings?.shopName ?? 'مبيعات المحل',
                        shopLogoPath: settings?.logoPath,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _confirmDeleteInvoice(context, ref, payment),
                    tooltip: payment.payType == 'تسديد دين' ? 'حذف الدفعة' : 'حذف الفاتورة',
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'المبلغ المسدد',
                        style: GoogleFonts.almarai(
                          fontSize: 11,
                          color: const Color(0xFF43A047),
                        ),
                      ),
                      Text(
                        _fmt(payment.paid),
                        style: GoogleFonts.almarai(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF43A047),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPayDialog(
      BuildContext context, WidgetRef ref, CustomerModel customer,
      {double? preferAmount}) async {
    final amountController =
        TextEditingController(text: preferAmount?.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تسديد دين لـ: ${customer.name}',
          style: GoogleFonts.almarai(fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الدين الكلي: ${_fmt(customer.totalDebt)}',
                style: GoogleFonts.almarai(
                  color: AppColors.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المبلغ المستلم',
                  prefixText: 'د.ع ',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'الرجاء إدخال المبلغ';
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) return 'مبلغ غير صالح';
                  if (parsed > customer.totalDebt) {
                    return 'المبلغ أكبر من الدين الكلي!';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('وصل سحب'),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final amount = double.parse(amountController.text.trim());
                      try {
                        await ref
                            .read(invoiceRepositoryProvider)
                            .payCustomerDebt(
                                customerId: customer.id, amountPaid: amount);

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          AppSnackBar.success(context, 'تم التسديد بنجاح');
                        }

                        ref.invalidate(customerProvider(customer.id));
                        ref.invalidate(customerUnpaidInvoicesProvider(customer.id));
                        ref.invalidate(customerAllInvoicesProvider(customer.id));
                        ref.invalidate(customerPaymentsProvider(customer.id));
                        ref.invalidate(debtSearchDataProvider);
                        ref.invalidate(delayedCustomersProvider);
                        ref.invalidate(allInvoicesProvider);

                        final settings = ref.read(settingsProvider).valueOrNull;
                        await PdfPaymentReceiptGenerator.generateAndShare(
                          customerName: customer.name,
                          amountPaid: amount,
                          shopName: settings?.shopName ?? 'مبيعات المحل',
                          shopLogoPath: settings?.logoPath,
                        );
                      } catch (e) {
                        if (ctx.mounted) {
                          AppSnackBar.error(context, 'خطأ: $e');
                        }
                      }
                    }
                  },
                ),
              ),
              if (customer.phone != null && customer.phone!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final amount =
                            double.parse(amountController.text.trim());
                        try {
                          await ref
                              .read(invoiceRepositoryProvider)
                              .payCustomerDebt(
                                  customerId: customer.id, amountPaid: amount);

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            AppSnackBar.success(context, 'تم التسديد بنجاح');
                          }

                          ref.invalidate(customerProvider(customer.id));
                         ref.invalidate(customerUnpaidInvoicesProvider(customer.id));
                         ref.invalidate(customerAllInvoicesProvider(customer.id));
                         ref.invalidate(customerPaymentsProvider(customer.id));
                         ref.invalidate(debtSearchDataProvider);
                         ref.invalidate(delayedCustomersProvider);
                         ref.invalidate(allInvoicesProvider);

                          // Send WhatsApp Receipt
                          await WhatsAppLauncher.sendPaymentReceipt(
                            phone: customer.phone!,
                            customerName: customer.name,
                            amountPaid: amount.toString(),
                            remainingBalance: _fmt(customer.totalDebt - amount),
                          );
                        } catch (e) {
                          if (ctx.mounted) {
                            AppSnackBar.error(context, 'خطأ: $e');
                          }
                        }
                      }
                    },
                    icon: const FaIcon(FontAwesomeIcons.whatsapp,
                        color: Colors.white, size: 18),
                    label: const Text('واتساب'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteInvoice(
      BuildContext context, WidgetRef ref, InvoiceModel invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الفاتورة'),
        content: const Text(
            'هل أنت متأكد من حذف هذه الفاتورة؟ سيتم مسح البيانات ولا يمكن التراجع.'),
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

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(invoiceRepositoryProvider).deleteInvoice(invoice.id);
        if (context.mounted) {
          AppSnackBar.success(context, 'تم حذف الفاتورة بنجاح');
        }
        ref.invalidate(customerProvider(customerId));
        ref.invalidate(customerUnpaidInvoicesProvider(customerId));
        ref.invalidate(customerAllInvoicesProvider(customerId));
        ref.invalidate(customerPaymentsProvider(customerId));
        ref.invalidate(allInvoicesProvider);
        ref.invalidate(debtSearchDataProvider);
        ref.invalidate(delayedCustomersProvider);
      } catch (e) {
        if (context.mounted) AppSnackBar.error(context, 'فشل الحذف: $e');
      }
    }
  }
}
