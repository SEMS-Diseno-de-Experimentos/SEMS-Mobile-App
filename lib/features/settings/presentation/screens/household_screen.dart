import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/core/providers/language_provider.dart';
import 'package:flutter_application_1/core/widgets/sems_card.dart';
import 'package:flutter_application_1/core/widgets/sems_button.dart';
import 'package:flutter_application_1/core/config/theme.dart';
import 'package:flutter_application_1/core/config/api.dart';
import 'package:flutter_application_1/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_application_1/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:flutter_application_1/core/widgets/loading_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key});

  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  final _goalCtrl = TextEditingController(text: '350');
  final _tariffCtrl = TextEditingController(text: '0.78');
  bool _loading = true;
  String _orgName = 'Sede Principal';
  String _planName = 'N/A';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String goal = '350';
    try {
      final user = await AuthRepositoryImpl.getMe();
      final goalRes = await api.get('/api/v1/users/${user.id}/goals');
      if (goalRes.data != null && goalRes.data['monthly_goal_kwh'] != null) {
        goal = (goalRes.data['monthly_goal_kwh'] as num).toDouble().toStringAsFixed(0);
      } else {
        goal = prefs.getString('consumption_goal_${user.id}') ?? prefs.getString('consumption_goal') ?? '350';
      }
    } catch (_) {
      goal = prefs.getString('consumption_goal') ?? '350';
    }

    if (mounted) {
      setState(() {
        _goalCtrl.text = goal;
        _tariffCtrl.text = prefs.getString('energy_tariff') ?? '0.78';
      });
    }
    await _loadOrg();
  }

  Future<void> _loadOrg() async {
    try {
      final user = await AuthRepositoryImpl.getMe();
      final res = await api.get('/api/v1/users/${user.id}/organizations');
      final dataList = res.data as List;
      if (dataList.isNotEmpty) {
        setState(() {
          _orgName = dataList[0]['organization']['legal_name'] ?? 'Mi Organización';
        });
      }
      final subRes = await api.get('/api/v1/subscriptions/users/${user.id}');
      final subList = subRes.data as List;
      if (subList.isNotEmpty) {
        setState(() {
          // No plan name returned directly, but we can set Active
          _planName = subList[0]['Status'] == 'ACTIVE' ? 'Suscripción Activa' : 'Inactiva';
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t("Mi Organización", "My Organization"), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_loading) const Center(child: LoadingWidget()) else SemsCard(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: SemsColors.blue100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.business, color: SemsColors.blue600, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _orgName,
                          style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _planName,
                          style: TextStyle(color: SemsColors.blue600, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              lang.t("Metas de Consumo", "Consumption Goals"),
              style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              lang.t("Establece un límite mensual para recibir alertas si estás por superarlo.", "Set a monthly limit to receive alerts if you are about to exceed it."),
              style: TextStyle(color: isDark ? SemsColors.slate400 : SemsColors.slate600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SemsCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.t("Meta global (kWh/mes)", "Global goal (kWh/month)"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _goalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      suffixText: 'kWh',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SemsButton(
                      text: lang.t("Guardar meta", "Save goal"),
                      onPressed: () async {
                        final val = _goalCtrl.text.trim();
                        final dVal = double.tryParse(val) ?? 350.0;
                        final prefs = await SharedPreferences.getInstance();
                        try {
                          final user = await AuthRepositoryImpl.getMe();
                          await prefs.setString('consumption_goal_${user.id}', val);
                          await prefs.setString('consumption_goal', val);
                          // Reset alert status when user configures a new limit
                          await prefs.remove('alert_status_goal_exceeded_${user.id}');
                          await prefs.remove('alert_status_goal_warning_${user.id}');
                          try {
                            await api.put('/api/v1/users/${user.id}/goals', data: {
                              'monthly_goal_kwh': dVal,
                            });
                          } catch (_) {}
                        } catch (_) {
                          await prefs.setString('consumption_goal', val);
                        }

                        AnalyticsRepositoryImpl.notifyDataChanged();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                lang.t(
                                  "Meta de ${dVal.toStringAsFixed(0)} kWh guardada. ¡Alerta de límite actualizada!",
                                  "Goal of ${dVal.toStringAsFixed(0)} kWh saved. Limit alert updated!"
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              lang.t("Tarifa Energética", "Energy Tariff"),
              style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SemsCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.t("Costo por kWh", "Cost per kWh"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tariffCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      prefixText: 'S/ ',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SemsButton(
                      text: lang.t("Guardar tarifa", "Save tariff"),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('energy_tariff', _tariffCtrl.text);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(lang.t("Tarifa guardada", "Tariff saved"))),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
