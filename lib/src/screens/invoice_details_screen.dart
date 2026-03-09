import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/providers/app_providers.dart';
import '../core/providers/invoice_detail_provider.dart';
import '../core/providers/invoices_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/utils/app_snackbar.dart';
import '../core/utils/pdf_invoice_generator.dart';
import '../data/repositories/invoice_repository.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/utils/whatsapp_launcher.dart';
import '../core/theme/app_theme.dart';

class InvoiceDetailsScreen extends ConsumerWidget {
  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  final String invoiceId;

  // Global key used to capture the receipt widget as an image
  static final GlobalKey _receiptKey = GlobalKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(invoiceDetailProvider(invoiceId));

    return Scaffold(
      backgroundColor: Colors.transparent, // rely on body container gradient
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: detail.when(
          data: (d) => Text('فاتورة رقم ${d.invoice.formattedNum}'),
          loading: () => const Text('جاري التحميل...'),
          error: (_, __) => const Text('خطأ'),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.almarai(
            fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        actions: [
          detail.when(
            data: (d) => Row(
              children: [
                IconButton(
                  tooltip: 'حذف الفاتورة',
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: () => _confirmDelete(context, ref, d.invoice),
                ),
                IconButton(
                  tooltip: 'تصدير PDF',
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: () => _exportPdf(context, ref, d),
                ),
                IconButton(
                  tooltip: 'مشاركة صورة',
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _shareImage(context),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
                : [const Color(0xFF4F46E5), const Color(0xFF818CF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: detail.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white)),
            error: (e, _) => Center(
                child: Text('خطأ: $e',
                    style: const TextStyle(color: Colors.white))),
            data: (d) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ─── The receipt card captured for sharing ───
                  RepaintBoundary(
                    key: _receiptKey,
                    child: _ReceiptCard(invoice: d.invoice, items: d.items),
                  ),
                  const SizedBox(height: 24),
                  // ─── Action buttons ───
                  // ─── Main Action Row ──────────────────────────────────────────────
                  Row(
                    children: [
                      // 1. WhatsApp Button
                      Expanded(
                        child: _ActionBtn(
                          icon: FontAwesomeIcons.whatsapp,
                          label: 'واتساب',
                          color: const Color(0xFF25D366),
                          onPressed: () =>
                              _sendInvoiceWhatsApp(context, ref, d),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 2. Print/PDF Button
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.print_outlined,
                          label: 'طبع / PDF',
                          color: const Color(0xFF6366F1),
                          onPressed: () => _exportPdf(context, ref, d),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 3. Share Image Button
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.share_outlined,
                          label: 'مشاركة صوره',
                          color: Colors.orange,
                          onPressed: () => _shareImage(context),
                        ),
                      ),
                    ],
                  ),

                  if (d.invoice.debt > 0) ...[
                    const SizedBox(height: 12),
                    // 4. Pay Button (Big & Prominent)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                        icon: const Icon(Icons.payments_outlined, size: 24),
                        label: const Text('تسديد هذا الدين',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                        onPressed: () =>
                            _showPayDialog(context, ref, d.invoice),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),

                  // Delete button at bottom
                  TextButton.icon(
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.white70),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text('حذف هذه الفاتورة نهائياً'),
                    onPressed: () => _confirmDelete(context, ref, d.invoice),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendInvoiceWhatsApp(
      BuildContext context, WidgetRef ref, InvoiceDetail d) async {
    final phone = d.invoice.customerPhone;
    if (phone == null || phone.isEmpty) {
      if (context.mounted) {
        AppSnackBar.error(context, 'لا يوجد رقم هاتف للعميل');
      }
      return;
    }

    try {
      final invRepo = ref.read(invoiceRepositoryProvider);
      final custRepo = ref.read(customerRepositoryProvider);
      final customerId = d.invoice.customerId;

      Set<String> allItems = <String>{};
      double totalDebtVal = d.invoice.debt;

      if (customerId != null && customerId.isNotEmpty) {
        // Fetch all unpaid invoices for this customer to sum up everything
        final allUnpaid = await invRepo.getUnpaidByCustomer(customerId);
        final customer = await custRepo.getById(customerId);

        for (final inv in allUnpaid) {
          final items = await invRepo.getItemsByInvoiceId(inv.id);
          for (final it in items) {
            allItems.add(it.productName);
          }
        }
        if (customer != null) {
          totalDebtVal = customer.totalDebt;
        }
      }

      // Fallback: If no other items found (or no customerId), use current invoice's items
      if (allItems.isEmpty) {
        allItems = d.items.map((e) => e.productName).toSet();
      }

      String productsStr = allItems.join(' - ');
      if (productsStr.length > 250) {
        productsStr = '${productsStr.substring(0, 247)}...';
      }
      if (productsStr.isEmpty) productsStr = 'مشتريات متنوعة';

      final settings = ref.read(settingsProvider).valueOrNull;

      await WhatsAppLauncher.sendReminder(
        phone: phone,
        customerName: d.invoice.customerName,
        products: productsStr,
        totalDebt: NumberFormat('#,###').format(totalDebtVal),
        date: DateFormat('yyyy/MM/dd').format(DateTime.now()),
        shopName: settings?.shopName ?? d.invoice.shopName,
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, 'خطأ في إرسال واتساب: $e');
      }
    }
  }

  // ─── Share as image ──────────────────────────────────────────────────────────
  Future<void> _shareImage(BuildContext context) async {
    try {
      final boundary = _receiptKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      if (kIsWeb) {
        await Share.shareXFiles(
          [
            XFile.fromData(bytes,
                mimeType: 'image/png', name: 'receipt_$invoiceId.png')
          ],
          text: 'وصل فاتورة رقم $invoiceId',
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/receipt_$invoiceId.png');
        await file.writeAsBytes(bytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'وصل فاتورة رقم $invoiceId',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل التصدير: $e')));
      }
    }
  }

  // ─── Export as PDF (Professional with branding) ──────────────────────────────────
  Future<void> _exportPdf(
      BuildContext context, WidgetRef ref, InvoiceDetail d) async {
    try {
      final settings = ref.read(settingsProvider).valueOrNull;
      await PdfInvoiceGenerator.generateAndShare(
        invoice: d.invoice,
        items: d.items,
        invoiceId: d.invoice.formattedNum,
        shopName: settings?.shopName,
        ownerName: settings?.ownerName,
        shopPhone: settings?.shopPhone,
        shopLogoPath: settings?.logoPath,
      );
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, 'فشل تصدير PDF: $e');
    }
  }

  Future<void> _confirmDelete(
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
          context.pop(); // Go back to list
        }
        ref.invalidate(allInvoicesProvider);
      } catch (e) {
        if (context.mounted) AppSnackBar.error(context, 'فشل الحذف: $e');
      }
    }
  }

  Future<void> _showPayDialog(
      BuildContext context, WidgetRef ref, InvoiceModel invoice) async {
    final amountController =
        TextEditingController(text: invoice.debt.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسديد دين الفاتورة'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'المبلغ المتبقي: ${NumberFormat('#,###').format(invoice.debt)} د.ع',
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
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
                  if (parsed > invoice.debt) return 'المبلغ أكبر من الدين!';
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
          FilledButton.icon(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final amount = double.parse(amountController.text.trim());
                try {
                  await ref.read(invoiceRepositoryProvider).payInvoiceDebt(
                      invoiceId: invoice.id, amountPaid: amount);

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    AppSnackBar.success(context, 'تم التسديد بنجاح');
                  }

                  // Refresh detail
                  ref.invalidate(invoiceDetailProvider(invoice.id));

                  if (invoice.customerPhone != null) {
                    await WhatsAppLauncher.sendPaymentReceipt(
                      phone: invoice.customerPhone!,
                      customerName: invoice.customerName,
                      amountPaid: amount.toString(),
                      remainingBalance:
                          NumberFormat('#,###').format(invoice.debt - amount),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    AppSnackBar.error(context, 'خطأ: $e');
                  }
                }
              }
            },
            icon: const FaIcon(FontAwesomeIcons.whatsapp,
                color: Colors.white, size: 18),
            label: const Text('تسديد وإرسال واتساب'),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Receipt Card Widget  ─  the "real receipt" design shown on screen
// ─────────────────────────────────────────────────────────────────────────────

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.invoice, required this.items});

  final InvoiceModel invoice;
  final List<InvoiceItemModel> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF4F46E5), const Color(0xFF312E81)]
                    : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              children: [
                Text(
                  invoice.shopName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                if (invoice.ownerName != null)
                  Text(
                    'بإدارة: ${invoice.ownerName}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                if (invoice.shopPhone != null)
                  Text(
                    'هاتف: ${invoice.shopPhone}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                const SizedBox(height: 8),
                Text(
                  'فاتورة رقم: ${invoice.formattedNum}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85), fontSize: 13),
                ),
                Text(
                  DateFormat('yyyy/MM/dd  hh:mm a', 'ar').format(invoice.date),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75), fontSize: 11),
                ),
              ],
            ),
          ),

          // ── Customer info ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  invoice.customerName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (invoice.customerPhone != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '• ${invoice.customerPhone}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ]
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: _DashedDivider(),
          ),

          // ── Items table header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: const [
                Expanded(flex: 4, child: _ColHeader('المنتج')),
                Expanded(flex: 1, child: _ColHeader('الكمية', center: true)),
                Expanded(flex: 2, child: _ColHeader('السعر', center: true)),
                Expanded(flex: 2, child: _ColHeader('الإجمالي', center: true)),
              ],
            ),
          ),
          const Divider(height: 8, indent: 20, endIndent: 20),

          // ── Items rows ───────────────────────────────────────────────────────
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                        Text(
                          item.priceType == 'wholesale' ? 'جملة' : 'مفرد',
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      _fmtQty(item.qty),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _fmtAmt(item.unitPrice),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _fmtAmt(item.total),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: _DashedDivider(),
          ),

          // ── Totals ───────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _TotalRow(label: 'الإجمالي الفرعي', value: invoice.subtotal),
                if (invoice.discount > 0)
                  _TotalRow(
                    label: 'الخصم',
                    value: -invoice.discount,
                    valueColor: Colors.orange.shade700,
                  ),
                const Divider(height: 16),
                _TotalRow(
                  label: 'الإجمالي النهائي',
                  value: invoice.grandTotal,
                  bold: true,
                  fontSize: 16,
                ),
                const SizedBox(height: 6),
                _TotalRow(label: 'المبلغ المدفوع', value: invoice.currentPaid),
                if (invoice.debt > 0)
                  _TotalRow(
                    label: 'المبلغ المتبقي (دين)',
                    value: invoice.debt,
                    valueColor: Colors.red.shade600,
                    bold: true,
                  ),
              ],
            ),
          ),

          // ── Status badge ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PayTypeBadge(invoice.payType),
                _StatusBadge(invoice.status),
              ],
            ),
          ),

          // ── Notes (If any) ───────────────────────────────────────────────────
          if (invoice.note != null && invoice.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ملاحظات:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(invoice.note!, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),

          Container(
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'شكراً لتعاملكم معنا 🙏',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'برمجة وتطوير: مرتضى علاء | مكتب فن للتصميم والبرمجة',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.almarai(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.grey.shade800,
                  ),
                ),
                Text(
                  'هاتف: 07876007620 - 07813938267',
                  style: GoogleFonts.almarai(
                    fontSize: 9,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '© 2026 جميع الحقوق محفوظة ',
                  style: GoogleFonts.almarai(
                    fontSize: 8,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtAmt(double v) =>
      '${NumberFormat('#,##0', 'en').format(v)} IQD';

  static String _fmtQty(double v) =>
      v == v.truncate() ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ColHeader extends StatelessWidget {
  const _ColHeader(this.text, {this.center = false});
  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.fontSize = 14,
    this.valueColor,
  });
  final String label;
  final double value;
  final bool bold;
  final double fontSize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    final valueStyle = style.copyWith(color: valueColor);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            '${value < 0 ? '-' : ''}${NumberFormat('#,##0', 'en').format(value.abs())} IQD',
            style: valueStyle,
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Container(
              width: dashWidth,
              height: 1,
              margin: const EdgeInsets.only(right: dashSpace),
              color: Colors.grey.shade300,
            ),
          ),
        );
      },
    );
  }
}

class _PayTypeBadge extends StatelessWidget {
  const _PayTypeBadge(this.type);
  final String type;

  @override
  Widget build(BuildContext context) {
    final labels = {'cash': 'نقدي', 'debt': 'آجل', 'partial': 'جزئي'};
    final colors = {
      'cash': Colors.green,
      'debt': Colors.red,
      'partial': Colors.orange,
    };
    final color = colors[type] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(labels[type] ?? type,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final labels = {'paid': 'مدفوع', 'unpaid': 'غير مدفوع', 'partial': 'جزئي'};
    final colors = {
      'paid': Colors.green,
      'unpaid': Colors.red,
      'partial': Colors.orange,
    };
    final color = colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(labels[status] ?? status,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.almarai(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
