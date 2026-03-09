import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/app_providers.dart';
import '../core/providers/products_provider.dart';
import '../data/repositories/product_repository.dart';
import 'barcode_scanner_screen.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  const AddEditProductScreen({
    super.key,
    this.productId,
  });

  /// If null, we are adding. Otherwise, editing (loads product by id).
  final String? productId;

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _retailPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _barcodeController = TextEditingController();

  static const _units = ['قطعة', 'كيلو', 'حبة', 'علبة', 'لتر', 'كرتون'];

  ProductModel? _product;
  bool _isLoading = true;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    _unitController.text = _units.first;
    if (widget.productId != null) {
      _loadProduct();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadProduct() async {
    final repo = ref.read(productRepositoryProvider);
    final product = await repo.getById(widget.productId!);
    if (mounted) {
      setState(() {
        _product = product;
        _isLoading = false;
      });
      if (product != null) {
        _nameController.text = product.name;
        _unitController.text = product.unit;
        _retailPriceController.text = product.retailPrice.toStringAsFixed(0);
        _wholesalePriceController.text =
            product.wholesalePrice?.toStringAsFixed(0) ?? '';
        _stockController.text = product.stock?.toStringAsFixed(0) ?? '';
        _barcodeController.text = product.barcode ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _retailPriceController.dispose();
    _wholesalePriceController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );
    if (result != null && mounted) {
      _barcodeController.text = result;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final unit = _unitController.text.trim();
    final retailPrice = double.tryParse(_retailPriceController.text) ?? 0;
    final wholesaleStr = _wholesalePriceController.text.trim();
    final wholesalePrice =
        wholesaleStr.isEmpty ? null : double.tryParse(wholesaleStr);
    final stockStr = _stockController.text.trim();
    final stock = stockStr.isEmpty ? null : double.tryParse(stockStr);
    final barcode = _barcodeController.text.trim();
    final barcodeVal = barcode.isEmpty ? null : barcode;

    final repo = ref.read(productRepositoryProvider);

    await repo.upsertProduct(
      id: _isEditing ? _product?.id : null,
      name: name,
      unit: unit,
      retailPrice: retailPrice,
      wholesalePrice: wholesalePrice,
      stock: stock,
      barcode: barcodeVal,
    );

    // Trigger list refresh
    ref.invalidate(productsProvider);

    if (mounted) {
      context.pop();
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: const Text(
            'هل أنت متأكد من حذف هذا المنتج؟ سيتم مسح البيانات ولا يمكن التراجع.'),
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

    if (confirmed == true && mounted) {
      final repo = ref.read(productRepositoryProvider);
      await repo.deleteProduct(_product!.id);
      ref.invalidate(productsProvider);
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isEditing && _product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تعديل المنتج')),
        body: const Center(child: Text('المنتج غير موجود')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل المنتج' : 'إضافة منتج جديد'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'حذف المنتج',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المنتج',
                hintText: 'أدخل اسم المنتج',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'الاسم مطلوب' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _units.contains(_unitController.text)
                  ? _unitController.text
                  : _units.first,
              decoration: const InputDecoration(
                labelText: 'الوحدة',
              ),
              items: _units
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _unitController.text = v ?? _units.first;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _retailPriceController,
              decoration: const InputDecoration(
                labelText: 'سعر المفرد (دينار)',
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'سعر المفرد مطلوب';
                if (double.tryParse(v) == null) return 'أدخل رقماً صحيحاً';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _wholesalePriceController,
              decoration: const InputDecoration(
                labelText: 'سعر الجملة (دينار) - اختياري',
                hintText: 'يُستخدم المفرد إن تُرك فارغاً',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(
                labelText: 'الكمية / الرصيد - اختياري',
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: 'الباركود',
                hintText: 'مسح أو إدخال يدوي',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanBarcode,
                  tooltip: 'مسح الباركود',
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ المنتج'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 50),
                ),
                onPressed: _save,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
