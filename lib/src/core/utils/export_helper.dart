import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_snackbar.dart';

class ExportHelper {
  static Future<void> exportBytes({
    required BuildContext context,
    required Uint8List bytes,
    required String fileName,
    required String extension,
    required String mimeType,
    String? shareText,
  }) async {
    final bool isPdf = extension.toLowerCase() == 'pdf' || extension.toLowerCase() == '.pdf';

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.print_outlined),
                  title: const Text('طباعة'),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (isPdf) {
                      _printPdf(context, bytes, fileName);
                    } else {
                      _printImage(context, bytes, fileName);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.save_alt_outlined),
                  title: const Text('حفظ كملف'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _saveFile(context, bytes, fileName, extension, mimeType);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('مشاركة'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareFile(context, bytes, fileName, mimeType, shareText);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _printPdf(BuildContext context, Uint8List bytes, String fileName) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: fileName,
      );
    } catch (e) {
      debugPrint('[ExportHelper] Print error: $e');
      if (context.mounted) {
        AppSnackBar.error(context, 'تعذّر إرسال أمر الطباعة: $e');
      }
    }
  }

  static Future<void> _printImage(BuildContext context, Uint8List bytes, String fileName) async {
    try {
      final doc = pw.Document();
      final image = pw.MemoryImage(bytes);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => pw.Center(child: pw.Image(image)),
        ),
      );
      final pdfBytes = await doc.save();
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: fileName,
      );
    } catch (e) {
      debugPrint('[ExportHelper] Print image error: $e');
      if (context.mounted) {
        AppSnackBar.error(context, 'تعذّر إرسال أمر الطباعة: $e');
      }
    }
  }

  static Future<void> _saveFile(
    BuildContext context,
    Uint8List bytes,
    String fileName,
    String extension,
    String mimeType,
  ) async {
    try {
      if (kIsWeb) {
        if (extension.toLowerCase().contains('pdf')) {
          await Printing.sharePdf(bytes: bytes, filename: fileName);
        } else {
          await Share.shareXFiles(
            [XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
            text: fileName,
          );
        }
        return;
      }

      final extClean = extension.replaceAll('.', '').toLowerCase();

      // On Desktop (Windows / Linux / macOS)
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'حفظ الملف',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: [extClean],
        );

        if (outputFile != null && outputFile.trim().isNotEmpty) {
          final file = File(outputFile);
          await file.writeAsBytes(bytes);
          if (context.mounted) {
            AppSnackBar.success(context, 'تم حفظ الملف بنجاح');
          }
        }
        return;
      }

      // On Mobile (Android / iOS)
      if (Platform.isAndroid) {
        try {
          final downloadDir = Directory('/storage/emulated/0/Download');
          final targetDir = await downloadDir.exists()
              ? downloadDir
              : await getExternalStorageDirectory();

          if (targetDir != null) {
            final file = File('${targetDir.path}/$fileName');
            await file.writeAsBytes(bytes);
            if (context.mounted) {
              AppSnackBar.success(context, 'تم حفظ الملف في التنزيلات بنجاح: $fileName');
            }
            return;
          }
        } catch (_) {}
      }

      // Fallback on mobile: native save/share sheet
      if (extClean == 'pdf') {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: mimeType)],
          text: fileName,
        );
      }
      if (context.mounted) {
        AppSnackBar.success(context, 'تم إعداد الملف بنجاح');
      }
    } catch (e) {
      debugPrint('[ExportHelper] Save file error: $e');
      if (context.mounted) {
        AppSnackBar.error(context, 'فشل الحفظ: $e');
      }
    }
  }

  static Future<void> _shareFile(
    BuildContext context,
    Uint8List bytes,
    String fileName,
    String mimeType,
    String? shareText,
  ) async {
    try {
      if (kIsWeb) {
        if (mimeType.contains('pdf')) {
          await Printing.sharePdf(bytes: bytes, filename: fileName);
        } else {
          await Share.shareXFiles(
            [XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
            text: shareText,
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop platforms do not have native mobile share sheets; open the file directly
        final uri = Uri.file(file.path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else if (context.mounted) {
          await _saveFile(context, bytes, fileName, fileName.split('.').last, mimeType);
        }
        return;
      }

      // Mobile PDF sharing is best handled by Printing.sharePdf
      if (mimeType.contains('pdf')) {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
        return;
      }

      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
        text: shareText,
      );
    } catch (e) {
      debugPrint('[ExportHelper] Share error: $e');
      if (context.mounted) {
        AppSnackBar.error(context, 'فشلت المشاركة: $e');
      }
    }
  }
}
