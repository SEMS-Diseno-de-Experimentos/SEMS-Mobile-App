import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';
import 'package:flutter_application_1/features/subscriptions/data/repositories/subscriptions_repository_impl.dart';
import 'package:flutter_application_1/features/subscriptions/domain/entities/billing.dart';
import 'package:flutter_application_1/core/widgets/sems_card.dart';
import 'package:flutter_application_1/core/widgets/sems_button.dart';
import 'package:flutter_application_1/core/widgets/loading_widget.dart';
import 'package:flutter_application_1/core/widgets/error_widget.dart';
import 'package:flutter_application_1/core/config/theme.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Subscription? _sub;
  List<SubscriptionPlan>? _plans;
  List<PaymentMethod>? _methods;
  List<Invoice>? _invoices;
  bool _loading = true;
  bool _error = false;
  bool _checkoutLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final futures = await Future.wait([
        SubscriptionsRepositoryImpl.getActiveSubscription(),
        SubscriptionsRepositoryImpl.getPlans(),
        SubscriptionsRepositoryImpl.getPaymentMethods(),
        SubscriptionsRepositoryImpl.getInvoices(),
      ]);
      setState(() {
        _sub = futures[0] as Subscription?;
        _plans = futures[1] as List<SubscriptionPlan>;
        _methods = futures[2] as List<PaymentMethod>;
        _invoices = futures[3] as List<Invoice>;
        _loading = false;
      });
    } catch (e, stack) {
      debugPrint('Subscription load error: $e\n$stack');
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _upgrade(String planId, String planName, double price) async {
    setState(() => _checkoutLoading = true);
    try {
      await SubscriptionsRepositoryImpl.subscribeToPlan(planId, planName, price, false);
      await _loadData();
    } catch (e) {
      if (mounted) {
        final lang = context.read<LanguageProvider>();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.t("Error al lanzar pago", "Error launching checkout"))));
      }
    } finally {
      if (mounted) setState(() => _checkoutLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) return const LoadingWidget();
    if (_error) return ErrorWidgetDisplay(onRetry: _loadData);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t("Suscripción", "Subscription"), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current Plan Card
              if (_sub != null)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [SemsColors.blue600, SemsColors.blue800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(SemsTheme.cardRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lang.t("Plan Actual", "Current Plan"),
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _sub!.status.name.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _sub!.planName == 'Ninguno' ? lang.t('Ninguno', 'None') :
                        _sub!.planName == 'Suscripción Actual' ? lang.t('Suscripción Actual', 'Current Subscription') : _sub!.planName,
                        style: const TextStyle(fontFamily: 'Sora', color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'S/ ${_sub!.price.toStringAsFixed(2)} / ${_sub!.period}',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lang.t("Se renueva el ${_sub!.renewalDate}", "Renews on ${_sub!.renewalDate}"),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Available Plans
              Text(
                lang.t("Cambiar Plan", "Change Plan"),
                style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...(_plans ?? []).map((p) {
                final isCurrent = p.id == _sub?.planId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: SemsCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (p.recommended)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: SemsColors.amber500,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              lang.t("RECOMENDADO", "RECOMMENDED"),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        Text(
                          p.name,
                          style: const TextStyle(fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'S/ ${p.price.toStringAsFixed(2)} / ${p.period}',
                          style: const TextStyle(fontSize: 16, color: SemsColors.blue600, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        ...p.features.map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.check, size: 16, color: SemsColors.emerald500),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(f, style: TextStyle(color: isDark ? SemsColors.slate300 : SemsColors.slate700, fontSize: 13))),
                                ],
                              ),
                            )),
                        const SizedBox(height: 16),
                        SemsButton(
                          text: isCurrent ? lang.t("Plan actual", "Current plan") : lang.t("Elegir plan", "Choose plan"),
                          variant: isCurrent ? SemsButtonVariant.outline : SemsButtonVariant.primary,
                          isFullWidth: true,
                          isLoading: _checkoutLoading,
                          onPressed: isCurrent ? null : () => _upgrade(p.id, p.name, p.price),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 32),

              // Payment Methods
              Text(
                lang.t("Métodos de Pago", "Payment Methods"),
                style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...(_methods ?? []).map((m) => SemsCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.credit_card, size: 24, color: SemsColors.slate500),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${m.brand} •••• ${m.last4}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(lang.t('Expira ${m.expMonth}/${m.expYear}', 'Expires ${m.expMonth}/${m.expYear}'), style: TextStyle(color: isDark ? SemsColors.slate400 : SemsColors.slate500, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (m.primary)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: SemsColors.slate200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(lang.t("PRINCIPAL", "DEFAULT"), style: const TextStyle(color: SemsColors.slate700, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  )),
              const SizedBox(height: 32),

              // Invoices
              Text(
                lang.t("Historial de Facturación", "Billing History"),
                style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SemsCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _invoices?.length ?? 0,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final inv = _invoices![index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: SemsColors.emerald500.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_long, color: SemsColors.emerald600),
                      ),
                      title: Text(inv.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(inv.date, style: TextStyle(color: isDark ? SemsColors.slate400 : SemsColors.slate500, fontSize: 12)),
                      trailing: Text(
                        'S/ ${inv.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
