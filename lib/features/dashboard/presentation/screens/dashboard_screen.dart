import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';
import 'package:flutter_application_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_application_1/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:flutter_application_1/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_application_1/features/monitoring/domain/entities/energy.dart';
import 'package:flutter_application_1/features/analytics/domain/entities/analytics.dart';
import 'package:flutter_application_1/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:flutter_application_1/core/widgets/kpi_card.dart';
import 'package:flutter_application_1/core/widgets/sems_card.dart';
import 'package:flutter_application_1/core/widgets/sems_badge.dart';
import 'package:flutter_application_1/core/widgets/consumption_chart.dart';
import 'package:flutter_application_1/core/widgets/loading_widget.dart';
import 'package:flutter_application_1/core/widgets/error_widget.dart';
import 'package:flutter_application_1/core/config/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardSummary? _summary;
  List<EnergyReading>? _readings;
  List<Anomaly>? _anomalies;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    AnalyticsRepositoryImpl.dataChangeNotifier.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    if (mounted) _loadData();
  }

  @override
  void dispose() {
    AnalyticsRepositoryImpl.dataChangeNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final futures = await Future.wait([
        DashboardRepositoryImpl.getSummary(),
        DashboardRepositoryImpl.getRecentReadings(),
        DashboardRepositoryImpl.getActiveAnomalies(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = futures[0] as DashboardSummary;
        _readings = futures[1] as List<EnergyReading>;
        _anomalies = futures[2] as List<Anomaly>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();

    if (_loading) return const LoadingWidget();
    if (_error) return ErrorWidgetDisplay(onRetry: _loadData);
    if (_summary == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  lang.t("Hola, ${auth.user?.fullName.isNotEmpty == true ? auth.user!.fullName.split(' ').first : 'Usuario'}", "Hi, ${auth.user?.fullName.isNotEmpty == true ? auth.user!.fullName.split(' ').first : 'User'}"),
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('👋', style: TextStyle(fontSize: 24, fontFamilyFallback: ['Segoe UI Emoji', 'Apple Color Emoji'])),
              ],
            ),
            const SizedBox(height: 16),
            // KPIs
            Row(
              children: [
                Expanded(
                  child: KpiCard(
                    title: lang.t("Consumo Actual", "Current Cost"),
                    value: 'S/ ${_summary!.currentMonthCost.toStringAsFixed(2)}',
                    subtitle: lang.t("Este mes", "This month"),
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: lang.t("Proyectado", "Projected"),
                    value: 'S/ ${_summary!.projectedCost.toStringAsFixed(2)}',
                    subtitle: lang.t("Fin de mes", "End of month"),
                    icon: Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: KpiCard(
                    title: lang.t("Energía Total", "Total Energy"),
                    value: '${_summary!.totalKwh.toStringAsFixed(0)} kWh',
                    icon: Icons.bolt,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: lang.t("Dispositivos", "Devices"),
                    value: '${_summary!.activeDevices}',
                    subtitle: lang.t("Activos", "Active"),
                    icon: Icons.devices,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Chart
            SemsCard(
              title: lang.t("Consumo últimos 14 días", "Consumption last 14 days"),
              child: ConsumptionChart(readings: _readings ?? []),
            ),
            const SizedBox(height: 24),
            // Anomalies
            if (_anomalies != null && _anomalies!.isNotEmpty) ...[
              Text(
                lang.t("Requieren atención", "Needs attention"),
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._anomalies!.map((anomaly) {
                SemsBadgeVariant bVar;
                if (anomaly.severity == 'HIGH') {
                  bVar = SemsBadgeVariant.rose;
                } else if (anomaly.severity == 'MEDIUM') {
                  bVar = SemsBadgeVariant.amber;
                } else {
                  bVar = SemsBadgeVariant.slate;
                }

                // Demo translations for data
                String dName = anomaly.deviceName;
                String dDesc = anomaly.description;
                if (lang.lang == 'en') {
                  if (dName == 'Aire acondicionado') dName = 'Air conditioner';
                  if (dName == 'Terma eléctrica') dName = 'Water heater';
                  if (dName == 'Refrigeradora') dName = 'Refrigerator';
                  if (dDesc.contains('4 h continuas')) dDesc = 'On for 4 continuous hours during the night.';
                  if (dDesc.contains('35% por encima')) dDesc = 'Consumption 35% above your weekly average.';
                  if (dDesc.contains('Pico breve')) dDesc = 'Brief unusual consumption peak.';
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SemsCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: SemsColors.rose500.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: SemsColors.rose500, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      dName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  SemsBadge(text: anomaly.severity, variant: bVar),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dDesc,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? SemsColors.slate400 : SemsColors.slate600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
