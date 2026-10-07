import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';
import 'package:flutter_application_1/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:flutter_application_1/features/subscriptions/data/repositories/subscriptions_repository_impl.dart';
import 'package:flutter_application_1/features/subscriptions/domain/entities/billing.dart';
import 'package:flutter_application_1/features/analytics/domain/entities/analytics.dart';
import 'package:flutter_application_1/core/widgets/sems_card.dart';
import 'package:flutter_application_1/core/widgets/sems_button.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/core/widgets/loading_widget.dart';
import 'package:flutter_application_1/core/widgets/error_widget.dart';
import 'package:flutter_application_1/core/config/theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  BillPrediction? _prediction;
  List<Recommendation>? _recommendations;
  List<ConsumptionRanking>? _ranking;
  Subscription? _sub;
  bool _loading = true;
  bool _error = false;

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
        AnalyticsRepositoryImpl.getBillPrediction(),
        AnalyticsRepositoryImpl.getRecommendations(),
        AnalyticsRepositoryImpl.getRanking(),
        SubscriptionsRepositoryImpl.getActiveSubscription(),
      ]);
      setState(() {
        _prediction = futures[0] as BillPrediction;
        _recommendations = futures[1] as List<Recommendation>;
        _ranking = futures[2] as List<ConsumptionRanking>;
        _sub = futures[3] as Subscription;
        _loading = false;
      });
    } catch (e, stack) {
      debugPrint('Analytics load error: $e\n$stack');
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) return const LoadingWidget();
    if (_error) return ErrorWidgetDisplay(onRetry: _loadData);

    final isFree = _sub?.planName == 'Básico' || _sub?.planName == 'Free' || _sub?.price == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t("Analíticas", "Analytics"), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: isFree ? [
              const SizedBox(height: 48),
              const Icon(Icons.lock_outline, size: 64, color: SemsColors.slate400),
              const SizedBox(height: 24),
              Text(
                lang.t("Analítica avanzada", "Advanced analytics"),
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                lang.t(
                  "Las recomendaciones personalizadas, la detección de anomalías y la proyección de factura están disponibles desde el plan Plus.", 
                  "Personalized recommendations, anomaly detection and bill forecasting are available from the Plus plan."
                ),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: isDark ? SemsColors.slate400 : SemsColors.slate600),
              ),
              const SizedBox(height: 32),
              SemsButton(
                text: lang.t("Mejorar mi plan", "Upgrade plan"),
                onPressed: () => context.push('/subscription'),
              ),
            ] : [
              // Proyección Factura
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [SemsColors.blue600, SemsColors.blue800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(SemsTheme.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: SemsColors.blue600.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.t("Proyección de factura", "Bill Prediction"),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'S/ ${_prediction!.projectedCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_prediction!.projectedKwh.toStringAsFixed(0)} kWh estimados al ${_prediction!.closingDate}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.auto_graph, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          lang.t("Precisión del modelo: ${(_prediction!.confidence * 100).toStringAsFixed(0)}%", "Model confidence: ${(_prediction!.confidence * 100).toStringAsFixed(0)}%"),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Recomendaciones
              Text(
                lang.t("Recomendaciones de IA", "AI Recommendations"),
                style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...(_recommendations ?? []).map((r) {
                String rTitle = r.title;
                String rDetail = r.detail;
                if (lang.lang == 'en') {
                  if (rTitle.contains('Sube el aire')) {
                    rTitle = 'Set AC to 24°C';
                    rDetail = 'Keeping the AC at 24°C instead of 21°C can reduce its consumption by up to 18%.';
                  } else if (rTitle.contains('Evita standby en la terma')) {
                    rTitle = 'Avoid water heater standby';
                    rDetail = 'Schedule the water heater 30 mins before bathing instead of leaving it on all day.';
                  } else if (rTitle.contains('Usa la lavadora en agua fría')) {
                    rTitle = 'Use washing machine with cold water';
                    rDetail = '90% of the washing machine\'s energy goes into heating the water.';
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SemsCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb, color: SemsColors.amber500),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                rTitle,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          rDetail,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? SemsColors.slate400 : SemsColors.slate600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              lang.t("Ahorro est.: S/ ${r.estimatedSaving.toStringAsFixed(2)}", "Est. savings: S/ ${r.estimatedSaving.toStringAsFixed(2)}"),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: SemsColors.emerald500,
                                fontSize: 13,
                              ),
                            ),
                            r.applied
                                ? Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: SemsColors.emerald500, size: 16),
                                      const SizedBox(width: 4),
                                      Text(lang.t("Aplicada", "Applied"), style: const TextStyle(color: SemsColors.emerald500, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  )
                                : SizedBox(
                                    height: 32,
                                    child: SemsButton(
                                      text: lang.t("Aplicar", "Apply"),
                                      onPressed: () async {
                                        if (r.id.isNotEmpty) {
                                          await AnalyticsRepositoryImpl.applyRecommendation(r.id);
                                          _loadData();
                                        }
                                      },
                                    ),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 32),

              // Ranking
              Text(
                lang.t("Top Consumidores", "Top Consumers"),
                style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SemsCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ranking?.length ?? 0,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final rank = _ranking![index];
                    String dName = rank.deviceName;
                    if (lang.lang == 'en') {
                      if (dName == 'Aire acondicionado') dName = 'Air conditioner';
                      if (dName == 'Terma eléctrica') dName = 'Water heater';
                      if (dName == 'Refrigeradora') dName = 'Refrigerator';
                      if (dName == 'Microondas') dName = 'Microwave';
                      if (dName == 'Televisor') dName = 'TV';
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isDark ? SemsColors.navy700 : SemsColors.slate100,
                        foregroundColor: isDark ? SemsColors.slate200 : SemsColors.slate700,
                        child: Text('#${rank.rank}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      title: Text(dName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('${rank.kwh} kWh', style: TextStyle(color: isDark ? SemsColors.slate400 : SemsColors.slate500)),
                      trailing: Text(
                        'S/ ${rank.cost.toStringAsFixed(2)}',
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
