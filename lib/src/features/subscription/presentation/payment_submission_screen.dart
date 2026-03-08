import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../data/subscription_provider.dart';
import 'payment_success_screen.dart';

class PaymentSubmissionScreen extends ConsumerStatefulWidget {
  final String planType;

  const PaymentSubmissionScreen({super.key, required this.planType});

  @override
  ConsumerState<PaymentSubmissionScreen> createState() =>
      _PaymentSubmissionScreenState();
}

class _PaymentSubmissionScreenState
    extends ConsumerState<PaymentSubmissionScreen> {
  final TextEditingController _transferNumController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  XFile? _selectedImage;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedImage == null) {
      _showError('يرجى إرفاق صورة لوصل الدفع');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final extension = _selectedImage!.name.split('.').last.toLowerCase();

      final service = ref.read(subscriptionServiceProvider);
      await service.submitPaymentRequest(
        planType: widget.planType,
        transferNum: _transferNumController.text.trim().isEmpty
            ? null
            : _transferNumController.text.trim(),
        receiptBytes: bytes,
        fileExtension: extension,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.tajawal()),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'حاول مجدداً',
          textColor: Colors.white,
          onPressed: () {}, // Simply dismisses the snackbar
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          title: Text(
            'تأكيد طلب التفعيل',
            style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'رقم عملية زين كاش (اختياري)',
                style: GoogleFonts.tajawal(color: Colors.grey[400]),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _transferNumController,
                style: GoogleFonts.tajawal(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  hintText: 'مثال: 1042345678',
                  hintStyle: GoogleFonts.tajawal(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Text(
                'وصل الدفع (مطلوب)',
                style: GoogleFonts.tajawal(color: Colors.white),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedImage == null
                          ? Colors.transparent
                          : const Color(0xFF22C55E),
                      width: 2,
                    ),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: kIsWeb
                                  ? Image.network(_selectedImage!.path,
                                      fit: BoxFit.cover)
                                  : Image.file(File(_selectedImage!.path),
                                      fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            )
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate,
                                size: 48, color: Color(0xFF6366F1)),
                            const SizedBox(height: 12),
                            Text(
                              'اضغط لاختيار صورة الوصل',
                              style:
                                  GoogleFonts.tajawal(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'معلومة إضافية (اختياري)',
                style: GoogleFonts.tajawal(color: Colors.grey[400]),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 3,
                style: GoogleFonts.tajawal(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  hintText: 'أي ملاحظة تود تركها للإدارة...',
                  hintStyle: GoogleFonts.tajawal(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    disabledBackgroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitRequest,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'أرسل الطلب',
                          style: GoogleFonts.tajawal(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
