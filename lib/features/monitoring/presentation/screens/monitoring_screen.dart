import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';
import 'package:flutter_application_1/features/monitoring/data/repositories/energy_repository_impl.dart';
import 'package:flutter_application_1/features/monitoring/domain/entities/energy.dart';
import 'package:flutter_application_1/core/widgets/sems_card.dart';
import 'package:flutter_application_1/core/widgets/loading_widget.dart';
import 'package:flutter_application_1/core/widgets/error_widget.dart';
import 'package:flutter_application_1/features/monitoring/presentation/widgets/qr_scanner_modal.dart';
import 'package:flutter_application_1/core/config/theme.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  List<EnergyMeter>? _meters;
  List<DeviceConsumption>? _breakdown;
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
        EnergyRepositoryImpl.getMeters(),
        EnergyRepositoryImpl.getConsumptionBreakdown('2026-06-01', '2026-06-15'),
      ]);
      setState(() {
        _meters = futures[0] as List<EnergyMeter>;
        _breakdown = futures[1] as List<DeviceConsumption>;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _openQrScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QRScannerModal(
        onScan: (code) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Medidor detectado: $code')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) return const LoadingWidget();
    if (_error) return ErrorWidgetDisplay(onRetry: _loadData);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t("Monitoreo de Energía", "Energy Monitoring"), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openQrScanner,
        backgroundColor: SemsColors.blue600,
        foregroundColor: Colors.white,
        child: const Icon(Icons.qr_code_scanner),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meters section
              Text(
                lang.t("Medidores Activos", "Active Meters"),
                style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...(_meters ?? []).map((m) {
                return SemsCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: m.active ? SemsColors.emerald500.withValues(alpha: 0.1) : SemsColors.slate500.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.speed, color: m.active ? SemsColors.emerald600 : SemsColors.slate500),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              m.active ? lang.t("Conectado", "Connected") : lang.t("Desconectado", "Disconnected"),
                              style: TextStyle(
                                fontSize: 12,
                                color: m.active ? SemsColors.emerald600 : SemsColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${m.lastReadingKwh.toStringAsFixed(1)} kWh',
                        style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 32),
              
              // Breakdown section
              Text(
                lang.t("Desglose por Dispositivo", "Device Breakdown"),
                style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SemsCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _breakdown?.length ?? 0,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final d = _breakdown![index];
                    return ListTile(
                      title: Text(d.deviceName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('${d.kwh} kWh', style: TextStyle(color: isDark ? SemsColors.slate400 : SemsColors.slate500)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('S/ ${d.cost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${d.pct}%', style: TextStyle(color: isDark ? SemsColors.slate400 : SemsColors.slate500, fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
