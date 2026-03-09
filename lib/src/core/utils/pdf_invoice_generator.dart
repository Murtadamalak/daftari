import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // Added for rootBundle
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/repositories/invoice_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _appName = 'نظام دفتري لإدارة الحسابات';
const _ctaText = 'هل أعجبك تنظيم هذا الوصل؟ صمم تطبيقك الخاص الآن!';
const _devCredit =
    'برمجة وتطوير: المبرمج مرتضى علاء | مكتب فن للتصميم والبرمجة';
const _devPhone = '07876007620 - 07813938267';
const _copyright = '© 2026 جميع الحقوق محفوظة ';
const _telegramUrl = 'https://t.me/art8ms';
const _qrCaption = 'امسح الرمز للتواصل المباشر';

const _cairoRegPath = 'assets/fonts/Cairo-Regular.ttf';
const _cairoBoldPath = 'assets/fonts/Cairo-Bold.ttf';

// ─────────────────────────────────────────────────────────────────────────────
// PDF Generator
// ─────────────────────────────────────────────────────────────────────────────

class PdfInvoiceGenerator {
  PdfInvoiceGenerator._();

  static final _amtFmt = NumberFormat('#,##0', 'en');
  static String _fmt(double v) => '${_amtFmt.format(v)} د.ع';
  static String _fmtQty(double v) =>
      v == v.truncate() ? v.toInt().toString() : v.toStringAsFixed(2);

  /// Loads a font from the application assets.
  static Future<pw.Font> _loadFontFromAssets(String path) async {
    final data = await rootBundle.load(path);
    return pw.Font.ttf(data);
  }

  /// Generates the invoice PDF and shares it via share_plus.
  static Future<void> generateAndShare({
    required InvoiceModel invoice,
    required List<InvoiceItemModel> items,
    required String invoiceId,
    String? shopName,
    String? ownerName,
    String? shopPhone,
    String? shopLogoPath,
  }) async {
    final pdf = pw.Document();

    final fontReg = await _loadFontFromAssets(_cairoRegPath);
    final fontBold = await _loadFontFromAssets(_cairoBoldPath);

    final baseStyle = pw.TextStyle(font: fontReg, fontSize: 11);
    final boldStyle = pw.TextStyle(font: fontBold, fontSize: 11);
    final smallStyle =
        pw.TextStyle(font: fontReg, fontSize: 9, color: PdfColors.grey600);
    final smallBoldStyle = pw.TextStyle(font: fontBold, fontSize: 9);

    // ── Logo (optional) ──────────────────────────────────────────────────────
    pw.ImageProvider? logoImage;
    if (shopLogoPath != null) {
      final logoFile = File(shopLogoPath);
      if (await logoFile.exists()) {
        final bytes = await logoFile.readAsBytes();
        logoImage = pw.MemoryImage(bytes);
      }
    }

    // ── Date ─────────────────────────────────────────────────────────────────
    final dateStr = DateFormat('yyyy/MM/dd  hh:mm a').format(invoice.date);

    // ── Status label ─────────────────────────────────────────────────────────
    final statusLabel = switch (invoice.status) {
      'paid' => 'مسدد',
      'partial' => 'جزئي',
      _ => 'دين',
    };
    final statusColor = switch (invoice.status) {
      'paid' => PdfColors.green700,
      'partial' => PdfColors.orange700,
      _ => PdfColors.red700,
    };

    // ─────────────────────────────────────────────────────────────────────────
    // Build Page
    // ─────────────────────────────────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ═══════════════════════════════════════════════════════════════
              // HEADER
              // ═══════════════════════════════════════════════════════════════
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF1A3C6E),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Logo placeholder or shop icon
                    if (logoImage != null)
                      pw.Container(
                        width: 56,
                        height: 56,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      )
                    else
                      pw.Container(
                        width: 52,
                        height: 52,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.white,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'د',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 24,
                              color: const PdfColor.fromInt(0xFF1A3C6E),
                            ),
                          ),
                        ),
                      ),

                    pw.SizedBox(width: 12),

                    // Shop name + app name
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            shopName ?? invoice.shopName,
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 18,
                              color: PdfColors.white,
                            ),
                            textDirection: pw.TextDirection.rtl,
                          ),
                          if ((ownerName ?? invoice.ownerName) != null) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'بإدارة: ${ownerName ?? invoice.ownerName}',
                              style: pw.TextStyle(
                                font: fontReg,
                                fontSize: 10,
                                color: const PdfColor(0.8, 0.8, 1.0),
                              ),
                              textDirection: pw.TextDirection.rtl,
                            ),
                          ],
                          if ((shopPhone ?? invoice.shopPhone) != null) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'هاتف: ${shopPhone ?? invoice.shopPhone}',
                              style: pw.TextStyle(
                                font: fontReg,
                                fontSize: 10,
                                color: const PdfColor(0.8, 0.8, 1.0),
                              ),
                              textDirection: pw.TextDirection.rtl,
                            ),
                          ],
                          pw.SizedBox(height: 4),
                          pw.Text(
                            _appName,
                            style: pw.TextStyle(
                              font: fontReg,
                              fontSize: 9,
                              color: const PdfColor(0.7, 0.7, 0.9),
                            ),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ═══════════════════════════════════════════════════════════════
              // INVOICE INFO
              // ═══════════════════════════════════════════════════════════════
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _pdfLabelValue('رقم الفاتورة', invoice.formattedNum,
                        fontReg, fontBold),
                    _pdfLabelValue('التاريخ', dateStr, fontReg, fontBold),
                    _pdfStatusBadge(statusLabel, statusColor, fontBold),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // Customer
              pw.Row(
                children: [
                  pw.Text('الزبون: ',
                      style: boldStyle, textDirection: pw.TextDirection.rtl),
                  pw.Text(invoice.customerName,
                      style: baseStyle, textDirection: pw.TextDirection.rtl),
                  if (invoice.customerPhone != null) ...[
                    pw.SizedBox(width: 16),
                    pw.Text('الهاتف: ',
                        style: boldStyle, textDirection: pw.TextDirection.rtl),
                    pw.Text(invoice.customerPhone!, style: baseStyle),
                  ],
                ],
              ),

              pw.SizedBox(height: 14),

              // ═══════════════════════════════════════════════════════════════
              // ITEMS TABLE
              // ═══════════════════════════════════════════════════════════════
              pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4), // product
                  1: const pw.FlexColumnWidth(1.2), // qty + unit
                  2: const pw.FlexColumnWidth(2), // unit price
                  3: const pw.FlexColumnWidth(2), // total
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF1A3C6E)),
                    children: ['المنتج', 'الكمية', 'السعر', 'الإجمالي']
                        .map((h) => pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                  vertical: 7, horizontal: 6),
                              child: pw.Text(h,
                                  style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 10,
                                    color: PdfColors.white,
                                  ),
                                  textDirection: pw.TextDirection.rtl,
                                  textAlign: pw.TextAlign.right),
                            ))
                        .toList(),
                  ),
                  // Item rows
                  ...items.asMap().entries.map((e) {
                    final i = e.key;
                    final item = e.value;
                    final bg = i.isOdd ? PdfColors.grey50 : PdfColors.white;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: bg),
                      children: [
                        // Product name
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(item.productName,
                                  style: baseStyle,
                                  textDirection: pw.TextDirection.rtl),
                              pw.Text(
                                item.priceType == 'wholesale' ? 'جملة' : 'مفرد',
                                style: smallStyle,
                                textDirection: pw.TextDirection.rtl,
                              ),
                            ],
                          ),
                        ),
                        _cell('${_fmtQty(item.qty)} ${item.unit}', baseStyle),
                        _cell(_fmt(item.unitPrice), baseStyle),
                        _cell(
                          _fmt(item.total),
                          boldStyle.copyWith(
                              color: const PdfColor.fromInt(0xFF1A3C6E)),
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 14),

              // Notes (If any)
              if (invoice.note != null && invoice.note!.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.yellow50,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.yellow200),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'ملاحظات:',
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                            color: PdfColors.grey800),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        invoice.note!,
                        style: pw.TextStyle(
                            font: fontReg, fontSize: 9, color: PdfColors.black),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),
              ],

              // ═══════════════════════════════════════════════════════════════
              // TOTALS
              // ═══════════════════════════════════════════════════════════════
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  children: [
                    _pdfTotalRow('الإجمالي الفرعي', _fmt(invoice.subtotal),
                        fontReg, fontBold),
                    if (invoice.discount > 0)
                      _pdfTotalRow('الخصم', '- ${_fmt(invoice.discount)}',
                          fontReg, fontBold,
                          valueColor: PdfColors.orange700),
                    pw.Divider(color: PdfColors.grey400, height: 12),
                    _pdfTotalRow('الإجمالي النهائي', _fmt(invoice.grandTotal),
                        fontReg, fontBold,
                        isBold: true, big: true),
                    pw.SizedBox(height: 4),
                    _pdfTotalRow('المبلغ المدفوع', _fmt(invoice.currentPaid),
                        fontReg, fontBold,
                        valueColor: PdfColors.green700),
                    if (invoice.debt > 0)
                      _pdfTotalRow('المتبقي (دين)', _fmt(invoice.debt), fontReg,
                          fontBold,
                          valueColor: PdfColors.red700, isBold: true),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════════
              // THANK YOU
              // ═══════════════════════════════════════════════════════════════
              pw.Center(
                child: pw.Text(
                  'شكراً لتعاملكم معنا 🙏',
                  style: pw.TextStyle(
                      font: fontReg, fontSize: 13, color: PdfColors.grey600),
                  textDirection: pw.TextDirection.rtl,
                ),
              ),

              pw.SizedBox(height: 16),

              // ═══════════════════════════════════════════════════════════════
              // MARKETING FOOTER
              // ═══════════════════════════════════════════════════════════════
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),

              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // ── Left: CTA + Credits ──
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        // CTA headline
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: const PdfColor.fromInt(0xFFE8EEF8),
                            borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(6)),
                          ),
                          child: pw.Text(
                            _ctaText,
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 10,
                              color: const PdfColor.fromInt(0xFF1A3C6E),
                            ),
                            textDirection: pw.TextDirection.rtl,
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          _devCredit,
                          style: smallBoldStyle,
                          textDirection: pw.TextDirection.rtl,
                          textAlign: pw.TextAlign.right,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _devPhone,
                          style: smallStyle,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _copyright,
                          style: smallStyle.copyWith(fontSize: 7),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(width: 20),

                  // ── Right: QR Code ──
                  pw.Column(
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: _telegramUrl,
                        width: 70,
                        height: 70,
                        drawText: false,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _qrCaption,
                        style: pw.TextStyle(
                          font: fontReg,
                          fontSize: 7,
                          color: PdfColors.grey600,
                        ),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // ── Save & share ──────────────────────────────────────────────────────────
    final bytes = await pdf.save();

    if (kIsWeb) {
      await Share.shareXFiles(
        [
          XFile.fromData(bytes,
              mimeType: 'application/pdf', name: 'invoice_$invoiceId.pdf')
        ],
        text: 'فاتورة رقم $invoiceId - $_appName',
      );
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/invoice_$invoiceId.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'فاتورة رقم $invoiceId - $_appName',
      );
    }
  }

  // ─── Helper widgets ─────────────────────────────────────────────────────────

  static pw.Widget _cell(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      child: pw.Text(text, style: style, textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _pdfLabelValue(
      String label, String value, pw.Font reg, pw.Font bold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(label,
            style:
                pw.TextStyle(font: reg, fontSize: 8, color: PdfColors.grey600),
            textDirection: pw.TextDirection.rtl),
        pw.Text(value,
            style: pw.TextStyle(font: bold, fontSize: 10),
            textDirection: pw.TextDirection.rtl),
      ],
    );
  }

  static pw.Widget _pdfStatusBadge(String label, PdfColor color, pw.Font bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Text(label,
          style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white),
          textDirection: pw.TextDirection.rtl),
    );
  }

  static pw.Widget _pdfTotalRow(
    String label,
    String value,
    pw.Font reg,
    pw.Font boldFont, {
    bool isBold = false,
    bool big = false,
    PdfColor? valueColor,
  }) {
    final labelStyle =
        pw.TextStyle(font: isBold ? boldFont : reg, fontSize: big ? 13 : 10);
    final valueStyle = pw.TextStyle(
        font: isBold ? boldFont : reg,
        fontSize: big ? 13 : 10,
        color: valueColor);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: labelStyle, textDirection: pw.TextDirection.rtl),
          pw.Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
