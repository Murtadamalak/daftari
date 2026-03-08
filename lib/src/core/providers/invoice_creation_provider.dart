import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/product_repository.dart';

/// Represents a single item added to the invoice (cart).
class CartItem {
  CartItem({
    required this.product,
    this.quantity = 1,
    this.isWholesale = false,
  });

  final ProductModel product;
  final double quantity;
  final bool isWholesale;

  /// Returns the effective price based on the selected type.
  /// Falls back to retail price if wholesale is null.
  double get effectivePrice {
    if (isWholesale && product.wholesalePrice != null) {
      return product.wholesalePrice!;
    }
    return product.retailPrice;
  }

  double get total => effectivePrice * quantity;

  CartItem copyWith({
    ProductModel? product,
    double? quantity,
    bool? isWholesale,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      isWholesale: isWholesale ?? this.isWholesale,
    );
  }
}

/// The payment method for the invoice.
enum PaymentMethod { cash, debt, partial }

/// The entire state of the invoice being created.
class InvoiceCreationState {
  InvoiceCreationState({
    this.customer,
    this.items = const [],
    this.discount = 0.0,
    this.paymentMethod = PaymentMethod.cash,
    this.receivedAmount,
  });

  final CustomerModel?
      customer; // null implies 'Cash Customer' (no specific account)
  final List<CartItem> items;
  final double discount;
  final PaymentMethod paymentMethod;
  final double? receivedAmount;

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  double get grandTotal {
    final t = subtotal - discount;
    return t < 0 ? 0 : t;
  }

  InvoiceCreationState copyWith({
    CustomerModel? customer,
    bool clearCustomer = false, // To allow setting customer to null
    List<CartItem>? items,
    double? discount,
    PaymentMethod? paymentMethod,
    double? receivedAmount,
  }) {
    return InvoiceCreationState(
      customer: clearCustomer ? null : (customer ?? this.customer),
      items: items ?? this.items,
      discount: discount ?? this.discount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receivedAmount: receivedAmount ?? this.receivedAmount,
    );
  }
}

/// Notifier to manage the InvoiceCreationState.
class InvoiceCreationNotifier
    extends AutoDisposeNotifier<InvoiceCreationState> {
  @override
  InvoiceCreationState build() {
    return InvoiceCreationState();
  }

  void setCustomer(CustomerModel? customer) {
    state = state.copyWith(customer: customer, clearCustomer: customer == null);
  }

  void addProduct(ProductModel product) {
    final items = List<CartItem>.from(state.items);
    final existingIndex =
        items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      // Increase quantity if already exists
      final existing = items[existingIndex];
      items[existingIndex] = existing.copyWith(quantity: existing.quantity + 1);
    } else {
      // Add new item
      items.add(CartItem(product: product));
    }

    state = state.copyWith(items: items);
  }

  void updateQuantity(String productId, double quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }

    final items = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: items);
  }

  void togglePriceType(String productId, bool isWholesale) {
    final items = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(isWholesale: isWholesale);
      }
      return item;
    }).toList();

    state = state.copyWith(items: items);
  }

  void removeProduct(String productId) {
    final items =
        state.items.where((item) => item.product.id != productId).toList();
    state = state.copyWith(items: items);
  }

  void setDiscount(double discount) {
    state = state.copyWith(discount: discount);
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setReceivedAmount(double? amount) {
    state = state.copyWith(receivedAmount: amount);
  }

  void clear() {
    state = InvoiceCreationState();
  }
}

final invoiceCreationProvider =
    NotifierProvider.autoDispose<InvoiceCreationNotifier, InvoiceCreationState>(
  () => InvoiceCreationNotifier(),
);
