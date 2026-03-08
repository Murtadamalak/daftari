import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/providers/app_providers.dart';
import '../core/providers/invoice_detail_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/utils/app_snackbar.dart';
import '../core/utils/pdf_invoice_generator.dart';
import '../data/repositories/invoice_repository.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/utils/whatsapp_launcher.dart';

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
        titleTextStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        actions: [
          detail.when(
            data: (d) => Row(
              children: [
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
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('تصدير PDF'),
                          onPressed: () => _exportPdf(context, ref, d),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('مشاركة صورة'),
                          onPressed: () => _shareImage(context),
                        ),
                      ),
                    ],
                  ),
                  if (d.invoice.debt > 0) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const FaIcon(FontAwesomeIcons.whatsapp,
                            color: Colors.white, size: 20),
                        label: const Text('تسديد الدين وإرسال واتساب',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )),
                        onPressed: () =>
                            _showPayDialog(context, ref, d.invoice),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
        shopLogoPath: settings?.logoPath,
      );
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, 'فشل تصدير PDF: $e');
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
                const SizedBox(height: 4),
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
                _TotalRow(label: 'المبلغ المدفوع', value: invoice.paid),
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

          // ── Footer ───────────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: Text(
                'شكراً لتعاملكم معنا 🙏',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic),
              ),
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
