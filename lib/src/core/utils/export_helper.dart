import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
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
    final bool isPdf = extension.toLowerCase() == 'pdf';

    await showModalBottomSheet(
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
                if (isPdf)
                  ListTile(
                    leading: const Icon(Icons.print_outlined),
                    title: const Text('طباعة'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _printPdf(bytes, fileName);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.save_alt_outlined),
                  title: const Text('حفظ كملف'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _saveFile(context, bytes, fileName, extension);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('مشاركة'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareFile(bytes, fileName, mimeType, shareText);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _printPdf(Uint8List bytes, String fileName) async {
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: fileName,
    );
  }

  static Future<void> _saveFile(BuildContext context, Uint8List bytes, String fileName, String extension) async {
    try {
      if (kIsWeb) {
        // fallback to share on web for downloading
        _shareFile(bytes, fileName, '', null);
        return;
      }

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ الملف',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [extension.replaceAll('.', '')],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
        if (context.mounted) {
          AppSnackBar.success(context, 'تم حفظ الملف بنجاح');
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, 'فشل الحفظ: $e');
      }
    }
  }

  static Future<void> _shareFile(Uint8List bytes, String fileName, String mimeType, String? shareText) async {
    if (kIsWeb) {
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
        text: shareText,
      );
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
        text: shareText,
      );
    }
  }
}
