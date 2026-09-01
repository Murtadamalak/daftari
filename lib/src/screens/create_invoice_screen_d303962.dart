import 'package:daftar_debt_manager/src/core/widgets/app_bar_logo.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daftar_debt_manager/src/core/theme/google_fonts_mock.dart';
import 'package:intl/intl.dart';

import '../core/providers/settings_provider.dart';
import '../core/providers/app_providers.dart';
import '../core/providers/invoice_creation_provider.dart';
import '../core/providers/products_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_snackbar.dart';
import '../core/widgets/glass_container.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/invoice_repository.dart';
import 'barcode_scanner_screen.dart';
import 'customers_screen.dart';
import 'delayed_debts_screen.dart';
import '../core/providers/invoices_provider.dart';

// ظ¤ظ¤ظ¤ Number formatter ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤
final _fmt = NumberFormat('#,###');

/// Fetch all customers ظ¤ used in the customer-picker step.
final _customersStreamProvider =
    FutureProvider.autoDispose<List<CustomerModel>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getAllCustomers();
});

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({
    super.key,
    this.invoiceId,
  });

  /// If null ظْ ╪ح┘╪┤╪د╪ة ┘╪د╪ز┘ê╪▒╪ر ╪ش╪»┘è╪»╪ر.
  /// ╪ح╪░╪د ┘â╪د┘ ┘ç┘╪د┘â id ظْ ╪ز╪╣╪»┘è┘ ┘╪د╪ز┘ê╪▒╪ر ┘┘é╪»┘è╪ر ┘é╪د╪خ┘à╪ر.
  final String? invoiceId;

  bool get isEditing => invoiceId != null;

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  int _currentStep = 0;
  final _discountCtrl = TextEditingController();
  final _receivedCtrl = TextEditingController();

  bool _isSaving = false;

  // ╪ذ┘è╪د┘╪د╪ز ╪د┘┘╪د╪ز┘ê╪▒╪ر ╪د┘╪ث╪╡┘┘è╪ر ╪╣┘╪» ╪د┘╪ز╪╣╪»┘è┘ (┘╪│╪ز╪«╪»┘à┘ç╪د ┘╪ص╪│╪د╪ذ ┘╪▒┘ê┘é╪د╪ز ╪د┘┘à╪«╪▓┘ê┘)
  InvoiceModel? _originalInvoice;
  List<InvoiceItemModel> _originalItems = const [];

  @override
  void dispose() {
    _discountCtrl.dispose();
    _receivedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(invoiceCreationProvider);
    final isLastStep = _currentStep == 2;
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to show gradient
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF0A1612), const Color(0xFF13211D)]
                : [const Color(0xFFF7F5F0), const Color(0xFFEEEBE1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ظ¤ظ¤ Custom AppBar ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: SizedBox(
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const AppBarLogo(),
                      Align(
                        alignment: Alignment.centerRight, // RTL Close button on right side
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _confirmDiscard(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ظ¤ظ¤ Step indicator at top ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤
              _StepHeader(currentStep: _currentStep),

              // ظ¤ظ¤ Step content ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: KeyedSubtree(
                      key: ValueKey(_currentStep),
                      child: _currentStep == 0
                          ? _CustomerStep()
                          : _currentStep == 1
                              ? _ProductsStep()
                              : _PaymentStep(
                                  discountCtrl: _discountCtrl,
                                  receivedCtrl: _receivedCtrl,
                                  isEditing: widget.isEditing,
                                  originalInvoice: _originalInvoice,
                                ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ظ¤ظ¤ Bottom action bar ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤
      bottomNavigationBar: _BottomActionBar(
        currentStep: _currentStep,
        isLastStep: isLastStep,
        itemCount: invoiceState.items.length,
        grandTotal: invoiceState.grandTotal,
        onNext: _onNext,
        onBack: () => setState(() => _currentStep -= 1),
        isSaving: _isSaving,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadExistingInvoice();
    }
  }

  Future<void> _loadExistingInvoice() async {
    try {
      final repo = ref.read(invoiceRepositoryProvider);
      final inv =
          await repo.getById(widget.invoiceId!); // must exist in normal flow
      if (inv == null) {
        if (mounted) {
          Navigator.of(context).pop();
          AppSnackBar.error(context, '╪ز╪╣╪░┘ّ╪▒ ╪ز╪ص┘à┘è┘ ╪د┘┘╪د╪ز┘ê╪▒╪ر');
        }
        return;
      }

      // ┘╪د ┘╪│┘à╪ص ╪ذ╪ز╪╣╪»┘è┘ ┘┘ê╪د╪ز┘è╪▒ ╪د┘╪ز╪│╪»┘è╪» ┘┘é╪╖ (┘┘è╪│╪ز ┘à╪ذ┘è╪╣╪د╪ز)
      if (inv.payType == '╪ز╪│╪»┘è╪» ╪»┘è┘') {
        if (mounted) {
          Navigator.of(context).pop();
          AppSnackBar.error(
            context,
            '┘╪د ┘è┘à┘â┘ ╪ز╪╣╪»┘è┘ ┘┘ê╪د╪ز┘è╪▒ ╪ز╪│╪»┘è╪» ╪د┘╪»┘è┘╪î ╪╣╪»┘ّ┘ ┘╪د╪ز┘ê╪▒╪ر ╪د┘┘à╪ذ┘è╪╣╪د╪ز ╪د┘╪ث╪╡┘┘è╪ر.',
          );
        }
        return;
      }

      final items = await repo.getItemsByInvoiceId(inv.id);
      final productsRepo = ref.read(productRepositoryProvider);
      final allProducts = await productsRepo.getAllProducts();

      // ╪ص┘ê┘ّ┘ ╪╣┘╪د╪╡╪▒ ╪د┘┘╪د╪ز┘ê╪▒╪ر ╪ح┘┘ë CartItem ╪»╪د╪«┘ ╪ص╪د┘╪ر ╪ح┘╪┤╪د╪ة ╪د┘┘╪د╪ز┘ê╪▒╪ر
      final cartItems = <CartItem>[];
      for (final it in items) {
        // ┘╪ص╪د┘ê┘ ╪ح┘è╪ش╪د╪» ╪د┘┘à┘╪ز╪ش ╪ذ┘┘╪│ ╪د┘╪د╪│┘à ┘┘┘ê╪╡┘ê┘ ┘┘┘à╪«╪▓┘ê┘ ┘ê┘à╪╣╪▒┘ّ┘ ╪د┘┘à┘╪ز╪ش
        final match = allProducts.firstWhere(
          (p) => p.name == it.productName,
          orElse: () => ProductModel(
            id: '',
            name: it.productName,
            unit: it.unit,
            retailPrice: it.unitPrice,
            wholesalePrice: it.priceType == 'wholesale' ? it.unitPrice : null,
            stock: null,
            createdAt: DateTime.now(),
          ),
        );
        cartItems.add(
          CartItem(
            product: match,
            quantity: it.qty,
            isWholesale: it.priceType == 'wholesale',
            note: it.note,
          ),
        );
      }

      final notifier = ref.read(invoiceCreationProvider.notifier);
      notifier.clear();
      notifier.setDiscount(
          inv.discount); // ╪│┘è┘╪╣╪د╪» ╪د╪ص╪ز╪│╪د╪ذ ╪د┘╪ح╪ش┘à╪د┘┘è ╪ز┘┘é╪د╪خ┘è╪د┘ï ┘┘è┘à╪د ╪ذ╪╣╪»

      // ╪ز╪╣╪ذ╪خ╪ر ╪د┘╪▓╪ذ┘ê┘ ┘┘è ╪ص╪د┘╪ر ╪د┘╪ز╪╣╪»┘è┘ (╪ح┘ ┘ê╪ش╪»)
      if (inv.customerId != null) {
        final custRepo = ref.read(customerRepositoryProvider);
        final customer = await custRepo.getById(inv.customerId!);
        if (customer != null) {
          notifier.setCustomer(customer);
        }
      }

      // ┘╪╢╪ذ╪╖ ╪╖╪▒┘è┘é╪ر ╪د┘╪»┘╪╣ ┘ê╪ص┘é┘ "╪د┘┘à╪ذ┘╪║ ╪د┘┘à╪»┘┘ê╪╣ ╪╣┘╪» ╪ح┘╪┤╪د╪ة ╪د┘┘╪د╪ز┘ê╪▒╪ر" ┘┘è ╪د┘╪ص╪د┘╪ر
      if (inv.payType == 'cash') {
        notifier.setPaymentMethod(PaymentMethod.cash);
      } else if (inv.payType == 'debt') {
        notifier.setPaymentMethod(PaymentMethod.debt);
      } else {
        notifier.setPaymentMethod(PaymentMethod.partial);
      }
      // ┘╪│╪ز╪«╪»┘à ╪د┘┘à╪ذ┘╪║ ╪د┘┘à╪»┘┘ê╪╣ ╪د┘┘â┘┘è (grandTotal - debt) ╪ذ╪»┘╪د┘ï ┘à┘ ╪د┘╪»┘╪╣╪ر ╪د┘╪ث┘ê┘┘ë ┘┘é╪╖
      final totalPaid = inv.currentPaid;
      notifier.setReceivedAmount(totalPaid);

      // ┘╪ص┘é┘ ╪د┘╪╣┘╪د╪╡╪▒ ┘┘è ╪د┘╪ص╪د┘╪ر
      for (final c in cartItems) {
        notifier.addProduct(c.product);
        notifier.updateQuantity(c.product.id, c.quantity);
        notifier.togglePriceType(c.product.id, c.isWholesale);
        if (c.note.isNotEmpty) {
          notifier.updateNote(c.product.id, c.note);
        }
      }

      _discountCtrl.text =
          inv.discount == 0 ? '' : inv.discount.toStringAsFixed(0);
      _receivedCtrl.text = totalPaid == 0 ? '' : totalPaid.toStringAsFixed(0);

      _originalInvoice = inv;
      _originalItems = items;
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.error(context, '╪«╪╖╪ث ╪ث╪س┘╪د╪ة ╪ز╪ص┘à┘è┘ ╪د┘┘╪د╪ز┘ê╪▒╪ر: $e');
      }
    }
  }

  void _onNext() {
    final state = ref.read(invoiceCreationProvider);
    if (_currentStep == 1 && state.items.isEmpty) {
      _showToast('╪ث╪╢┘ ┘à┘╪ز╪ش╪د┘ï ┘ê╪د╪ص╪»╪د┘ï ╪╣┘┘ë ╪د┘╪ث┘é┘');
      return;
    }
    if (_currentStep == 2) {
      if (!widget.isEditing &&
          state.paymentMethod == PaymentMethod.partial &&
          (state.receivedAmount == null || state.receivedAmount! <= 0)) {
        _showToast('╪ث╪»╪«┘ ╪د┘┘à╪ذ┘╪║ ╪د┘┘à╪│╪ز┘┘à');
        return;
      }
      if (widget.isEditing) {
        final totalPaid = state.receivedAmount ?? 0.0;
        final total = state.grandTotal;
        if (totalPaid > total + 0.01) {
          _showToast(
              '╪د┘┘à╪ذ┘╪║ ╪د┘┘à╪»┘┘ê╪╣ ╪د┘┘â┘┘è ┘╪د ┘è┘à┘â┘ ╪ث┘ ┘è┘â┘ê┘ ╪ث┘â╪ذ╪▒ ┘à┘ ┘é┘è┘à╪ر ╪د┘┘╪د╪ز┘ê╪▒╪ر.');
          return;
        }
      }
      if (widget.isEditing) {
        _saveEditedInvoice();
      } else {
        _saveInvoice();
      }
    } else {
      setState(() => _currentStep += 1);
    }
  }

  void _showToast(String msg) {
    AppSnackBar.warning(context, msg);
  }

  Future<void> _confirmDiscard(BuildContext context) async {
    final state = ref.read(invoiceCreationProvider);
    if (state.items.isEmpty && state.customer == null) {
      Navigator.of(context).pop();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('╪ز╪ش╪د┘ç┘ ╪د┘┘╪د╪ز┘ê╪▒╪ر╪ا'),
        content: const Text('╪│┘è╪ز┘à ╪ص╪░┘ ╪ش┘à┘è╪╣ ╪د┘╪ذ┘è╪د┘╪د╪ز ╪د┘┘à╪»╪«┘╪ر.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('╪ح┘╪║╪د╪ة')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('╪ز╪ش╪د┘ç┘'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      ref.read(invoiceCreationProvider.notifier).clear();
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveInvoice() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final invoiceNotifier = ref.read(invoiceCreationProvider.notifier);
      final invoiceState = ref.read(invoiceCreationProvider);
      final repo = ref.read(invoiceRepositoryProvider);
      final settings =
          ref.read(settingsProvider).valueOrNull ?? const AppSettings();

      double paid = 0, debt = 0;
      String status = 'paid';

      if (invoiceState.paymentMethod == PaymentMethod.cash) {
        paid = invoiceState.grandTotal;
      } else if (invoiceState.paymentMethod == PaymentMethod.debt) {
        debt = invoiceState.grandTotal;
        status = 'unpaid';
      } else {
        paid = invoiceState.receivedAmount!;
        debt = invoiceState.grandTotal - paid;
        status = 'partial';
      }

      final customer = invoiceState.customer;

      final items = invoiceState.items.map((item) {
        final displayName = item.note.trim().isNotEmpty
            ? '${item.product.name} [${item.note.trim()}]'
            : item.product.name;
        return <String, dynamic>{
          'product_name': displayName,
          'unit': item.product.unit,
          'qty': item.quantity,
          'unit_price': item.effectivePrice,
          'price_type': item.isWholesale ? 'wholesale' : 'retail',
          'total': item.total,
        };
      }).toList();

      double? additionalDebt;
      if (customer != null) {
        if (invoiceState.paymentMethod == PaymentMethod.debt) {
          additionalDebt = invoiceState.grandTotal;
        } else if (invoiceState.paymentMethod == PaymentMethod.partial) {
          additionalDebt = debt;
        }
      }

      await repo.createInvoice(
        customerName: customer?.name ?? '╪▓╪ذ┘ê┘ ┘┘é╪»┘è',
        customerId: customer?.id,
        customerPhone: customer?.phone,
        subtotal: invoiceState.subtotal,
        discount: invoiceState.discount,
        grandTotal: invoiceState.grandTotal,
        paid: paid,
        debt: debt,
        payType: invoiceState.paymentMethod.name,
        status: status,
        shopName: settings.shopName,
        shopPhone: settings.shopPhone,
        ownerName: settings.ownerName,
        shopLogoPath: settings.logoPath,
        items: items,
        additionalDebt: additionalDebt,
      );

      // Decrement stock for the items sold
      final productRepo = ref.read(productRepositoryProvider);
      final productsToDecrease = invoiceState.items
          .where((item) =>
              item.product.id.isNotEmpty) // Make sure it's a saved product
          .map((item) => {
                'productId': item.product.id,
                'quantity': item.quantity,
              })
          .toList();

      if (productsToDecrease.isNotEmpty) {
        await productRepo.decreaseStockBulk(productsToDecrease);
      }

      // Refresh data
      ref.invalidate(productsProvider);
      ref.invalidate(debtSearchDataProvider);
      ref.invalidate(delayedCustomersProvider);
      ref.invalidate(allInvoicesProvider);

      invoiceNotifier.clear();
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.success(context, '╪ز┘à ╪ص┘╪╕ ╪د┘┘╪د╪ز┘ê╪▒╪ر ╪ذ┘╪ش╪د╪ص ظ£ô');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showToast('╪«╪╖╪ث ╪ث╪س┘╪د╪ة ╪د┘╪ص┘╪╕: $e');
      }
    }
  }

  /// ╪ص┘╪╕ ╪د┘╪ز╪╣╪»┘è┘╪د╪ز ╪╣┘┘ë ┘╪د╪ز┘ê╪▒╪ر ┘┘é╪»┘è╪ر ┘é╪د╪خ┘à╪ر ┘à╪╣ ╪╢╪ذ╪╖ ╪د┘┘à╪«╪▓┘ê┘ ╪ذ╪»┘ê┘ ╪د┘╪ز╪ث╪س┘è╪▒ ╪╣┘┘ë ╪»┘è┘ê┘ ┘é╪»┘è┘à╪ر.
  Future<void> _saveEditedInvoice() async {
    if (_isSaving || _originalInvoice == null) return;
    setState(() => _isSaving = true);

    try {
      final invoiceState = ref.read(invoiceCreationProvider);
      final repo = ref.read(invoiceRepositoryProvider);

      // ┘╪ص╪│╪ذ ╪د┘╪ح╪ش┘à╪د┘┘è╪د╪ز ╪د┘╪ش╪»┘è╪»╪ر ╪ذ┘╪د╪ة┘ï ╪╣┘┘ë ╪ص╪د┘╪ر ╪د┘╪ح┘╪┤╪د╪ة ╪د┘╪ص╪د┘┘è╪ر
      final subtotal = invoiceState.subtotal;
      final discount = invoiceState.discount;
      final grandTotal = invoiceState.grandTotal;

      final original = _originalInvoice!;

      // ╪د┘┘à╪ذ┘╪║ ╪د┘┘à╪»┘┘ê╪╣ ╪د┘┘â┘┘è ╪د┘╪░┘è ┘è╪▒┘è╪»┘ç ╪د┘┘à╪│╪ز╪«╪»┘à (┘è╪┤┘à┘ ┘â┘ ╪د┘╪»┘╪╣╪د╪ز)
      final desiredTotalPaid = invoiceState.receivedAmount ?? original.currentPaid;

      // ┘╪ص╪│╪ذ ┘à╪ش┘à┘ê╪╣ ╪»┘╪╣╪د╪ز ╪د┘╪ز╪│╪»┘è╪» ╪د┘┘à┘┘╪╡┘╪ر (╪│╪ش┘╪د╪ز '╪ز╪│╪»┘è╪» ╪»┘è┘')
      // ╪ص╪ز┘ë ┘╪د ┘┘â╪▒╪▒┘ç╪د ╪╣┘╪» ╪ح╪╣╪د╪»╪ر ╪د╪ص╪ز╪│╪د╪ذ ╪د┘╪»┘è┘ê┘
      double extraPayments = 0.0;
      if (original.customerId != null) {
        final paymentRecords = await repo.getPaymentRecordsByCustomer(original.customerId!);
        extraPayments = paymentRecords.fold(0.0, (sum, p) => sum + p.paid);
      }

      // ╪د┘┘ paid ┘┘è ┘é╪د╪╣╪»╪ر ╪د┘╪ذ┘è╪د┘╪د╪ز = ╪د┘┘à╪ذ┘╪║ ╪د┘┘à╪»┘┘ê╪╣ ╪د┘┘â┘┘è - ╪»┘╪╣╪د╪ز ╪د┘╪ز╪│╪»┘è╪» ╪د┘┘à┘┘╪╡┘╪ر
      // ┘╪ث┘ recalculateCustomerDebt ╪│╪ز╪╢┘è┘ ╪»┘╪╣╪د╪ز ╪د┘╪ز╪│╪»┘è╪» ╪ز┘┘é╪د╪خ┘è╪د┘ï
      var paidForDb = desiredTotalPaid - extraPayments;
      if (paidForDb < 0) paidForDb = 0;
      if (paidForDb > grandTotal) paidForDb = grandTotal;

      // ╪د┘╪»┘è┘ ┘è┘╪ص╪│╪ذ ╪ذ╪╣╪» recalculateCustomerDebt ┘┘â┘ ┘╪╢╪╣ ┘é┘è┘à╪ر ┘à╪ذ╪»╪خ┘è╪ر
      var debt = grandTotal - paidForDb;
      if (debt < 0) debt = 0;

      String status;
      String payType;
      if (debt <= 0.01 && extraPayments <= 0.01) {
        // ┘à╪»┘┘ê╪╣ ╪ذ╪د┘┘â╪د┘à┘ ┘à┘ ╪د┘╪ذ╪»╪د┘è╪ر (╪ذ╪»┘ê┘ ╪ز╪│╪»┘è╪»╪د╪ز)
        status = 'paid';
        payType = 'cash';
      } else if (paidForDb <= 0.01 && extraPayments <= 0.01) {
        // ┘┘à ┘è┘╪»┘╪╣ ╪┤┘è╪ة
        status = 'unpaid';
        payType = 'debt';
      } else {
        // ╪»┘╪╣ ╪ش╪▓╪خ┘è
        status = 'partial';
        payType = 'partial';
      }

      // ┘╪ذ┘┘è ╪د┘╪╣┘╪د╪╡╪▒ ╪د┘╪ش╪»┘è╪»╪ر ╪ذ┘┘╪│ ╪┤┘â┘ ╪د┘╪ح┘╪┤╪د╪ة ╪د┘╪╣╪د╪»┘è
      final items = invoiceState.items.map((item) {
        final displayName = item.note.trim().isNotEmpty
            ? '${item.product.name} [${item.note.trim()}]'
            : item.product.name;
        return <String, dynamic>{
          'product_name': displayName,
          'unit': item.product.unit,
          'qty': item.quantity,
          'unit_price': item.effectivePrice,
          'price_type': item.isWholesale ? 'wholesale' : 'retail',
          'total': item.total,
        };
      }).toList();

      await repo.updateCashInvoiceWithItems(
        original: original,
        originalItems: _originalItems,
        customerId: invoiceState.customer?.id,
        customerName: invoiceState.customer?.name ?? '╪▓╪ذ┘ê┘ ┘┘é╪»┘è',
        customerPhone: invoiceState.customer?.phone,
        subtotal: subtotal,
        discount: discount,
        grandTotal: grandTotal,
        paid: paidForDb,
        debt: debt,
        status: status,
        payType: payType,
        items: items,
      );

      ref.read(invoiceCreationProvider.notifier).clear();
      ref.invalidate(productsProvider);
      ref.invalidate(debtSearchDataProvider);
      ref.invalidate(delayedCustomersProvider);
      ref.invalidate(allInvoicesProvider);

      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.success(context, '╪ز┘à ╪ص┘╪╕ ╪د┘╪ز╪╣╪»┘è┘╪د╪ز ╪╣┘┘ë ╪د┘┘╪د╪ز┘ê╪▒╪ر ظ£ô');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showToast('╪«╪╖╪ث ╪ث╪س┘╪د╪ة ╪ص┘╪╕ ╪د┘╪ز╪╣╪»┘è┘: $e');
      }
    }
  }
}

// ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤
// Step Header
// ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.currentStep});
  final int currentStep;

  static const _steps = ['╪د┘╪▓╪ذ┘ê┘', '╪د┘┘à┘╪ز╪ش╪د╪ز', '╪د┘╪»┘╪╣'];
  static const _icons = [
    Icons.person_outline,
    Icons.shopping_cart_outlined,
    Icons.payments_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final inactiveColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);
    final activeTextColor = isDark ? Colors.white : primary;
    final inactiveTextColor = isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4);

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = i ~/ 2;
            final isPast = currentStep > stepIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isPast
                    ? primary.withOpacity(0.8)
                    : inactiveTextColor.withOpacity(0.2),
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isActive = currentStep == stepIndex;
          final isPast = currentStep > stepIndex;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive
                      ? primary
                      : isPast
                          ? primary.withOpacity(0.15)
                          : inactiveColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? Colors.transparent : primary.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isPast ? Icons.check : _icons[stepIndex],
                  size: 20,
                  color: isActive
                      ? Colors.white
                      : isPast
                          ? primary
                          : inactiveTextColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _steps[stepIndex],
                style: TextStyle(
                  fontFamily: 'KOMedia',
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w400,
                  color: isActive ? activeTextColor : inactiveTextColor,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤
// Bottom Action Bar
// ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.currentStep,
    required this.isLastStep,
    required this.itemCount,
    required this.grandTotal,
    required this.onNext,
    required this.onBack,
    this.isSaving = false,
  });

  final int currentStep;
  final bool isLastStep;
  final int itemCount;
  final double grandTotal;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(24),
      child: Row(
        children: [
          // ظ¤ظ¤ Back button ظ¤ظ¤
          if (currentStep > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: OutlinedButton.icon(
                onPressed: isSaving ? null : onBack,
                icon: const Icon(Icons.arrow_forward_ios, size: 14),
                label: const Text(
                  '╪▒╪ش┘ê╪╣',
                  style: TextStyle(fontFamily: 'KOMedia'),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(100, 50),
                ),
              ),
            ),

          // ظ¤ظ¤ Next / Save button ظ¤ظ¤
          Expanded(
            child: FilledButton.icon(
              onPressed: isSaving ? null : onNext,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isLastStep ? Icons.save_outlined : Icons.arrow_back_ios,
                      size: 16),
              label: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isSaving
                        ? '╪ش╪د╪▒┘è ╪د┘╪ص┘╪╕...'
                        : (isLastStep ? '╪ص┘╪╕ ╪د┘┘╪د╪ز┘ê╪▒╪ر' : '╪د┘╪ز╪د┘┘è'),
                    style: const TextStyle(fontFamily: 'KOMedia'),
                  ),
                  if (currentStep == 1 && itemCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$itemCount ظت ${_fmt.format(grandTotal)} IQD',
                        style: const TextStyle(
                          fontFamily: 'KOMedia',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤
// Step 1: Customer
// ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤

class _CustomerStep extends ConsumerWidget {
  const _CustomerStep();

  Future<void> _pickCustomer(BuildContext context, WidgetRef ref) async {
    final customers = await ref.read(_customersStreamProvider.future);
    if (!context.mounted) return;

    final result = await showModalBottomSheet<CustomerModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerSearchPicker(customers: customers),
    );
    if (result != null) {
      ref.read(invoiceCreationProvider.notifier).setCustomer(result);
    }
  }

  Future<void> _showAddCustomerDialog(
      BuildContext context, WidgetRef ref) async {
    final result = await showDialog<CustomerModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AddCustomerDialog(),
    );
    if (result != null) {
      ref.invalidate(_customersStreamProvider);
      await ref.read(_customersStreamProvider.future);

      if (context.mounted) {
        ref.read(invoiceCreationProvider.notifier).setCustomer(result);
        AppSnackBar.success(context, '╪ز┘à╪ز ╪ح╪╢╪د┘╪ر ${result.name} ╪ذ┘╪ش╪د╪ص ظ£ô');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceNotifier = ref.read(invoiceCreationProvider.notifier);
    final invoiceState = ref.watch(invoiceCreationProvider);
    final isCashOnly = invoiceState.customer == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCashOnly) ...[
          // ظ¤ظ¤ Cash customer card ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤
          _QuickOptionCard(
            icon: Icons.payments_outlined,
            iconColor: AppColors.success,
            title: '╪▓╪ذ┘ê┘ ┘┘é╪»┘è',
            subtitle: '╪ذ╪»┘ê┘ ╪ص╪│╪د╪ذ ┘à╪│╪ش┘ّ┘',
            isSelected: true,
            onTap: () => invoiceNotifier.setCustomer(null),
          ),

          const SizedBox(height: 16),

          // ظ¤ظ¤ Selection Buttons ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.person_search_outlined,
                  label: '╪ذ╪ص╪س ╪╣┘ ╪▓╪ذ┘ê┘',
                  color: AppColors.primary,
                  onTap: () => _pickCustomer(context, ref),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.person_add_outlined,
                  label: '╪ح╪╢╪د┘╪ر ╪▓╪ذ┘ê┘',
                  color: AppColors.accent,
                  onTap: () => _showAddCustomerDialog(context, ref),
                ),
              ),
            ],
          ),
        ] else ...[
          // ظ¤ظ¤ Selected customer info ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤
          Padding(
            padding: const EdgeInsets.only(bottom: 12, right: 4),
            child: Text(
              '╪د┘╪▓╪ذ┘ê┘ ╪د┘┘à╪«╪ز╪د╪▒:',
              style: GoogleFonts.almarai(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _CustomerInfoCard(
            customer: invoiceState.customer!,
            onClear: () => invoiceNotifier.setCustomer(null),
            onChange: () => _pickCustomer(context, ref),
          ),
        ],
      ],
    );
  }
}

// ظ¤ظ¤ Quick option card ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤

class _QuickOptionCard extends StatelessWidget {
  const _QuickOptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBorderColor = AppColors.primary;
    final inactiveBorderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: isDark
                      ? [AppColors.primary.withOpacity(0.25), AppColors.primary.withOpacity(0.08)]
                      : [AppColors.primary.withOpacity(0.08), AppColors.primary.withOpacity(0.02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeBorderColor : inactiveBorderColor,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.08 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isSelected ? AppColors.primary : iconColor).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? AppColors.primary : iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'KOMedia',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isSelected ? AppColors.primary : (isDark ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

// ظ¤ظ¤ Customer Search Picker Bottom Sheet ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤

class _CustomerSearchPicker extends StatefulWidget {
  const _CustomerSearchPicker({required this.customers});
  final List<CustomerModel> customers;

  @override
  State<_CustomerSearchPicker> createState() => _CustomerSearchPickerState();
}

class _CustomerSearchPickerState extends State<_CustomerSearchPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _query.isEmpty
        ? widget.customers
        : widget.customers.where((c) {
            final q = _query.toLowerCase();
            return c.name.toLowerCase().contains(q) ||
                (c.phone != null && c.phone!.contains(q));
          }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        children: [
          // Header Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '╪د╪«╪ز╪▒ ╪▓╪ذ┘ê┘╪د┘ï',
                    style: GoogleFonts.almarai(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: '╪ذ╪ص╪س ╪ذ╪د╪│┘à ╪د┘╪▓╪ذ┘ê┘ ╪ث┘ê ╪▒┘é┘à ╪د┘┘ç╪د╪ز┘...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Search Results
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search,
                            size: 64, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('┘╪د ╪ز┘ê╪ش╪» ┘╪ز╪د╪خ╪ش',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      return _CustomerGridItem(
                        customer: c,
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CustomerGridItem extends StatelessWidget {
  const _CustomerGridItem({required this.customer, required this.onTap});
  final CustomerModel customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDebt = customer.totalDebt > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasDebt
                ? AppColors.danger.withOpacity(0.3)
                : AppColors.border.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (hasDebt ? AppColors.danger : AppColors.primary)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: hasDebt ? AppColors.danger : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              customer.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.almarai(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasDebt) ...[
              const SizedBox(height: 4),
              Text(
                NumberFormat('#,###').format(customer.totalDebt),
                style: GoogleFonts.almarai(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.danger,
                ),
              ),
              Text(
                '╪»┘è┘ ┘à╪│╪ز╪ص┘é',
                style: GoogleFonts.almarai(
                  fontSize: 10,
                  color: AppColors.danger.withOpacity(0.8),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '┘╪د ┘è┘ê╪ش╪» ╪»┘è┘ê┘',
                  style: GoogleFonts.almarai(
                    fontSize: 10,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ظ¤ظ¤ Add Customer Dialog ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤

class _AddCustomerDialog extends ConsumerStatefulWidget {
  const _AddCustomerDialog();

  @override
  ConsumerState<_AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends ConsumerState<_AddCustomerDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person_add_outlined, color: AppColors.primary),
          SizedBox(width: 10),
          Text(
            '╪▓╪ذ┘ê┘ ╪ش╪»┘è╪»',
            style: TextStyle(fontFamily: 'KOMedia'),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '╪د┘╪د╪│┘à ┘à╪╖┘┘ê╪ذ' : null,
              decoration: const InputDecoration(
                labelText: '╪د╪│┘à ╪د┘╪▓╪ذ┘ê┘ *',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: '╪▒┘é┘à ╪د┘┘ç╪د╪ز┘ (╪د╪«╪ز┘è╪د╪▒┘è)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        OutlinedButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text(
            '╪ح┘╪║╪د╪ة',
            style: TextStyle(fontFamily: 'KOMedia'),
          ),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text(
                  '╪ص┘╪╕ ┘ê╪د╪«╪ز╪▒',
                  style: TextStyle(fontFamily: 'KOMedia'),
                ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(customerRepositoryProvider);
      final saved = await repo.upsertCustomer(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) AppSnackBar.error(context, '╪«╪╖╪ث ╪ث╪س┘╪د╪ة ╪د┘╪ص┘╪╕: $e');
    }
  }
}

class _CustomerInfoCard extends StatelessWidget {
  const _CustomerInfoCard({
    required this.customer,
    required this.onClear,
    required this.onChange,
  });
  final CustomerModel customer;
  final VoidCallback onClear;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: TextStyle(
                    fontFamily: 'KOMedia',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (customer.phone != null)
                  Text(
                    customer.phone!,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                if (customer.totalDebt > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '╪»┘è┘ ╪ص╪د┘┘è: ${NumberFormat('#,###').format(customer.totalDebt)} IQD',
                    style: const TextStyle(
                      fontFamily: 'KOMedia',
                      color: AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Change Button
              InkWell(
                onTap: onChange,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sync_alt_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Clear Button
              InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.danger,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤
// Step 2: Products
// ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤

class _ProductsStep extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceNotifier = ref.read(invoiceCreationProvider.notifier);
    final invoiceState = ref.watch(invoiceCreationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ظ¤ظ¤ Action buttons ظ¤ظ¤
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.qr_code_scanner,
                label: '┘à╪│╪ص ╪ذ╪د╪▒┘â┘ê╪»',
                color: AppColors.primary,
                onTap: () => _scanBarcode(context, ref),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.playlist_add,
                label: '╪د╪«╪ز┘è╪د╪▒ ┘à┘╪ز╪ش',
                color: AppColors.accent,
                onTap: () => _pickProduct(context, ref),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ظ¤ظ¤ Cart items ظ¤ظ¤
        if (invoiceState.items.isEmpty)
          _EmptyCartHint()
        else ...[
          // Summary header
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${invoiceState.items.length} ┘à┘╪ز╪ش╪د╪ز ┘┘è ╪د┘╪│┘╪ر',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontFamily: 'KOMedia')),
                Text(
                  '╪د┘╪ح╪ش┘à╪د┘┘è: ${_fmt.format(invoiceState.subtotal)} IQD',
                  style: const TextStyle(
                      fontFamily: 'KOMedia',
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
                ),
              ],
            ),
          ),
          ...invoiceState.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CartItemCard(
                item: item,
                onRemove: () => invoiceNotifier.removeProduct(item.product.id),
                onQtyChange: (q) =>
                    invoiceNotifier.updateQuantity(item.product.id, q),
                onPriceTypeChange: (w) =>
                    invoiceNotifier.togglePriceType(item.product.id, w),
                onNoteChange: (n) =>
                    invoiceNotifier.updateNote(item.product.id, n),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _scanBarcode(BuildContext context, WidgetRef ref) async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code == null) return;
    final repo = ref.read(productRepositoryProvider);
    final all = await repo.getAllProducts();
    final match = all.where((p) => p.barcode == code).firstOrNull;
    if (match != null) {
      ref.read(invoiceCreationProvider.notifier).addProduct(match);
      if (context.mounted) {
        AppSnackBar.success(context, '╪ز┘à╪ز ╪ح╪╢╪د┘╪ر ${match.name}');
      }
    } else {
      if (context.mounted) {
        AppSnackBar.error(context, '╪د┘┘à┘╪ز╪ش ╪║┘è╪▒ ┘à┘ê╪ش┘ê╪» ┘┘è ┘é╪د╪╣╪»╪ر ╪د┘╪ذ┘è╪د┘╪د╪ز');
      }
    }
  }

  Future<void> _pickProduct(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(productRepositoryProvider);
    final allProducts = await repo.getAllProducts();
    if (!context.mounted) return;

    final selected = await showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductPickerSheet(products: allProducts),
    );
    if (selected != null) {
      ref.read(invoiceCreationProvider.notifier).addProduct(selected);
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isDark ? 0.05 : 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'KOMedia',
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCartHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.05 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 56,
            color: isDark ? AppColors.darkTextSecondary.withOpacity(0.4) : AppColors.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            '╪د┘╪│┘╪ر ┘╪د╪▒╪║╪ر',
            style: TextStyle(
              fontFamily: 'KOMedia',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '╪د┘à╪│╪ص ╪د┘╪ذ╪د╪▒┘â┘ê╪» ╪ث┘ê ╪د╪«╪ز╪▒ ┘à┘╪ز╪ش╪د┘ï',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatefulWidget {
  const _CartItemCard({
    required this.item,
    required this.onRemove,
    required this.onQtyChange,
    required this.onPriceTypeChange,
    required this.onNoteChange,
  });

  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<double> onQtyChange;
  final ValueChanged<bool> onPriceTypeChange;
  final ValueChanged<String> onNoteChange;

  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard> {
  late TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.item.note);
  }

  @override
  void didUpdateWidget(covariant _CartItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.product.id != oldWidget.item.product.id) {
      _noteCtrl.text = widget.item.note;
    } else if (widget.item.note != oldWidget.item.note && widget.item.note != _noteCtrl.text) {
      _noteCtrl.text = widget.item.note;
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasWholesale = widget.item.product.wholesalePrice != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.08 : 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ظ¤ظ¤ Product name + remove ظ¤ظ¤
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.item.product.name,
                  style: TextStyle(
                    fontFamily: 'KOMedia',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onRemove,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ظ¤ظ¤ Item Note Input Field ظ¤ظ¤
          TextFormField(
            controller: _noteCtrl,
            onChanged: widget.onNoteChange,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Cairo',
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              hintText: '╪ث╪╢┘ ┘à┘╪د╪ص╪╕╪ر ┘┘ç╪░╪د ╪د┘┘à┘╪ز╪ش...',
              hintStyle: TextStyle(
                fontSize: 11,
                fontFamily: 'Cairo',
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              prefixIcon: const Icon(Icons.edit_note, size: 18, color: AppColors.primary),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.withOpacity(0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ظ¤ظ¤ Price type + quantity ظ¤ظ¤
          Row(
            children: [
              // Price type toggle
              if (hasWholesale)
                _PriceTypeToggle(
                  isWholesale: widget.item.isWholesale,
                  onChanged: widget.onPriceTypeChange,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '┘à┘╪▒╪»',
                    style: TextStyle(
                      fontFamily: 'KOMedia',
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

              const Spacer(),

              // Quantity stepper
              _QuantityStepper(
                quantity: widget.item.quantity,
                onDecrease: () => widget.onQtyChange(widget.item.quantity - 1),
                onIncrease: () => widget.onQtyChange(widget.item.quantity + 1),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: isDark ? AppColors.darkDivider : AppColors.divider, height: 1),
          const SizedBox(height: 12),

          // ظ¤ظ¤ Price summary ظ¤ظ¤
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_fmt.format(widget.item.effectivePrice)} IQD ├ù ${widget.item.quantity.toStringAsFixed(widget.item.quantity == widget.item.quantity.truncate() ? 0 : 2)}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                '${_fmt.format(widget.item.total)} IQD',
                style: const TextStyle(
                  fontFamily: 'KOMedia',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceTypeToggle extends StatelessWidget {
  const _PriceTypeToggle({
    required this.isWholesale,
    required this.onChanged,
  });
  final bool isWholesale;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkDivider : AppColors.divider,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(
            label: '┘à┘╪▒╪»',
            isActive: !isWholesale,
            onTap: () => onChanged(false),
          ),
          _Tab(
            label: '╪ش┘à┘╪ر',
            isActive: isWholesale,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'KOMedia',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isActive
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });
  final double quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepBtn(icon: Icons.remove, onTap: onDecrease),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            quantity.toStringAsFixed(quantity == quantity.truncate() ? 0 : 2),
            style: const TextStyle(
              fontFamily: 'KOMedia',
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        _StepBtn(icon: Icons.add, onTap: onIncrease),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}

// ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤
// Product Picker Bottom Sheet
// ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤

// ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤
// Product Picker Bottom Sheet
// ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤

class _ProductPickerSheet extends ConsumerStatefulWidget {
  const _ProductPickerSheet({required this.products});
  final List<ProductModel> products;

  @override
  ConsumerState<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  String _query = '';
  late List<ProductModel> _localProducts;

  @override
  void initState() {
    super.initState();
    _localProducts = widget.products;
  }

  Future<void> _quickAddProduct(BuildContext context) async {
    final repo = ref.read(productRepositoryProvider);
    final newProduct = await showDialog<ProductModel>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddProductDialog(
        onSave: (name, retail, wholesale, unit, barcode, stock) async {
          final saved = await repo.upsertProduct(
            name: name,
            retailPrice: retail,
            wholesalePrice: wholesale,
            unit: unit,
            barcode: barcode,
            stock: stock,
          );
          ref.invalidate(productsProvider);
          return saved;
        },
      ),
    );

    if (newProduct != null && mounted) {
      Navigator.of(context).pop(newProduct);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _query.isEmpty
        ? _localProducts
        : _localProducts
            .where((p) =>
                p.name.toLowerCase().contains(_query.toLowerCase()) ||
                (p.barcode?.toLowerCase().contains(_query.toLowerCase()) ??
                    false))
            .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '╪د╪«╪ز╪▒ ┘à┘╪ز╪ش╪د┘ï',
                    style: GoogleFonts.almarai(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _quickAddProduct(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    '┘à┘╪ز╪ش ╪ش╪»┘è╪»',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: '╪ذ╪ص╪س ┘┘è ╪د┘┘à┘╪ز╪ش╪د╪ز...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      '┘╪د ╪ز┘ê╪ش╪» ┘╪ز╪د╪خ╪ش',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.border.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 22),
                          ),
                          title: Text(
                            p.name,
                            style: const TextStyle(
                              fontFamily: 'KOMedia',
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${_fmt.format(p.retailPrice)} IQD',
                              style: const TextStyle(
                                fontFamily: 'KOMedia',
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          trailing: const Icon(Icons.add_circle, color: AppColors.primary, size: 30),
                          onTap: () => Navigator.of(context).pop(p),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AddProductDialog extends StatefulWidget {
  const _AddProductDialog({required this.onSave});
  final Future<ProductModel> Function(
    String name,
    double retailPrice,
    double? wholesalePrice,
    String unit,
    String? barcode,
    double? stock,
  ) onSave;

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _retailCtrl = TextEditingController();
  final _wholesaleCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: '┘é╪╖╪╣╪ر');
  final _barcodeCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _retailCtrl.dispose();
    _wholesaleCtrl.dispose();
    _unitCtrl.dispose();
    _barcodeCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        '╪ح╪╢╪د┘╪ر ┘à┘╪ز╪ش ╪ش╪»┘è╪»',
        style: GoogleFonts.almarai(fontWeight: FontWeight.bold, fontSize: 16),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                textDirection: ui.TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: '╪د╪│┘à ╪د┘┘à┘╪ز╪ش *',
                  hintText: '┘à╪س╪د┘: ╪ص┘┘è╪ذ ╪د┘┘à╪▒╪د╪╣┘è 1 ┘╪ز╪▒',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? '╪د╪│┘à ╪د┘┘à┘╪ز╪ش ┘à╪╖┘┘ê╪ذ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _retailCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '╪│╪╣╪▒ ╪د┘┘à┘╪▒╪» *',
                  hintText: '╪│╪╣╪▒ ╪د┘╪ذ┘è╪╣ ╪ذ╪د┘┘à┘╪▒╪»',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '╪│╪╣╪▒ ╪د┘┘à┘╪▒╪» ┘à╪╖┘┘ê╪ذ';
                  if (double.tryParse(v) == null) return '╪ث╪»╪«┘ ╪▒┘é┘à ╪╡╪ص┘è╪ص';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _wholesaleCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '╪│╪╣╪▒ ╪د┘╪ش┘à┘╪ر (╪د╪«╪ز┘è╪د╪▒┘è)',
                  hintText: '╪│╪╣╪▒ ╪د┘╪ذ┘è╪╣ ╪ذ╪د┘╪ش┘à┘╪ر',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty && double.tryParse(v) == null) {
                    return '╪ث╪»╪«┘ ╪▒┘é┘à ╪╡╪ص┘è╪ص';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitCtrl,
                textDirection: ui.TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: '╪د┘┘ê╪ص╪»╪ر',
                  hintText: '┘é╪╖╪╣╪ر╪î ┘â╪▒╪ز┘ê┘╪î ┘â╪║...',
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barcodeCtrl,
                decoration: const InputDecoration(
                  labelText: '╪د┘╪ذ╪د╪▒┘â┘ê╪» (╪د╪«╪ز┘è╪د╪▒┘è)',
                  hintText: '╪▒┘é┘à ╪د┘╪ذ╪د╪▒┘â┘ê╪»',
                  prefixIcon: Icon(Icons.qr_code_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '╪د┘┘à╪«╪▓┘ê┘ ╪د┘╪ث┘ê┘┘è (╪د╪«╪ز┘è╪د╪▒┘è)',
                  hintText: '╪د┘┘â┘à┘è╪ر ╪د┘┘à╪ز┘ê┘╪▒╪ر',
                  prefixIcon: Icon(Icons.inventory_outlined),
                ),
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty && double.tryParse(v) == null) {
                    return '╪ث╪»╪«┘ ╪▒┘é┘à ╪╡╪ص┘è╪ص';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('╪ح┘╪║╪د╪ة'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveProduct,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('╪ص┘╪╕'),
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final name = _nameCtrl.text.trim();
      final retail = double.parse(_retailCtrl.text.trim());
      final wholesale = _wholesaleCtrl.text.trim().isNotEmpty
          ? double.parse(_wholesaleCtrl.text.trim())
          : null;
      final unit = _unitCtrl.text.trim().isNotEmpty ? _unitCtrl.text.trim() : '┘é╪╖╪╣╪ر';
      final barcode = _barcodeCtrl.text.trim().isNotEmpty ? _barcodeCtrl.text.trim() : null;
      final stock = _stockCtrl.text.trim().isNotEmpty ? double.parse(_stockCtrl.text.trim()) : null;

      final savedProduct = await widget.onSave(name, retail, wholesale, unit, barcode, stock);
      if (mounted) {
        Navigator.pop(context, savedProduct);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.error(context, '╪ص╪»╪س ╪«╪╖╪ث ╪ث╪س┘╪د╪ة ╪ص┘╪╕ ╪د┘┘à┘╪ز╪ش: $e');
      }
    }
  }
}

// ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤
// Step 3: Payment
// ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤ظ¤

class _PaymentStep extends ConsumerWidget {
  const _PaymentStep({
    required this.discountCtrl,
    required this.receivedCtrl,
    this.isEditing = false,
    this.originalInvoice,
  });

  final TextEditingController discountCtrl;
  final TextEditingController receivedCtrl;
  final bool isEditing;
  final InvoiceModel? originalInvoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceNotifier = ref.read(invoiceCreationProvider.notifier);
    final invoiceState = ref.watch(invoiceCreationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ظ¤ظ¤ Totals summary card ظ¤ظ¤
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.08 : 0.02),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            children: [
              _TotalRow(
                label: '╪د┘╪ح╪ش┘à╪د┘┘è ╪د┘┘╪▒╪╣┘è',
                value: invoiceState.subtotal,
                size: 14,
              ),
              if (invoiceState.discount > 0) ...[
                const SizedBox(height: 8),
                _TotalRow(
                  label: '╪د┘╪«╪╡┘à',
                  value: -invoiceState.discount,
                  size: 14,
                  color: AppColors.warning,
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: isDark ? AppColors.darkDivider : AppColors.divider),
              ),
              _TotalRow(
                label: '╪د┘╪ح╪ش┘à╪د┘┘è ╪د┘┘┘ç╪د╪خ┘è',
                value: invoiceState.grandTotal,
                size: 20,
                bold: true,
                color: AppColors.primary,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ظ¤ظ¤ Discount field ظ¤ظ¤
        TextField(
          controller: discountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '╪د┘╪«╪╡┘à (╪د╪«╪ز┘è╪د╪▒┘è)',
            prefixIcon: Icon(Icons.discount_outlined),
            suffixText: 'IQD',
          ),
          onChanged: (val) =>
              invoiceNotifier.setDiscount(double.tryParse(val) ?? 0),
        ),

        const SizedBox(height: 24),

        if (!isEditing) ...[
          // ظ¤ظ¤ Payment method ظ¤ظ¤
          Text(
            '╪╖╪▒┘è┘é╪ر ╪د┘╪»┘╪╣',
            style: TextStyle(
              fontFamily: 'KOMedia',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: PaymentMethod.values.map((method) {
              final isSelected = invoiceState.paymentMethod == method;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _PaymentMethodCard(
                    method: method,
                    isSelected: isSelected,
                    onTap: () {
                      invoiceNotifier.setPaymentMethod(method);
                      if (method != PaymentMethod.partial) {
                        invoiceNotifier.setReceivedAmount(null);
                        receivedCtrl.clear();
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),

          // ظ¤ظ¤ Received amount (partial only) ظ¤ظ¤
          if (invoiceState.paymentMethod == PaymentMethod.partial) ...[
            const SizedBox(height: 20),
            TextField(
              controller: receivedCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '╪د┘┘à╪ذ┘╪║ ╪د┘┘à╪│╪ز┘┘à',
                prefixIcon: const Icon(Icons.payments_outlined),
                suffixText: 'IQD',
                helperText: invoiceState.receivedAmount != null &&
                        invoiceState.receivedAmount! > 0
                    ? '╪د┘┘à╪ز╪ذ┘é┘è: ${_fmt.format(invoiceState.grandTotal - invoiceState.receivedAmount!)} IQD'
                    : null,
                helperStyle: const TextStyle(
                  fontFamily: 'KOMedia',
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onChanged: (val) =>
                  invoiceNotifier.setReceivedAmount(double.tryParse(val)),
            ),
          ],
        ],

        if (isEditing && originalInvoice != null) ...[
          const SizedBox(height: 24),
          Builder(builder: (context) {
            final totalPaid = invoiceState.receivedAmount ?? originalInvoice!.currentPaid;
            final remaining = invoiceState.grandTotal - totalPaid;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '╪ذ┘è╪د┘╪د╪ز ╪د┘╪»┘╪╣:',
                  style: TextStyle(
                    fontFamily: 'KOMedia',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: receivedCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '╪د┘┘à╪ذ┘╪║ ╪د┘┘à╪»┘┘ê╪╣ ╪د┘┘â┘┘è',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    suffixText: 'IQD',
                    helperText: remaining > 0.01
                        ? '╪د┘┘à╪ز╪ذ┘é┘è ┘â╪»┘è┘: ${_fmt.format(remaining)} IQD'
                        : '┘à╪»┘┘ê╪╣ ╪ذ╪د┘┘â╪د┘à┘ ظ£ô',
                    helperStyle: TextStyle(
                      fontFamily: 'KOMedia',
                      fontWeight: FontWeight.w800,
                      color: remaining > 0.01 ? AppColors.danger : AppColors.success,
                    ),
                  ),
                  onChanged: (val) =>
                      invoiceNotifier.setReceivedAmount(double.tryParse(val)),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '╪د┘┘à╪ذ┘╪║ ╪د┘┘à╪»┘┘ê╪╣:',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${_fmt.format(totalPaid)} IQD',
                            style: const TextStyle(
                              fontFamily: 'KOMedia',
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '╪د┘┘à╪ز╪ذ┘é┘è ┘â╪»┘è┘:',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${_fmt.format(remaining > 0 ? remaining : 0)} IQD',
                            style: const TextStyle(
                              fontFamily: 'KOMedia',
                              fontWeight: FontWeight.w800,
                              color: AppColors.danger,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = _config[method]!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? config.color.withOpacity(0.12)
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? config.color : (isDark ? AppColors.darkBorder : AppColors.border),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? config.color.withOpacity(0.1) : Colors.transparent,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              config.icon,
              color: isSelected ? config.color : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              size: 26,
            ),
            const SizedBox(height: 8),
            Text(
              config.label,
              style: TextStyle(
                fontFamily: 'KOMedia',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? config.color : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final _config = {
    PaymentMethod.cash: _MethodConfig(
      label: '┘┘é╪»┘è',
      icon: Icons.payments_outlined,
      color: const Color(0xFF22C55E),
    ),
    PaymentMethod.debt: _MethodConfig(
      label: '╪ت╪ش┘',
      icon: Icons.schedule_outlined,
      color: const Color(0xFFEF4444),
    ),
    PaymentMethod.partial: _MethodConfig(
      label: '╪ش╪▓╪خ┘è',
      icon: Icons.splitscreen_outlined,
      color: const Color(0xFFF59E0B),
    ),
  };
}

class _MethodConfig {
  const _MethodConfig(
      {required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.size = 14,
    this.bold = false,
    this.color,
  });
  final String label;
  final double value;
  final double size;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'KOMedia',
      fontSize: size,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          '${value < 0 ? '-' : ''}${_fmt.format(value.abs())} IQD',
          style: style,
        ),
      ],
    );
  }
}
