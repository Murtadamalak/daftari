import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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

class CustomerDebtsScreen extends ConsumerWidget {
  const CustomerDebtsScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerProvider(customerId));
    final invoicesAsync = ref.watch(customerUnpaidInvoicesProvider(customerId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('تفاصيل الديون والتسديد'),
        centerTitle: true,
        actions: [
          RefreshActionButton(
            onPressed: () {
              ref.invalidate(customerProvider(customerId));
              ref.invalidate(customerUnpaidInvoicesProvider(customerId));
            },
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
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'الدين الكلي المتبقي',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fmt(customer.totalDebt),
                      style: GoogleFonts.cairo(
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

              // Title for invoices
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'الفواتير غير المسددة',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),

              // Invoices List
              Expanded(
                child: invoicesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('خطأ: $e')),
                  data: (invoices) {
                    if (invoices.isEmpty) {
                      return Center(
                        child: Text(
                          'لا يوجد فواتير دين لهذا الزبون',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: invoices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final inv = invoices[index];
                        return InkWell(
                          onTap: () => _showPayDialog(context, ref, customer,
                              preferAmount: inv.debt),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.receipt_long,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'فاتورة رقم ${inv.formattedNum}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('yyyy/MM/dd HH:mm')
                                            .format(inv.date),
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (customer.phone != null &&
                                    customer.phone!.isNotEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 12),
                                    child: FaIcon(FontAwesomeIcons.whatsapp,
                                        color: Color(0xFF25D366), size: 18),
                                  ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'مبلغ الدين',
                                      style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                    Text(
                                      _fmt(inv.debt),
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showPayDialog(
      BuildContext context, WidgetRef ref, CustomerModel customer,
      {double? preferAmount}) async {
    final amountController =
        TextEditingController(text: preferAmount?.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تسديد دين لـ: ${customer.name}',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الدين الكلي: ${_fmt(customer.totalDebt)}',
                style: GoogleFonts.cairo(
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
                  if (parsed > customer.totalDebt)
                    return 'المبلغ أكبر من الدين الكلي!';
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
                        ref.invalidate(
                            customerUnpaidInvoicesProvider(customer.id));

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
                          ref.invalidate(
                              customerUnpaidInvoicesProvider(customer.id));

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
}
