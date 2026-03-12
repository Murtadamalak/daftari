import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

// ─── Number formatter ─────────────────────────────────────────────────────────
final _fmt = NumberFormat('#,###');

/// Fetch all customers — used in the customer-picker step.
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

  /// If null → إنشاء فاتورة جديدة.
  /// إذا كان هناك id → تعديل فاتورة نقدية قائمة.
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

  // بيانات الفاتورة الأصلية عند التعديل (نستخدمها لحساب فروقات المخزون)
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'تعديل الفاتورة' : 'فاتورة جديدة'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _confirmDiscard(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
                : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Step indicator at top ──────────────────────────────────────────
              _StepHeader(currentStep: _currentStep),

              // ── Step content ──────────────────────────────────────────────────
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

      // ── Bottom action bar ─────────────────────────────────────────────────
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
          AppSnackBar.error(context, 'تعذّر تحميل الفاتورة');
        }
        return;
      }

      // لا نسمح بتعديل فواتير التسديد فقط (ليست مبيعات)
      if (inv.payType == 'تسديد دين') {
        if (mounted) {
          Navigator.of(context).pop();
          AppSnackBar.error(
            context,
            'لا يمكن تعديل فواتير تسديد الدين، عدّل فاتورة المبيعات الأصلية.',
          );
        }
        return;
      }

      final items = await repo.getItemsByInvoiceId(inv.id);
      final productsRepo = ref.read(productRepositoryProvider);
      final allProducts = await productsRepo.getAllProducts();

      // حوّل عناصر الفاتورة إلى CartItem داخل حالة إنشاء الفاتورة
      final cartItems = <CartItem>[];
      for (final it in items) {
        // نحاول إيجاد المنتج بنفس الاسم للوصول للمخزون ومعرّف المنتج
        final match = allProducts.firstWhere(
          (p) => p.name == it.productName,
          orElse: () => ProductModel(
            id: '',
            name: it.productName,
            unit: it.unit,
            retailPrice: it.unitPrice,
            wholesalePrice:
                it.priceType == 'wholesale' ? it.unitPrice : null,
            stock: null,
            createdAt: DateTime.now(),
          ),
        );
        cartItems.add(
          CartItem(
            product: match,
            quantity: it.qty,
            isWholesale: it.priceType == 'wholesale',
          ),
        );
      }

      final notifier = ref.read(invoiceCreationProvider.notifier);
      notifier.clear();
      notifier
          .setDiscount(inv.discount); // سيُعاد احتساب الإجمالي تلقائياً فيما بعد

      // تعبئة الزبون في حالة التعديل (إن وجد)
      if (inv.customerId != null) {
        final custRepo = ref.read(customerRepositoryProvider);
        final customer = await custRepo.getById(inv.customerId!);
        if (customer != null) {
          notifier.setCustomer(customer);
        }
      }

      // نضبط طريقة الدفع وحقل "المبلغ المدفوع عند إنشاء الفاتورة" في الحالة
      if (inv.payType == 'cash') {
        notifier.setPaymentMethod(PaymentMethod.cash);
      } else if (inv.payType == 'debt') {
        notifier.setPaymentMethod(PaymentMethod.debt);
      } else {
        notifier.setPaymentMethod(PaymentMethod.partial);
      }
      notifier.setReceivedAmount(inv.paid);

      // نحقن العناصر في الحالة
      for (final c in cartItems) {
        notifier.addProduct(c.product);
        notifier.updateQuantity(c.product.id, c.quantity);
        notifier.togglePriceType(c.product.id, c.isWholesale);
      }

      _discountCtrl.text =
          inv.discount == 0 ? '' : inv.discount.toStringAsFixed(0);
      _receivedCtrl.text =
          inv.paid == 0 ? '' : inv.paid.toStringAsFixed(0);

      _originalInvoice = inv;
      _originalItems = items;
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.error(context, 'خطأ أثناء تحميل الفاتورة: $e');
      }
    }
  }

  void _onNext() {
    final state = ref.read(invoiceCreationProvider);
    if (_currentStep == 1 && state.items.isEmpty) {
      _showToast('أضف منتجاً واحداً على الأقل');
      return;
    }
    if (_currentStep == 2) {
      if (!widget.isEditing &&
          state.paymentMethod == PaymentMethod.partial &&
          (state.receivedAmount == null || state.receivedAmount! <= 0)) {
        _showToast('أدخل المبلغ المستلم');
        return;
      }
      if (widget.isEditing) {
        final original = _originalInvoice!;
        final initialPaidOld = original.paid;
        final extraPaidAfterOld = original.currentPaid - initialPaidOld;
        final initialPaidNew =
            state.receivedAmount ?? initialPaidOld;
        final totalPaidAfterEdit =
            initialPaidNew + extraPaidAfterOld;
        final total = state.grandTotal;
        if (totalPaidAfterEdit > total + 0.01) {
          _showToast(
              'المبلغ المدفوع (الدفعة الأولى + التسديدات) لا يمكن أن يكون أكبر من كلفة الفاتورة الكلية.');
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
        title: const Text('تجاهل الفاتورة؟'),
        content: const Text('سيتم حذف جميع البيانات المدخلة.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تجاهل'),
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
        return <String, dynamic>{
          'product_name': item.product.name,
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
        customerName: customer?.name ?? 'زبون نقدي',
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
      // Removed undefined providers like dashboardProvider etc.
      // Realistically we can just rely on the ones we know exist.

      invoiceNotifier.clear();
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.success(context, 'تم حفظ الفاتورة بنجاح ✓');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showToast('خطأ أثناء الحفظ: $e');
      }
    }
  }

  /// حفظ التعديلات على فاتورة نقدية قائمة مع ضبط المخزون بدون التأثير على ديون قديمة.
  Future<void> _saveEditedInvoice() async {
    if (_isSaving || _originalInvoice == null) return;
    setState(() => _isSaving = true);

    try {
      final invoiceState = ref.read(invoiceCreationProvider);
      final repo = ref.read(invoiceRepositoryProvider);

      // نحسب الإجماليات الجديدة بناءً على حالة الإنشاء الحالية
      final subtotal = invoiceState.subtotal;
      final discount = invoiceState.discount;
      final grandTotal = invoiceState.grandTotal;

      final original = _originalInvoice!;
      final initialPaidOld = original.paid;
      final extraPaidAfterOld = original.currentPaid - initialPaidOld;
      final initialPaidNew =
          invoiceState.receivedAmount ?? initialPaidOld;

      final paid = initialPaidNew + extraPaidAfterOld;
      var debt = grandTotal - paid;
      if (debt < 0) debt = 0;

      String status;
      String payType = original.payType;
      if (debt <= 0.01) {
        status = 'paid';
      } else if (original.payType == 'debt' && paid <= 0.01) {
        status = 'unpaid';
      } else {
        status = 'partial';
      }

      // نبني العناصر الجديدة بنفس شكل الإنشاء العادي
      final items = invoiceState.items.map((item) {
        return <String, dynamic>{
          'product_name': item.product.name,
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
        subtotal: subtotal,
        discount: discount,
        grandTotal: grandTotal,
        paid: paid,
        debt: debt,
        status: status,
        payType: payType,
        items: items,
      );

      ref.read(invoiceCreationProvider.notifier).clear();

      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.success(context, 'تم حفظ التعديلات على الفاتورة ✓');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showToast('خطأ أثناء حفظ التعديل: $e');
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step Header
// ─────────────────────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.currentStep});
  final int currentStep;

  static const _steps = ['الزبون', 'المنتجات', 'الدفع'];
  static const _icons = [
    Icons.person_outline,
    Icons.shopping_cart_outlined,
    Icons.payments_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
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
                    ? Colors.white.withOpacity(0.8)
                    : Colors.white.withOpacity(0.25),
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
                      ? Colors.white
                      : isPast
                          ? Colors.white.withOpacity(0.8)
                          : Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPast ? Icons.check : _icons[stepIndex],
                  size: 20,
                  color: (isActive || isPast) ? primary : Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _steps[stepIndex],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color:
                      isActive ? Colors.white : Colors.white.withOpacity(0.65),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Action Bar
// ─────────────────────────────────────────────────────────────────────────────

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
          // ── Back button ──
          if (currentStep > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: OutlinedButton.icon(
                onPressed: isSaving ? null : onBack,
                icon: const Icon(Icons.arrow_forward_ios, size: 14),
                label: const Text('رجوع'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(100, 50),
                ),
              ),
            ),

          // ── Next / Save button ──
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
                  Text(isSaving
                      ? 'جاري الحفظ...'
                      : (isLastStep ? 'حفظ الفاتورة' : 'التالي')),
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
                        '$itemCount • ${_fmt.format(grandTotal)} IQD',
                        style: const TextStyle(fontSize: 12),
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

// ─────────────────────────────────────────────────────────────────────────────
// Step 1: Customer
// ─────────────────────────────────────────────────────────────────────────────

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
        AppSnackBar.success(context, 'تمت إضافة ${result.name} بنجاح ✓');
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
        // ── Cash customer card ──────────────────────────────────────────────
        _QuickOptionCard(
          icon: Icons.payments_outlined,
          iconColor: AppColors.success,
          title: 'زبون نقدي',
          subtitle: 'بدون حساب مسجّل',
          isSelected: isCashOnly,
          onTap: () => invoiceNotifier.setCustomer(null),
        ),

        const SizedBox(height: 16),

        // ── Selection Buttons ──────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.person_search_outlined,
                label: 'بحث عن زبون',
                color: AppColors.primary,
                onTap: () => _pickCustomer(context, ref),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.person_add_outlined,
                label: 'إضافة زبون',
                color: const Color(0xFF8B5CF6),
                onTap: () => _showAddCustomerDialog(context, ref),
              ),
            ),
          ],
        ),

        // ── Selected customer info ────────────────────────────────────────
        if (invoiceState.customer != null) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 4),
            child: Text('الزبون المختار:',
                style: GoogleFonts.almarai(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
          ),
          _CustomerInfoCard(customer: invoiceState.customer!),
        ],
      ],
    );
  }
}

// ── Quick option card ────────────────────────────────────────────────────────

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
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        opacity: isSelected ? 0.2 : 0.05,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isSelected ? AppColors.success : Colors.white.withOpacity(0.15),
          width: isSelected ? 2 : 1.5,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isSelected ? AppColors.success : null)),
                  Text(subtitle, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Customer Picker Row ──────────────────────────────────────────────────────

// ── Customer Search Picker Bottom Sheet ──────────────────────────────────────

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
        color: Theme.of(context).scaffoldBackgroundColor,
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
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'اختر زبوناً',
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
                hintText: 'بحث باسم الزبون أو رقم الهاتف...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.05),
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
                        Text('لا توجد نتائج',
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
                'دين مستحق',
                style: GoogleFonts.almarai(
                  fontSize: 10,
                  color: AppColors.danger.withOpacity(0.8),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'لا يوجد ديون',
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

// ── Add Customer Dialog ──────────────────────────────────────────────────────

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
          Text('زبون جديد'),
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
                  (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
              decoration: const InputDecoration(
                labelText: 'اسم الزبون *',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف (اختياري)',
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
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('حفظ واختر'),
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
      if (mounted) AppSnackBar.error(context, 'خطأ أثناء الحفظ: $e');
    }
  }
}

class _CustomerInfoCard extends StatelessWidget {
  const _CustomerInfoCard({required this.customer});
  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(20),
      opacity: 0.1,
      border: Border.all(
          color: const Color(0xFF4F46E5).withOpacity(0.5), width: 1.5),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFF4F46E5), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                if (customer.phone != null)
                  Text(customer.phone!,
                      style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontSize: 12)),
                if (customer.totalDebt > 0)
                  Text(
                    'دين حالي: ${NumberFormat('#,###').format(customer.totalDebt)} IQD',
                    style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF4F46E5), size: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2: Products
// ─────────────────────────────────────────────────────────────────────────────

class _ProductsStep extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceNotifier = ref.read(invoiceCreationProvider.notifier);
    final invoiceState = ref.watch(invoiceCreationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Action buttons ──
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.qr_code_scanner,
                label: 'مسح باركود',
                color: const Color(0xFF0EA5E9),
                onTap: () => _scanBarcode(context, ref),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.playlist_add,
                label: 'اختيار منتج',
                color: const Color(0xFF8B5CF6),
                onTap: () => _pickProduct(context, ref),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Cart items ──
        if (invoiceState.items.isEmpty)
          _EmptyCartHint()
        else ...[
          // Summary header
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${invoiceState.items.length} منتجات في السلة',
                    style: Theme.of(context).textTheme.titleSmall),
                Text(
                  'الإجمالي: ${_fmt.format(invoiceState.subtotal)} IQD',
                  style: const TextStyle(
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.w700,
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
        AppSnackBar.success(context, 'تمت إضافة ${match.name}');
      }
    } else {
      if (context.mounted) {
        AppSnackBar.error(context, 'المنتج غير موجود في قاعدة البيانات');
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _EmptyCartHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.grey.shade300, width: 1.5, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('السلة فارغة',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 6),
          Text('امسح الباركود أو اختر منتجاً',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onRemove,
    required this.onQtyChange,
    required this.onPriceTypeChange,
  });

  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<double> onQtyChange;
  final ValueChanged<bool> onPriceTypeChange;

  @override
  Widget build(BuildContext context) {
    final hasWholesale = item.product.wholesalePrice != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product name + remove ──
            Row(
              children: [
                Expanded(
                  child: Text(item.product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Color(0xFFEF4444), size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Price type + quantity ──
            Row(
              children: [
                // Price type toggle
                if (hasWholesale)
                  _PriceTypeToggle(
                    isWholesale: item.isWholesale,
                    onChanged: onPriceTypeChange,
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('مفرد',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600)),
                  ),

                const Spacer(),

                // Quantity stepper
                _QuantityStepper(
                  quantity: item.quantity,
                  onDecrease: () => onQtyChange(item.quantity - 1),
                  onIncrease: () => onQtyChange(item.quantity + 1),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Price summary ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_fmt.format(item.effectivePrice)} IQD × ${item.quantity.toStringAsFixed(item.quantity == item.quantity.truncate() ? 0 : 2)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Text(
                  '${_fmt.format(item.total)} IQD',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF4F46E5)),
                ),
              ],
            ),
          ],
        ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(
              label: 'مفرد',
              isActive: !isWholesale,
              onTap: () => onChanged(false)),
          _Tab(
              label: 'جملة',
              isActive: isWholesale,
              onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab(
      {required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey.shade600,
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
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
          color: const Color(0xFF4F46E5).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF4F46E5)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Picker Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet({required this.products});
  final List<ProductModel> products;

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.products
        : widget.products
            .where((p) =>
                p.name.toLowerCase().contains(_query.toLowerCase()) ||
                (p.barcode?.toLowerCase().contains(_query.toLowerCase()) ??
                    false))
            .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'بحث في المنتجات...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('لا توجد نتائج',
                        style: TextStyle(color: Colors.grey.shade500)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.inventory_2_outlined,
                                color: Color(0xFF4F46E5), size: 20),
                          ),
                          title: Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(
                            '${_fmt.format(p.retailPrice)} IQD',
                            style: const TextStyle(
                                color: Color(0xFF4F46E5),
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                          trailing: const Icon(Icons.add_circle,
                              color: Color(0xFF4F46E5), size: 28),
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

// ─────────────────────────────────────────────────────────────────────────────
// Step 3: Payment
// ─────────────────────────────────────────────────────────────────────────────

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Totals summary card ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _TotalRow(
                    label: 'الإجمالي الفرعي',
                    value: invoiceState.subtotal,
                    size: 14),
                if (invoiceState.discount > 0) ...[
                  const SizedBox(height: 6),
                  _TotalRow(
                    label: 'الخصم',
                    value: -invoiceState.discount,
                    size: 14,
                    color: const Color(0xFFF59E0B),
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(),
                ),
                _TotalRow(
                  label: 'الإجمالي النهائي',
                  value: invoiceState.grandTotal,
                  size: 22,
                  bold: true,
                  color: const Color(0xFF4F46E5),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Discount field ──
        TextField(
          controller: discountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'الخصم (اختياري)',
            prefixIcon: Icon(Icons.discount_outlined),
            suffixText: 'IQD',
          ),
          onChanged: (val) =>
              invoiceNotifier.setDiscount(double.tryParse(val) ?? 0),
        ),

        const SizedBox(height: 20),

        if (!isEditing) ...[
          // ── Payment method ──
          Text('طريقة الدفع', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),

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

          // ── Received amount (partial only) ──
          if (invoiceState.paymentMethod == PaymentMethod.partial) ...[
            const SizedBox(height: 16),
            TextField(
              controller: receivedCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'المبلغ المستلم',
                prefixIcon: const Icon(Icons.payments_outlined),
                suffixText: 'IQD',
                helperText: invoiceState.receivedAmount != null &&
                        invoiceState.receivedAmount! > 0
                    ? 'المتبقي: ${_fmt.format(invoiceState.grandTotal - invoiceState.receivedAmount!)} IQD'
                    : null,
                helperStyle: const TextStyle(color: Color(0xFFEF4444)),
              ),
              onChanged: (val) =>
                  invoiceNotifier.setReceivedAmount(double.tryParse(val)),
            ),
          ],
        ],

        if (isEditing && originalInvoice != null) ...[
          const SizedBox(height: 20),
          Builder(builder: (context) {
            final initialPaid = originalInvoice!.paid;
            final extraPaid = originalInvoice!.currentPaid - initialPaid;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعديل بيانات الدفع:',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'طريقة الدفع الأصلية: ${originalInvoice!.payType == 'cash' ? 'نقدي' : originalInvoice!.payType == 'debt' ? 'آجل' : 'جزئي'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'المبالغ المسددة بعد الفاتورة: ${_fmt.format(extraPaid)} IQD (لن تتغيّر من هنا)',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: receivedCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'المبلغ المدفوع عند إنشاء الفاتورة',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    suffixText: 'IQD',
                    helperText:
                        'المدفوع الكلي بعد التسديدات سيكون: ${_fmt.format((double.tryParse(receivedCtrl.text) ?? initialPaid) + extraPaid)} IQD',
                  ),
                  onChanged: (val) => invoiceNotifier
                      .setReceivedAmount(double.tryParse(val)),
                ),
                const SizedBox(height: 8),
                Text(
                  'المبلغ المدفوع حتى الآن (بعد كل التسديدات): ${_fmt.format(originalInvoice!.currentPaid)} IQD',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.green),
                ),
                const SizedBox(height: 4),
                Text(
                  'المتبقي كدين بعد آخر تسديد: ${_fmt.format(originalInvoice!.debt)} IQD',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.redAccent),
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
    final config = _config[method]!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? config.color.withOpacity(0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? config.color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon,
                color: isSelected ? config.color : Colors.grey.shade500,
                size: 26),
            const SizedBox(height: 6),
            Text(
              config.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? config.color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final _config = {
    PaymentMethod.cash: _MethodConfig(
      label: 'نقدي',
      icon: Icons.payments_outlined,
      color: const Color(0xFF22C55E),
    ),
    PaymentMethod.debt: _MethodConfig(
      label: 'آجل',
      icon: Icons.schedule_outlined,
      color: const Color(0xFFEF4444),
    ),
    PaymentMethod.partial: _MethodConfig(
      label: 'جزئي',
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
