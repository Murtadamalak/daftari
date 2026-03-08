import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/repositories/invoice_repository.dart';

// Google Fonts TTF URLs for Cairo
const _cairoRegUrl =
    'https://github.com/google/fonts/raw/main/ofl/cairo/Cairo%5Bslnt%2Cwght%5D.ttf';

class PdfReportGenerator {
  PdfReportGenerator._();

  static final _amtFmt = NumberFormat('#,##0', 'en');
  static String _fmt(double v) => '${_amtFmt.format(v)} د.ع';
  static String _fmtQty(double v) =>
      v == v.truncate() ? v.toInt().toString() : v.toStringAsFixed(2);

  static Future<pw.Font?> _loadFontFromNetwork(
      String url, String fileName) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheFile = File('${cacheDir.path}/$fileName');

      if (!await cacheFile.exists()) {
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        final bytes = await response
            .fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
        await cacheFile.writeAsBytes(bytes);
        client.close();
      }

      final data = cacheFile.readAsBytesSync();
      return pw.Font.ttf(data.buffer.asByteData());
    } catch (_) {
      return null;
    }
  }

  static Future<void> generateAndShare({
    required DateTimeRange dateRange,
    required List<InvoiceModel> invoices,
    required List<MapEntry<String, double>> itemQuantities,
    required double totalSales,
    required double totalPaid,
    required double totalDebt,
    String? shopName,
    String? shopLogoPath,
  }) async {
    final pdf = pw.Document();

    final cairoFont = await _loadFontFromNetwork(_cairoRegUrl, 'cairo_vf.ttf');
    final cairoReg = cairoFont ?? pw.Font.helvetica();
    final cairoBold = cairoFont ?? pw.Font.helveticaBold();

    final baseStyle = pw.TextStyle(font: cairoReg, fontSize: 10);
    final boldStyle = pw.TextStyle(font: cairoBold, fontSize: 10);
    final titleStyle = pw.TextStyle(
        font: cairoBold,
        fontSize: 16,
        color: const PdfColor.fromInt(0xFF1A3C6E));

    final dateStr1 = DateFormat('yyyy/MM/dd').format(dateRange.start);
    final dateStr2 = DateFormat('yyyy/MM/dd').format(dateRange.end);
    final periodStr = '$dateStr1  إلى  $dateStr2';

    pw.ImageProvider? logoImage;
    if (shopLogoPath != null) {
      final logoFile = File(shopLogoPath);
      if (await logoFile.exists()) {
        final bytes = await logoFile.readAsBytes();
        logoImage = pw.MemoryImage(bytes);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context ctx) {
          return [
            // ── Header ──────────────────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(shopName ?? 'مبيعات المحل', style: titleStyle),
                    pw.SizedBox(height: 4),
                    pw.Text('تقرير المبيعات الشامل', style: boldStyle),
                    pw.Text('للفترة: $periodStr', style: baseStyle),
                  ],
                ),
                if (logoImage != null)
                  pw.Container(
                    width: 60,
                    height: 60,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  )
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 16),

            // ── Summary Cards ────────────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _summaryCard('المبيعات الكلية', _fmt(totalSales),
                    PdfColors.blue800, cairoReg, cairoBold),
                _summaryCard('الإيرادات المحصلة', _fmt(totalPaid),
                    PdfColors.green700, cairoReg, cairoBold),
                _summaryCard('الديون المتبقية', _fmt(totalDebt),
                    PdfColors.red700, cairoReg, cairoBold),
              ],
            ),
            pw.SizedBox(height: 24),

            // ── Top Products Table ───────────────────────────────────────────────
            pw.Text('تفاصيل المنتجات المباعة (الكميات):',
                style: titleStyle.copyWith(fontSize: 14)),
            pw.SizedBox(height: 8),
            if (itemQuantities.isEmpty)
              pw.Text('لا توجد مبيعات في هذه الفترة.', style: baseStyle)
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('المنتج',
                            style: boldStyle, textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('الكمية',
                            style: boldStyle, textAlign: pw.TextAlign.center),
                      ),
                    ],
                  ),
                  ...itemQuantities.map(
                    (e) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(e.key,
                              style: baseStyle, textAlign: pw.TextAlign.right),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(_fmtQty(e.value),
                              style: boldStyle, textAlign: pw.TextAlign.center),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            pw.SizedBox(height: 24),

            // ── Invoices Table ───────────────────────────────────────────────
            pw.Text('قائمة الفواتير:',
                style: titleStyle.copyWith(fontSize: 14)),
            pw.SizedBox(height: 8),
            if (invoices.isEmpty)
              pw.Text('لا توجد فواتير لهذه الفترة.', style: baseStyle)
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FixedColumnWidth(80),
                  1: const pw.FlexColumnWidth(),
                  2: const pw.FixedColumnWidth(80),
                  3: const pw.FixedColumnWidth(60),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children:
                        ['التاريخ / الوقت', 'الزبون', 'الإجمالي', 'الحالة']
                            .map((text) => pw.Padding(
                                  padding: const pw.EdgeInsets.all(6),
                                  child: pw.Text(text,
                                      style: boldStyle,
                                      textAlign: pw.TextAlign.center),
                                ))
                            .toList(),
                  ),
                  ...invoices.map((inv) {
                    final timeStr =
                        DateFormat('yy/MM/dd hh:mm', 'en').format(inv.date);
                    final cName = inv.payType == 'تسديد دين'
                        ? '${inv.customerName} (دفعة دين)'
                        : inv.customerName;
                    final gTotal = _fmt(inv.grandTotal);
                    final status = inv.payType == 'تسديد دين'
                        ? 'دُفعة مسددة'
                        : (inv.status == 'paid'
                            ? 'مسدد'
                            : (inv.status == 'partial' ? 'جزئي' : 'دين'));

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(timeStr,
                                style: baseStyle,
                                textAlign: pw.TextAlign.center)),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(cName,
                                style: baseStyle,
                                textAlign: pw.TextAlign.right)),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(gTotal,
                                style: boldStyle,
                                textAlign: pw.TextAlign.center)),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(status,
                                style: baseStyle,
                                textAlign: pw.TextAlign.center)),
                      ],
                    );
                  }),
                ],
              ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();

    if (kIsWeb) {
      await Share.shareXFiles(
        [
          XFile.fromData(bytes,
              mimeType: 'application/pdf',
              name: 'report_${DateTime.now().millisecondsSinceEpoch}.pdf')
        ],
        text: 'تقرير المبيعات من $dateStr1 إلى $dateStr2',
      );
    } else {
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'تقرير المبيعات من $dateStr1 إلى $dateStr2',
      );
    }
  }

  static pw.Widget _summaryCard(
      String title, String value, PdfColor color, pw.Font reg, pw.Font bold) {
    return pw.Container(
      width: 140,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1.5),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  font: reg, fontSize: 10, color: PdfColors.grey700),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 6),
          pw.Text(value,
              style: pw.TextStyle(font: bold, fontSize: 13, color: color),
              textDirection: pw.TextDirection.rtl),
        ],
      ),
    );
  }
}
