/// Subscription status.
enum SubscriptionStatus { active, trial, canceled, pastDue }

/// Subscription plan.
class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String period; // "mes" | "año"
  final List<String> features;
  final bool recommended;
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    this.recommended = false,
  });
}

/// Active subscription.
class Subscription {
  final String id;
  final String planId;
  final String planName;
  SubscriptionStatus status;
  final String renewalDate;
  final double price;
  final String period;
  Subscription({
    required this.id,
    required this.planId,
    required this.planName,
    required this.status,
    required this.renewalDate,
    required this.price,
    required this.period,
  });
}

/// Payment method.
class PaymentMethod {
  final String id;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final bool primary;
  const PaymentMethod({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    this.primary = false,
  });
}

/// Invoice item.
class Invoice {
  final String id;
  final String date;
  final double amount;
  final String status; // PAID, PENDING, FAILED
  final String description;
  const Invoice({
    required this.id,
    required this.date,
    required this.amount,
    required this.status,
    required this.description,
  });
}
