import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';
import 'package:flutter_application_1/core/widgets/sems_button.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/core/config/theme.dart';
import 'package:flutter_application_1/features/subscriptions/domain/entities/billing.dart';
import 'package:flutter_application_1/features/subscriptions/data/repositories/subscriptions_repository_impl.dart';
import 'package:flutter_application_1/features/analytics/data/repositories/analytics_repository_impl.dart';
// Note: Requires pdf and printing packages for actual generation
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'Este Mes';
  bool _generating = false;
  Subscription? _sub;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final sub = await SubscriptionsRepositoryImpl.getActiveSubscription();
      if (mounted) {
        setState(() {
          _sub = sub;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generatePdf() async {
    setState(() => _generating = true);
    
    List<List<String>> tableData = [
      ['Dispositivo', 'Consumo (kWh)', 'Costo Est. (S/)', '% del Total']
    ];
    
    try {
      final rankings = await AnalyticsRepositoryImpl.getRanking(period: _selectedPeriod);
      double totalKwh = rankings.fold(0, (sum, item) => sum + item.kwh);
      
      for (var r in rankings) {
        String pct = totalKwh > 0 ? '${((r.kwh / totalKwh) * 100).toStringAsFixed(1)}%' : '0%';
        tableData.add([r.deviceName, r.kwh.toStringAsFixed(1), r.cost.toStringAsFixed(2), pct]);
      }
      
      if (rankings.isEmpty) {
        tableData.add(['Sin datos', '0.0', '0.00', '0%']);
      }
    } catch (_) {
      tableData.add(['Error obteniendo datos', '-', '-', '-']);
    }
    
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text("Reporte de Consumo Energético - SEMS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
              ),
              pw.SizedBox(height: 20),
              pw.Text("Período: $_selectedPeriod", style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                data: tableData,
              ),
              pw.SizedBox(height: 20),
              pw.Text("Generado por SEMS App", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    setState(() => _generating = false);
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'SEMS_Reporte_$_selectedPeriod.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final periods = lang.isEn 
        ? ['This Week', 'This Month', 'Last Month', 'This Year']
        : ['Esta Semana', 'Este Mes', 'Mes Pasado', 'Este Año'];

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(lang.t("Reportes PDF", "PDF Reports"), style: const TextStyle(fontWeight: FontWeight.bold))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t("Reportes PDF", "PDF Reports"), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: (_sub?.planName == 'Básico' || _sub?.planName == 'Free' || _sub?.price == 0) ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: SemsColors.slate400),
            const SizedBox(height: 24),
            Text(
              lang.t("Reportes avanzados", "Advanced reports"),
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              lang.t(
                "La generación de reportes detallados en formato PDF está disponible desde el plan Pro.",
                "Detailed PDF report generation is available from the Pro plan."
              ),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: isDark ? SemsColors.slate400 : SemsColors.slate600),
            ),
            const SizedBox(height: 32),
            SemsButton(
              text: lang.t("Mejorar mi plan", "Upgrade plan"),
              onPressed: () => context.push('/subscription'),
            ),
          ],
        ) : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.picture_as_pdf, size: 64, color: SemsColors.blue600),
            const SizedBox(height: 24),
            Text(
              lang.t("Generar Reporte", "Generate Report"),
              style: const TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              lang.t(
                "Genera un reporte detallado de tu consumo energético, con desgloses por dispositivo y recomendaciones.",
                "Generate a detailed energy consumption report with device breakdowns and recommendations."
              ),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? SemsColors.slate400 : SemsColors.slate600,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              lang.t("Selecciona el período", "Select period"),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? SemsColors.navy700 : SemsColors.slate300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: periods.contains(_selectedPeriod) ? _selectedPeriod : periods[1],
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: periods.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() => _selectedPeriod = newValue!);
                  },
                ),
              ),
            ),
            const Spacer(),
            SemsButton(
              text: lang.t("Descargar PDF", "Download PDF"),
              icon: Icons.download,
              isFullWidth: true,
              isLoading: _generating,
              onPressed: _generatePdf,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
