import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';
import 'package:flutter_application_1/features/alerts/data/repositories/alerts_repository_impl.dart';
import 'package:flutter_application_1/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:flutter_application_1/features/alerts/domain/entities/alert.dart';
import 'package:flutter_application_1/core/widgets/sems_card.dart';
import 'package:flutter_application_1/core/widgets/sems_badge.dart';
import 'package:flutter_application_1/core/widgets/loading_widget.dart';
import 'package:flutter_application_1/core/widgets/error_widget.dart';
import 'package:flutter_application_1/core/config/theme.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Alert>? _alerts;
  bool _loading = true;
  bool _error = false;
  AlertStatus? _filterStatus; // null means ALL

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
      final alerts = await AlertsRepositoryImpl.getAlerts(status: _filterStatus);
      setState(() {
        _alerts = alerts;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Widget _buildFilterChips() {
    final lang = context.watch<LanguageProvider>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip(lang.t("Todas", "All"), null),
          const SizedBox(width: 8),
          _filterChip(lang.t("Activas", "Active"), AlertStatus.active),
          const SizedBox(width: 8),
          _filterChip(lang.t("Reconocidas", "Acknowledged"), AlertStatus.acknowledged),
          const SizedBox(width: 8),
          _filterChip(lang.t("Resueltas", "Resolved"), AlertStatus.resolved),
        ],
      ),
    );
  }

  Widget _filterChip(String label, AlertStatus? status) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = status);
        _loadData();
      },
      backgroundColor: Colors.transparent,
      selectedColor: SemsColors.blue600,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? SemsColors.slate300 : SemsColors.slate700),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? SemsColors.blue600 : (Theme.of(context).brightness == Brightness.dark ? SemsColors.navy700 : SemsColors.slate300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t("Alertas", "Alerts"), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilterChips(),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _error
                    ? ErrorWidgetDisplay(onRetry: _loadData)
                    : _alerts == null || _alerts!.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off, size: 64, color: SemsColors.slate400),
                                const SizedBox(height: 16),
                                Text(
                                  lang.t("No hay alertas", "No alerts"),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _alerts!.length,
                              itemBuilder: (context, index) {
                                final alert = _alerts![index];
                                SemsBadgeVariant bVar;
                                if (alert.severity == AlertSeverity.critical || alert.severity == AlertSeverity.high) {
                                  bVar = SemsBadgeVariant.rose;
                                } else if (alert.severity == AlertSeverity.warning || alert.severity == AlertSeverity.medium) {
                                  bVar = SemsBadgeVariant.amber;
                                } else {
                                  bVar = SemsBadgeVariant.slate;
                                }

                                IconData alertIcon;
                                Color iconColor;
                                if (alert.type == AlertType.demand) {
                                  alertIcon = Icons.bolt;
                                  iconColor = SemsColors.rose500;
                                } else if (alert.type == AlertType.anomaly) {
                                  alertIcon = Icons.warning_amber_rounded;
                                  iconColor = SemsColors.amber500;
                                } else if (alert.type == AlertType.threshold) {
                                  alertIcon = Icons.trending_up;
                                  iconColor = SemsColors.rose500;
                                } else {
                                  alertIcon = Icons.sensors_off;
                                  iconColor = SemsColors.slate500;
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
                                            color: iconColor.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(alertIcon, color: iconColor, size: 24),
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
                                                      alert.title,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                    ),
                                                  ),
                                                  SemsBadge(text: alert.severity.name.toUpperCase(), variant: bVar),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                alert.deviceName,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: SemsColors.blue600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                alert.message,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark ? SemsColors.slate400 : SemsColors.slate600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                alert.createdAt,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? SemsColors.slate500 : SemsColors.slate400,
                                                ),
                                              ),
                                              if (alert.status == AlertStatus.active) ...[
                                                const SizedBox(height: 12),
                                                const Divider(),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    TextButton(
                                                      onPressed: () async {
                                                        await AlertsRepositoryImpl.acknowledgeAlert(alert.id);
                                                        _loadData();
                                                      },
                                                      child: Text(lang.t("Reconocer", "Acknowledge")),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        await AlertsRepositoryImpl.resolveAlert(alert.id);
                                                        _loadData();
                                                      },
                                                      style: TextButton.styleFrom(foregroundColor: SemsColors.emerald600),
                                                      child: Text(lang.t("Resolver", "Resolve")),
                                                    ),
                                                  ],
                                                ),
                                              ] else ...[
                                                const SizedBox(height: 12),
                                                const Divider(),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    TextButton(
                                                      onPressed: () async {
                                                        await AlertsRepositoryImpl.undoAlert(alert.id);
                                                        _loadData();
                                                      },
                                                      style: TextButton.styleFrom(foregroundColor: SemsColors.amber600),
                                                      child: Text(lang.t("Deshacer", "Undo")),
                                                    ),
                                                  ],
                                                ),
                                              ]
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
