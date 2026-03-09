class SubscriptionPlan {
  final String type;
  final String title;
  final String price;
  final String subtitle;
  final List<String> features;
  final List<String> missingFeatures;

  const SubscriptionPlan({
    required this.type,
    required this.title,
    required this.price,
    required this.subtitle,
    required this.features,
    required this.missingFeatures,
  });
}

class SubscriptionStatus {
  final String plan;
  final String currentStatus;
  final int daysRemaining;
  final bool isActive;
  final int invoicesRemaining;
  final int customersRemaining;

  const SubscriptionStatus({
    required this.plan,
    required this.currentStatus,
    required this.daysRemaining,
    required this.isActive,
    this.invoicesRemaining = 0,
    this.customersRemaining = 0,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      plan: json['plan']?.toString() ?? 'free',
      currentStatus: json['current_status']?.toString() ?? 'expired',
      daysRemaining: (json['days_remaining'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? false,
    );
  }
}

class PaymentConfig {
  final String zainCashNumber;
  final String accountHolder;
  final int monthlyPrice;
  final int yearlyPrice;

  PaymentConfig({
    required this.zainCashNumber,
    required this.accountHolder,
    required this.monthlyPrice,
    required this.yearlyPrice,
  });

  factory PaymentConfig.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> paymentInfo =
        json['payment_info'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> pricing =
        json['pricing'] as Map<String, dynamic>? ?? {};
    return PaymentConfig(
      zainCashNumber: paymentInfo['zain_cash_number']?.toString() ?? '',
      accountHolder: paymentInfo['account_holder']?.toString() ?? '',
      monthlyPrice: (pricing['monthly'] as num?)?.toInt() ?? 10000,
      yearlyPrice: (pricing['yearly'] as num?)?.toInt() ?? 99000,
    );
  }
}
