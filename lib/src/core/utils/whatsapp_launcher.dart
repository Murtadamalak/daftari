import 'package:url_launcher/url_launcher.dart';

class WhatsAppLauncher {
  WhatsAppLauncher._();

  static Future<void> sendReminder({
    required String phone,
    required String customerName,
    required String products,
    required String remainingBalance,
  }) async {
    final message = '''
السلام عليكم أخي $customerName المحترم،
نود تذكيركم بتسديد القسط المستحق بذمتكم لهذا اليوم عن:
($products)
المبلغ المتبقي الكلي: $remainingBalance
شكراً لتعاونكم معنا 🙏
''';
    await _launchWhatsApp(phone, message);
  }

  static Future<void> sendPaymentReceipt({
    required String phone,
    required String customerName,
    required String amountPaid,
    required String remainingBalance,
  }) async {
    final message = '''
زبوننا العزيز $customerName،
تم استلام مبلغ ($amountPaid) د.ع من حسابكم بنجاح.
المبلغ المتبقي في ذمتكم الآن هو ($remainingBalance) د.ع.
شكراً لتعاملكم معنا 🙏
''';
    await _launchWhatsApp(phone, message);
  }

  static Future<void> _launchWhatsApp(String phone, String message) async {
    // Basic phone cleaning (remove leading + or 00 if needed for standard wa.me)
    // Most users in Iraq use 07xxxxxxxx. wa.me prefers 9647xxxxxxxx.
    String formattedPhone = phone.trim().replaceAll(RegExp(r'\s+'), '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '964${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('964')) {
      formattedPhone = '964$formattedPhone';
    }

    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://wa.me/$formattedPhone?text=$encodedMessage';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
