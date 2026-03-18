import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/invoice_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _cairoRegPath = 'assets/fonts/Cairo-Regular.ttf';
const _cairoBoldPath = 'assets/fonts/Cairo-Bold.ttf';

const _devCredit =
    'برمجة وتطوير: المبرمج مرتضى علاء | مكتب فن للتصميم والبرمجة';
const _devPhone = '07876007620  -  07813938267';
const _copyright = '© 2026 جميع الحقوق محفوظة - مكتب فن للتصميم والبرمجة';

// ─────────────────────────────────────────────────────────────────────────────
// Model: بيانات صف الزبون الكاملة للتقرير
// ─────────────────────────────────────────────────────────────────────────────

class CustomerDebtRow {
  final CustomerModel customer;
  final double totalPurchased; // مجموع ما اشتراه
  final double totalPaid; // مجموع ما دفعه
  final double remaining; // الدين المتبقي
  final DateTime? lastPurchaseDate; // تاريخ آخر فاتورة
  final DateTime? lastPaymentDate; // تاريخ آخر تسديد
  final int invoiceCount; // عدد الفواتير

  const CustomerDebtRow({
    required this.customer,
    required this.totalPurchased,
    required this.totalPaid,
    required this.remaining,
    this.lastPurchaseDate,
    this.lastPaymentDate,
    required this.invoiceCount,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Model: ملخص التقرير
// ─────────────────────────────────────────────────────────────────────────────

class DebtReportSummary {
  final int totalDebtors; // عدد المديونين
  final double totalDebt; // الدين الكلي
  final double monthlyIncoming; // الواصل هذا الشهر
  final int invoiceCount; // عدد الفواتير
  final int productsSoldCount; // عدد المنتجات المباعة (وحدات)
  final List<CustomerDebtRow> rows;
  final String monthLabel; // اسم الشهر عربي
  final String year;

  const DebtReportSummary({
    required this.totalDebtors,
    required this.totalDebt,
    required this.monthlyIncoming,
    required this.invoiceCount,
    required this.productsSoldCount,
    required this.rows,
    required this.monthLabel,
    required this.year,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Generator
// ─────────────────────────────────────────────────────────────────────────────

class PdfDebtReportGenerator {
  PdfDebtReportGenerator._();

  static final _amtFmt = NumberFormat('#,##0', 'en');
  static String _fmt(double v) => '${_amtFmt.format(v)} د.ع';
  static String _fmtDate(DateTime? d) =>
      d == null ? '-' : DateFormat('yyyy/MM/dd').format(d);

  static final _primaryColor = const PdfColor.fromInt(0xFF1A3C6E);
  static final _accentGreen = PdfColors.green700;
  static final _accentRed = PdfColors.red700;
  static final _accentOrange = PdfColors.orange700;
  static final _lightBg = const PdfColor.fromInt(0xFFF0F4FA);

  // ── Arabic month names ────────────────────────────────────────────────────
  static const _arabicMonths = [
    '',
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

  // ── Load fonts ────────────────────────────────────────────────────────────
  static Future<pw.Font> _font(String path) async {
    final data = await rootBundle.load(path);
    return pw.Font.ttf(data);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build summary from raw data
  // ─────────────────────────────────────────────────────────────────────────

  /// يبني [DebtReportSummary] من البيانات الخام
  static Future<DebtReportSummary> buildSummary({
    required List<CustomerModel> customers,
    required List<InvoiceModel> allInvoices,
    required List<InvoiceItemModel> allItems,
    required DateTime forMonth, // أي شهر تريد (يأخذ السنة والشهر فقط)
  }) async {
    final monthStart = DateTime(forMonth.year, forMonth.month, 1);
    final monthEnd = DateTime(forMonth.year, forMonth.month + 1, 1);

    // فواتير الشهر المحدد
    final monthInvoices = allInvoices
        .where((inv) =>
            inv.date.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
            inv.date.isBefore(monthEnd))
        .toList();

    // الواصل هذا الشهر (تسديدات + مبالغ نقدية)
    double monthlyIncoming = 0;
    for (final inv in monthInvoices) {
      if (inv.payType == 'تسديد دين') {
        monthlyIncoming += inv.paid;
      } else {
        monthlyIncoming += inv.paid; // المدفوع عند الشراء
      }
    }

    // عدد وحدات المنتجات المباعة هذا الشهر
    final monthInvoiceIds = <String>{};
    for (final inv in monthInvoices) {
      if (inv.payType != 'تسديد دين') monthInvoiceIds.add(inv.id);
    }
    int productsSoldCount = 0;
    for (final item in allItems) {
      if (monthInvoiceIds.contains(item.invoiceId)) {
        productsSoldCount += item.qty.toInt();
      }
    }

    // بناء صفوف الزبائن
    final rows = <CustomerDebtRow>[];
    for (final cust in customers) {
      if (cust.totalDebt <= 0) continue; // فقط المديونون

      final custInvoices = allInvoices
          .where(
              (inv) => inv.customerId == cust.id && inv.payType != 'تسديد دين')
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      final custPayments = allInvoices
          .where(
              (inv) => inv.customerId == cust.id && inv.payType == 'تسديد دين')
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      double totalPurchased = 0;
      for (final inv in custInvoices) {
        totalPurchased += inv.grandTotal;
      }

      double totalPaid = 0;
      for (final inv in custInvoices) {
        totalPaid += inv.paid;
      }
      for (final pay in custPayments) {
        totalPaid += pay.paid;
      }

      rows.add(CustomerDebtRow(
        customer: cust,
        totalPurchased: totalPurchased,
        totalPaid: totalPaid,
        remaining: cust.totalDebt,
        lastPurchaseDate:
            custInvoices.isNotEmpty ? custInvoices.first.date : null,
        lastPaymentDate:
            custPayments.isNotEmpty ? custPayments.first.date : null,
        invoiceCount: custInvoices.length,
      ));
    }

    // ترتيب تنازلي حسب الدين
    rows.sort((a, b) => b.remaining.compareTo(a.remaining));

    return DebtReportSummary(
      totalDebtors: rows.length,
      totalDebt: rows.fold(0, (s, r) => s + r.remaining),
      monthlyIncoming: monthlyIncoming,
      invoiceCount: monthInvoices.where((i) => i.payType != 'تسديد دين').length,
      productsSoldCount: productsSoldCount,
      rows: rows,
      monthLabel: _arabicMonths[forMonth.month],
      year: forMonth.year.toString(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Generate PDF
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> generateAndShare({
    required DebtReportSummary summary,
    String? shopName,
    String? ownerName,
    String? shopPhone,
    String? shopLogoPath,
  }) async {
    final fontReg = await _font(_cairoRegPath);
    final fontBold = await _font(_cairoBoldPath);

    final baseStyle = pw.TextStyle(font: fontReg, fontSize: 10);
    final boldStyle = pw.TextStyle(font: fontBold, fontSize: 10);
    final smallStyle =
        pw.TextStyle(font: fontReg, fontSize: 8, color: PdfColors.grey600);

    pw.ImageProvider? logoImage;
    if (shopLogoPath != null && !kIsWeb) {
      final f = File(shopLogoPath);
      if (await f.exists()) {
        logoImage = pw.MemoryImage(await f.readAsBytes());
      }
    }

    final now = DateTime.now();
    final generatedAt = DateFormat('yyyy/MM/dd  hh:mm a').format(now);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 36),
        textDirection: pw.TextDirection.rtl,

        // ── Footer on every page ──
        footer: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 8),
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'صفحة ${ctx.pageNumber} من ${ctx.pagesCount}',
                style: pw.TextStyle(
                    font: fontReg, fontSize: 8, color: PdfColors.grey500),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(_devCredit,
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 7,
                          color: PdfColors.grey600),
                      textDirection: pw.TextDirection.rtl),
                  pw.Text('هاتف: $_devPhone',
                      style: pw.TextStyle(
                          font: fontReg,
                          fontSize: 7,
                          color: PdfColors.grey500)),
                ],
              ),
              pw.Text(_copyright,
                  style: pw.TextStyle(
                      font: fontReg, fontSize: 7, color: PdfColors.grey500),
                  textDirection: pw.TextDirection.rtl),
            ],
          ),
        ),

        build: (ctx) => [
          // ══════════════════════════════════════════════════════════════════
          // HEADER BLOCK
          // ══════════════════════════════════════════════════════════════════
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: _primaryColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Logo / placeholder
                if (logoImage != null)
                  pw.Container(
                    width: 54,
                    height: 54,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.white,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.ClipOval(
                        child: pw.Image(logoImage, fit: pw.BoxFit.cover)),
                  )
                else
                  pw.Container(
                    width: 48,
                    height: 48,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.white,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Center(
                      child: pw.Text('د',
                          style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 22,
                              color: _primaryColor)),
                    ),
                  ),
                pw.SizedBox(width: 12),
                // Shop info
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(shopName ?? 'سجل الديون',
                          style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 18,
                              color: PdfColors.white),
                          textDirection: pw.TextDirection.rtl),
                      if (ownerName != null && ownerName.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('بإدارة: $ownerName',
                            style: pw.TextStyle(
                                font: fontReg,
                                fontSize: 10,
                                color: const PdfColor(0.8, 0.85, 1.0)),
                            textDirection: pw.TextDirection.rtl),
                      ],
                      if (shopPhone != null && shopPhone.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text('هاتف: $shopPhone',
                            style: pw.TextStyle(
                                font: fontReg,
                                fontSize: 10,
                                color: const PdfColor(0.8, 0.85, 1.0)),
                            textDirection: pw.TextDirection.rtl),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(width: 14),
                // Report title block
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('تقرير سجل الديون',
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 13,
                            color: PdfColors.white),
                        textDirection: pw.TextDirection.rtl),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor(1, 1, 1, 0.15),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(12)),
                      ),
                      child: pw.Text('${summary.monthLabel}  ${summary.year}',
                          style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 11,
                              color: PdfColors.white),
                          textDirection: pw.TextDirection.rtl),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('تاريخ الإصدار: $generatedAt',
                        style: pw.TextStyle(
                            font: fontReg,
                            fontSize: 7,
                            color: const PdfColor(0.8, 0.85, 1.0))),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // ══════════════════════════════════════════════════════════════════
          // SUMMARY CARDS (5 cards)
          // ══════════════════════════════════════════════════════════════════
          pw.Row(
            children: [
              _card('عدد المديونين', '${summary.totalDebtors} زبون',
                  _primaryColor, fontReg, fontBold,
                  icon: '👥'),
              pw.SizedBox(width: 8),
              _card('الدين الكلي', _fmt(summary.totalDebt), _accentRed, fontReg,
                  fontBold,
                  icon: '💸'),
              pw.SizedBox(width: 8),
              _card('الواصل هذا الشهر', _fmt(summary.monthlyIncoming),
                  _accentGreen, fontReg, fontBold,
                  icon: '✅'),
              pw.SizedBox(width: 8),
              _card('عدد الفواتير', '${summary.invoiceCount}', _accentOrange,
                  fontReg, fontBold,
                  icon: '🧾'),
              pw.SizedBox(width: 8),
              _card('المنتجات المباعة', '${summary.productsSoldCount} وحدة',
                  const PdfColor.fromInt(0xFF7C3AED), fontReg, fontBold,
                  icon: '📦'),
            ],
          ),

          pw.SizedBox(height: 20),

          // ══════════════════════════════════════════════════════════════════
          // CUSTOMERS TABLE
          // ══════════════════════════════════════════════════════════════════
          pw.Text('جدول الزبائن المديونين',
              style: pw.TextStyle(
                  font: fontBold, fontSize: 13, color: _primaryColor),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 8),

          if (summary.rows.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Center(
                child: pw.Text('لا يوجد أي مديون حالياً',
                    style: pw.TextStyle(
                        font: fontReg, fontSize: 12, color: PdfColors.grey500),
                    textDirection: pw.TextDirection.rtl),
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(20), // رقم
                1: const pw.FlexColumnWidth(2.5), // الاسم
                2: const pw.FlexColumnWidth(1.6), // إجمالي المشتريات
                3: const pw.FlexColumnWidth(1.6), // الواصل
                4: const pw.FlexColumnWidth(1.6), // المتبقي
                5: const pw.FlexColumnWidth(1.4), // تاريخ آخر شراء
                6: const pw.FlexColumnWidth(1.4), // تاريخ آخر تسديد
                7: const pw.FixedColumnWidth(30), // فواتير
              },
              children: [
                // ── Header row ──
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: _primaryColor),
                  children: [
                    '#',
                    'اسم الزبون',
                    'إجمالي المشتريات',
                    'المبلغ الواصل',
                    'المبلغ المتبقي',
                    'آخر شراء',
                    'آخر تسديد',
                    'ف',
                  ]
                      .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                vertical: 6, horizontal: 4),
                            child: pw.Text(h,
                                style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 8,
                                    color: PdfColors.white),
                                textDirection: pw.TextDirection.rtl,
                                textAlign: pw.TextAlign.center),
                          ))
                      .toList(),
                ),
                // ── Data rows ──
                ...summary.rows.asMap().entries.map((entry) {
                  final i = entry.key;
                  final row = entry.value;
                  final bg = i.isEven ? PdfColors.white : _lightBg;
                  final debtColor = row.remaining > 500000
                      ? _accentRed
                      : (row.remaining > 100000
                          ? _accentOrange
                          : PdfColors.black);

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      // رقم
                      _tc('${i + 1}', baseStyle, center: true),
                      // الاسم + الهاتف
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 5, horizontal: 4),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(row.customer.name,
                                style: boldStyle,
                                textDirection: pw.TextDirection.rtl),
                            if (row.customer.phone != null)
                              pw.Text(row.customer.phone!, style: smallStyle),
                          ],
                        ),
                      ),
                      // إجمالي المشتريات
                      _tc(_fmt(row.totalPurchased), baseStyle, center: true),
                      // الواصل
                      _tc(_fmt(row.totalPaid),
                          baseStyle.copyWith(color: _accentGreen),
                          center: true),
                      // المتبقي
                      _tc(_fmt(row.remaining),
                          boldStyle.copyWith(color: debtColor),
                          center: true),
                      // آخر شراء
                      _tc(_fmtDate(row.lastPurchaseDate), smallStyle,
                          center: true),
                      // آخر تسديد
                      _tc(_fmtDate(row.lastPaymentDate), smallStyle,
                          center: true),
                      // عدد الفواتير
                      _tc('${row.invoiceCount}', baseStyle, center: true),
                    ],
                  );
                }),

                // ── Totals row ──
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFE8EEF8)),
                  children: [
                    _tc('', boldStyle),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('المجموع الكلي',
                          style: boldStyle,
                          textDirection: pw.TextDirection.rtl),
                    ),
                    _tc(
                        _fmt(summary.rows
                            .fold(0, (s, r) => s + r.totalPurchased)),
                        boldStyle,
                        center: true),
                    _tc(_fmt(summary.rows.fold(0, (s, r) => s + r.totalPaid)),
                        boldStyle.copyWith(color: _accentGreen),
                        center: true),
                    _tc(_fmt(summary.totalDebt),
                        boldStyle.copyWith(color: _accentRed),
                        center: true),
                    _tc('', boldStyle),
                    _tc('', boldStyle),
                    _tc('${summary.invoiceCount}', boldStyle, center: true),
                  ],
                ),
              ],
            ),

          pw.SizedBox(height: 20),

          // ══════════════════════════════════════════════════════════════════
          // NOTES
          // ══════════════════════════════════════════════════════════════════
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFFF8E1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.orange200, width: 0.5),
            ),
            child: pw.Row(
              children: [
                pw.Text('⚠', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Text(
                    'ملاحظة: تشير الأرقام بالأحمر إلى ديون تتجاوز 500,000 د.ع، والبرتقالي لديون تتجاوز 100,000 د.ع. '
                    'هذا التقرير يعكس البيانات حتى لحظة الطباعة.',
                    style: pw.TextStyle(
                        font: fontReg, fontSize: 8, color: PdfColors.grey700),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // ── Save & Share ──────────────────────────────────────────────────────
    final bytes = await pdf.save();
    final fileName = 'debt_report_${summary.monthLabel}_${summary.year}.pdf';

    if (kIsWeb) {
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'application/pdf', name: fileName)],
        text: 'تقرير الديون الشهري - ${summary.monthLabel} ${summary.year}',
      );
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'تقرير الديون الشهري - ${summary.monthLabel} ${summary.year}',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  static pw.Widget _card(
      String title, String value, PdfColor color, pw.Font reg, pw.Font bold,
      {String icon = ''}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
          color: PdfColors.white,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (icon.isNotEmpty)
              pw.Text(icon,
                  style: pw.TextStyle(font: reg, fontSize: 14),
                  textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(font: bold, fontSize: 11, color: color),
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 3),
            pw.Text(title,
                style: pw.TextStyle(
                    font: reg, fontSize: 8, color: PdfColors.grey600),
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.center),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tc(String text, pw.TextStyle style, {bool center = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(text,
          style: style,
          textAlign: center ? pw.TextAlign.center : pw.TextAlign.right,
          textDirection: pw.TextDirection.rtl),
    );
  }
}
