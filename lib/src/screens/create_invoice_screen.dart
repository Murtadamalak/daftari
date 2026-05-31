import 'package:daftar_debt_manager/src/core/widgets/app_bar_logo.dart';
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
              // ── Custom AppBar ───────────────────────────────────────────
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
          ),
        );
      }

      final notifier = ref.read(invoiceCreationProvider.notifier);
      notifier.clear();
      notifier.setDiscount(
          inv.discount); // سيُعاد احتساب الإجمالي تلقائياً فيما بعد

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
      _receivedCtrl.text = inv.paid == 0 ? '' : inv.paid.toStringAsFixed(0);

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
        final initialPaidNew = state.receivedAmount ?? initialPaidOld;
        final totalPaidAfterEdit = initialPaidNew + extraPaidAfterOld;
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
      final initialPaidNew = invoiceState.receivedAmount ?? initialPaidOld;

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
        customerId: invoiceState.customer?.id,
        customerName: invoiceState.customer?.name ?? 'زبون نقدي',
        customerPhone: invoiceState.customer?.phone,
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
                label: const Text(
                  'رجوع',
                  style: TextStyle(fontFamily: 'KOMedia'),
                ),
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
                  Text(
                    isSaving
                        ? 'جاري الحفظ...'
                        : (isLastStep ? 'حفظ الفاتورة' : 'التالي'),
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
                        '$itemCount • ${_fmt.format(grandTotal)} IQD',
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
        if (isCashOnly) ...[
          // ── Cash customer card ──────────────────────────────────────────────
          _QuickOptionCard(
            icon: Icons.payments_outlined,
            iconColor: AppColors.success,
            title: 'زبون نقدي',
            subtitle: 'بدون حساب مسجّل',
            isSelected: true,
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
                  color: AppColors.accent,
                  onTap: () => _showAddCustomerDialog(context, ref),
                ),
              ),
            ],
          ),
        ] else ...[
          // ── Selected customer info ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 12, right: 4),
            child: Text(
              'الزبون المختار:',
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
          Text(
            'زبون جديد',
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
          child: const Text(
            'إلغاء',
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
                  'حفظ واختر',
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
      if (mounted) AppSnackBar.error(context, 'خطأ أثناء الحفظ: $e');
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
                    'دين حالي: ${NumberFormat('#,###').format(customer.totalDebt)} IQD',
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
                color: AppColors.primary,
                onTap: () => _scanBarcode(context, ref),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.playlist_add,
                label: 'اختيار منتج',
                color: AppColors.accent,
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontFamily: 'KOMedia')),
                Text(
                  'الإجمالي: ${_fmt.format(invoiceState.subtotal)} IQD',
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
            'السلة فارغة',
            style: TextStyle(
              fontFamily: 'KOMedia',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'امسح الباركود أو اختر منتجاً',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasWholesale = item.product.wholesalePrice != null;
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
          // ── Product name + remove ──
          Row(
            children: [
              Expanded(
                child: Text(
                  item.product.name,
                  style: TextStyle(
                    fontFamily: 'KOMedia',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onRemove,
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
          const SizedBox(height: 12),

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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'مفرد',
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
                quantity: item.quantity,
                onDecrease: () => onQtyChange(item.quantity - 1),
                onIncrease: () => onQtyChange(item.quantity + 1),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: isDark ? AppColors.darkDivider : AppColors.divider, height: 1),
          const SizedBox(height: 12),

          // ── Price summary ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_fmt.format(item.effectivePrice)} IQD × ${item.quantity.toStringAsFixed(item.quantity == item.quantity.truncate() ? 0 : 2)}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                '${_fmt.format(item.total)} IQD',
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
            label: 'مفرد',
            isActive: !isWholesale,
            onTap: () => onChanged(false),
          ),
          _Tab(
            label: 'جملة',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    'اختر منتجاً',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'بحث في المنتجات...',
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
                      'لا توجد نتائج',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Totals summary card ──
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
                label: 'الإجمالي الفرعي',
                value: invoiceState.subtotal,
                size: 14,
              ),
              if (invoiceState.discount > 0) ...[
                const SizedBox(height: 8),
                _TotalRow(
                  label: 'الخصم',
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
                label: 'الإجمالي النهائي',
                value: invoiceState.grandTotal,
                size: 20,
                bold: true,
                color: AppColors.primary,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

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

        const SizedBox(height: 24),

        if (!isEditing) ...[
          // ── Payment method ──
          Text(
            'طريقة الدفع',
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

          // ── Received amount (partial only) ──
          if (invoiceState.paymentMethod == PaymentMethod.partial) ...[
            const SizedBox(height: 20),
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
            final initialPaid = originalInvoice!.paid;
            final extraPaid = originalInvoice!.currentPaid - initialPaid;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعديل بيانات الدفع:',
                  style: TextStyle(
                    fontFamily: 'KOMedia',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طريقة الدفع الأصلية: ${originalInvoice!.payType == 'cash' ? 'نقدي' : originalInvoice!.payType == 'debt' ? 'آجل' : 'جزئي'}',
                        style: const TextStyle(
                          fontFamily: 'KOMedia',
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'المبالغ المسددة بعد الفاتورة: ${_fmt.format(extraPaid)} IQD (لن تتغيّر من هنا)',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                  onChanged: (val) =>
                      invoiceNotifier.setReceivedAmount(double.tryParse(val)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المبلغ المدفوع الكلي:',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${_fmt.format(originalInvoice!.currentPaid)} IQD',
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
                      'المتبقي كدين:',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${_fmt.format(originalInvoice!.debt)} IQD',
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
