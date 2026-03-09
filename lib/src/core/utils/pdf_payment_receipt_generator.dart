import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

// Google Fonts TTF URLs for almarai
const _almaraiRegUrl =
    'https://github.com/google/fonts/raw/main/ofl/almarai/Almarai-Regular.ttf';
const _almaraiBoldUrl =
    'https://github.com/google/fonts/raw/main/ofl/almarai/Almarai-Bold.ttf';

const _devCredit =
    'برمجة وتطوير: المبرمج مرتضى علاء | مكتب فن للتصميم والبرمجة';
const _devPhone = '07876007620 - 07813938267';
const _copyright = '© 2026 جميع الحقوق محفوظة ';

class PdfPaymentReceiptGenerator {
  PdfPaymentReceiptGenerator._();

  static final _amtFmt = NumberFormat('#,##0', 'en');
  static String _fmt(double v) => '${_amtFmt.format(v)} د.ع';

  /// Downloads a font file from [url] and caches it in the temp directory.
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

  /// Generates the payment receipt PDF and shares it.
  static Future<void> generateAndShare({
    required String customerName,
    required double amountPaid,
    DateTime? date,
    String? shopName,
    String? ownerName,
    String? shopPhone,
    String? shopLogoPath,
  }) async {
    final pdf = pw.Document();

    final regFont =
        await _loadFontFromNetwork(_almaraiRegUrl, 'almarai_reg.ttf');
    final boldFont =
        await _loadFontFromNetwork(_almaraiBoldUrl, 'almarai_bold.ttf');
    final fontReg = regFont ?? pw.Font.helvetica();
    final fontBold = boldFont ?? fontReg;

    pw.ImageProvider? logoImage;
    if (shopLogoPath != null) {
      final logoFile = File(shopLogoPath);
      if (await logoFile.exists()) {
        final bytes = await logoFile.readAsBytes();
        logoImage = pw.MemoryImage(bytes);
      }
    }

    final dateStr =
        DateFormat('yyyy/MM/dd', 'en').format(date ?? DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF1A3C6E),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        width: 60,
                        height: 60,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: PdfColors.white,
                          image: pw.DecorationImage(
                              image: logoImage, fit: pw.BoxFit.cover),
                        ),
                      )
                    else
                      pw.SizedBox(width: 60),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          shopName ?? 'مكتب تجاري',
                          style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 22,
                              color: PdfColors.white),
                        ),
                        if (ownerName != null)
                          pw.Text(
                            'بإدارة: $ownerName',
                            style: pw.TextStyle(
                                font: fontReg,
                                fontSize: 10,
                                color: const PdfColor(0.8, 0.8, 1.0)),
                          ),
                        if (shopPhone != null)
                          pw.Text(
                            'هاتف: $shopPhone',
                            style: pw.TextStyle(
                                font: fontReg,
                                fontSize: 10,
                                color: const PdfColor(0.8, 0.8, 1.0)),
                          ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'وصل استلام قبض',
                          style: pw.TextStyle(
                              font: fontReg,
                              fontSize: 14,
                              color: PdfColors.white),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'التاريخ: $dateStr',
                          style: pw.TextStyle(
                              font: fontReg,
                              fontSize: 12,
                              color: PdfColors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),

              // Body
              pw.Container(
                padding: const pw.EdgeInsets.all(32),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 2),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(16)),
                  color: const PdfColor.fromInt(0xFFF8FAFC),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'استلمت من السيد / السيدة',
                      style: pw.TextStyle(
                          font: fontReg,
                          fontSize: 18,
                          color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      customerName,
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 28,
                          color: const PdfColor.fromInt(0xFF1E293B)),
                    ),
                    pw.SizedBox(height: 24),
                    pw.Text(
                      'مبلغاً وقدره',
                      style: pw.TextStyle(
                          font: fontReg,
                          fontSize: 18,
                          color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFEEF2FF),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(12)),
                        border: pw.Border.all(
                            color: const PdfColor.fromInt(0xFF818CF8)),
                      ),
                      child: pw.Text(
                        _fmt(amountPaid),
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 24,
                            color: const PdfColor.fromInt(0xFF4338CA)),
                        textDirection: pw.TextDirection.ltr,
                      ),
                    ),
                    pw.SizedBox(height: 24),
                    pw.Text(
                      'وذلك كدفعة تسديد من الدين الكُلي',
                      style: pw.TextStyle(
                          font: fontReg,
                          fontSize: 18,
                          color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 32),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 16),
                    pw.Text(
                      'شكراً لتعاملكم معنا',
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 20,
                          color: const PdfColor.fromInt(0xFF10B981)),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(children: [
                      pw.Text('توقيع المستلم',
                          style: pw.TextStyle(font: fontBold, fontSize: 16)),
                      pw.SizedBox(height: 40),
                      pw.Container(
                          width: 150, height: 1, color: PdfColors.grey400),
                    ]),
                    pw.Column(children: [
                      pw.Text('توقيع المسدد',
                          style: pw.TextStyle(font: fontBold, fontSize: 16)),
                      pw.SizedBox(height: 40),
                      pw.Container(
                          width: 150, height: 1, color: PdfColors.grey400),
                    ]),
                  ]),

              pw.SizedBox(height: 40),

              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.only(top: 16),
                decoration: const pw.BoxDecoration(
                  border:
                      pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(_devCredit,
                        style: pw.TextStyle(font: fontBold, fontSize: 8),
                        textDirection: pw.TextDirection.rtl),
                    pw.SizedBox(height: 2),
                    pw.Text('هاتف: $_devPhone | $_copyright',
                        style: pw.TextStyle(font: fontReg, fontSize: 7),
                        textDirection: pw.TextDirection.rtl),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();

    if (kIsWeb) {
      await Share.shareXFiles(
        [
          XFile.fromData(bytes,
              mimeType: 'application/pdf',
              name: 'receipt_${DateTime.now().millisecondsSinceEpoch}.pdf')
        ],
        text: 'وصل استلام قبض - $customerName',
      );
    } else {
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'وصل استلام قبض - $customerName',
      );
    }
  }
}
