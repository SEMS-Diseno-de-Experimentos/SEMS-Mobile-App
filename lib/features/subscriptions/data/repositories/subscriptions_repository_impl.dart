import 'package:flutter_application_1/core/config/api.dart';
import 'package:flutter_application_1/features/subscriptions/domain/entities/billing.dart';
import 'package:flutter_application_1/features/auth/data/repositories/auth_repository_impl.dart';

class SubscriptionsRepositoryImpl {
  static const String _basePlan = '/api/v1/subscription-plans';
  static const String _baseSub = '/api/v1/subscriptions';

  static Future<List<SubscriptionPlan>> getPlans() async {
    final response = await api.get(_basePlan);
    final data = response.data as List;
    return data.map((json) {
      return SubscriptionPlan(
        id: (json['PlanID'] ?? json['plan_id'] ?? '').toString(),
        name: (json['Name'] ?? json['name'] ?? '').toString(),
        price: (json['Price'] as num?)?.toDouble() ?? double.tryParse(json['Price']?.toString() ?? '0') ?? 0.0,
        period: (json['BillingPeriod'] ?? json['billing_period'] ?? 'mes').toString(),
        features: (json['PlanFeatures'] as List?)?.map((f) => f['FeatureName']?.toString() ?? f['FeatureValue']?.toString() ?? '').toList() ?? [],
        recommended: (json['Name'] ?? json['name'] ?? '').toString().toLowerCase().contains('pro'),
      );
    }).toList();
  }

  static Future<Subscription?> getActiveSubscription() async {
    final user = await AuthRepositoryImpl.getMe();
    try {
      final response = await api.get('$_baseSub/users/${user.id}');
      final data = response.data as List;
      final active = data.where((s) {
        final st = (s['Status'] ?? s['status'])?.toString().toUpperCase();
        return st == 'ACTIVE' || st == 'TRIAL';
      }).toList();
      if (active.isEmpty) return null;

      final sub = active.first;
      final plans = await getPlans();
      final planId = (sub['PlanID'] ?? sub['plan_id'])?.toString() ?? '';
      final plan = plans.where((p) => p.id == planId).firstOrNull;

      return Subscription(
        id: (sub['SubscriptionID'] ?? sub['subscription_id'])?.toString() ?? '',
        planId: planId,
        planName: plan?.name ?? 'Plan Comercial',
        status: SubscriptionStatus.active,
        renewalDate: (sub['EndDate'] ?? sub['end_date'])?.toString() ?? DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        price: plan?.price ?? 0.0,
        period: plan?.period ?? 'mes',
      );
    } catch (e) {
      return null;
    }
  }

  static Future<List<PaymentMethod>> getPaymentMethods() async {
    final user = await AuthRepositoryImpl.getMe();
    try {
      final response = await api.get('/api/v1/payment-methods/user/${user.id}');
      final data = response.data as List;
      return data.map((pm) => PaymentMethod(
        id: (pm['payment_method_id'] ?? pm['method_id'] ?? pm['id'])?.toString() ?? '',
        brand: pm['brand']?.toString() ?? pm['type']?.toString() ?? 'Card',
        last4: pm['last4']?.toString() ?? '4242',
        expMonth: int.tryParse(pm['exp_month']?.toString() ?? '12') ?? 12,
        expYear: int.tryParse(pm['exp_year']?.toString() ?? '2028') ?? 2028,
        primary: pm['is_default'] == true,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Invoice>> getInvoices() async {
    final user = await AuthRepositoryImpl.getMe();
    try {
      final response = await api.get('/api/v1/payments/user/${user.id}');
      final data = response.data as List;
      return data.map((inv) => Invoice(
        id: (inv['payment_id'] ?? inv['paymentId'] ?? inv['id'])?.toString() ?? '',
        amount: (inv['amount'] as num?)?.toDouble() ?? 0.0,
        status: inv['status']?.toString() ?? 'PAID',
        date: (inv['created_at'] ?? inv['createdAt'])?.toString() ?? DateTime.now().toIso8601String(),
        description: 'Pago de suscripción SEMS',
      )).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> subscribeToPlan(String planId, String planName, double amount, bool simulate) async {
    final user = await AuthRepositoryImpl.getMe();

    if (simulate && amount > 0) {
      final methods = await getPaymentMethods();
      String pmId = '';
      if (methods.isEmpty) {
        await api.post('/api/v1/payment-methods', data: {
          'user_id': user.id,
          'type': 'card',
          'stripe_payment_method_id': 'pm_fake_${DateTime.now().millisecondsSinceEpoch}',
          'is_default': true,
        });
        final newMethods = await getPaymentMethods();
        if (newMethods.isNotEmpty) pmId = newMethods.first.id;
      } else {
        pmId = methods.first.id;
      }

      if (pmId.isNotEmpty) {
        final sub = await getActiveSubscription();
        await api.post('/api/v1/payments/process', data: {
          'user_id': user.id,
          'payment_method_id': pmId,
          'subscription_id': sub?.id,
          'amount': amount,
          'currency': 'pen',
          'payment_method': 'card',
        });
      }
    }

    final sub = await getActiveSubscription();
    if (sub != null) {
      await api.patch('$_baseSub/${sub.id}/change-plan', data: {
        'new_plan_id': planId,
      });
    } else {
      await api.post(_baseSub, data: {
        'user_id': user.id,
        'plan_id': planId,
      });
    }
  }
}
