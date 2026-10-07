import 'package:flutter_application_1/core/config/api.dart';
import 'package:flutter_application_1/features/analytics/domain/entities/analytics.dart';
import 'package:flutter_application_1/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_application_1/features/devices/data/repositories/devices_repository_impl.dart';
import 'package:flutter_application_1/features/devices/domain/entities/device.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsRepositoryImpl {
  static const String _base = '/api/v1/analytics';

  static final List<Recommendation> _mockRecommendations = [
    Recommendation(id: 'r1', title: 'Apaga el Aire Acondicionado', detail: 'Usa el temporizador para apagar a las 3 AM.', estimatedSaving: 35.50, applied: true),
    Recommendation(id: 'r2', title: 'Ajustar Refrigeradora', detail: 'Sube 1 grado la temperatura para ahorrar energía.', estimatedSaving: 12.50, applied: false),
    Recommendation(id: 'r3', title: 'Desconectar PC Escritorio', detail: 'El modo suspensión consume energía. Apágalo por completo.', estimatedSaving: 8.20, applied: false),
    Recommendation(id: 'r4', title: 'Revisar Lavadora', detail: 'Lava con carga completa y agua fría.', estimatedSaving: 15.00, applied: false),
    Recommendation(id: 'r5', title: 'Bajar brillo del Televisor', detail: 'Reduce el brillo de la pantalla en la noche.', estimatedSaving: 5.50, applied: false),
    Recommendation(id: 'r6', title: 'Desenchufar Home Theater', detail: 'Desenchufa el equipo cuando no esté en uso.', estimatedSaving: 10.00, applied: false),
    Recommendation(id: 'r7', title: 'Microondas Eficiente', detail: 'No uses el microondas para descongelar, hazlo al natural.', estimatedSaving: 4.80, applied: false),
  ];

  static Future<List<Recommendation>> getRecommendations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final devices = await DevicesRepositoryImpl.getDevices();
    final activeDevices = devices.where((d) => d.status == DeviceStatus.active).toList();
    if (activeDevices.isEmpty) return [];

    final user = await AuthRepositoryImpl.getMe();
    final prefs = await SharedPreferences.getInstance();
    final appliedIds = prefs.getStringList('applied_recommendations_${user.id}') ?? [];

    final activeNames = activeDevices.map((d) => d.deviceName.toLowerCase()).toSet();
    return _mockRecommendations.where((r) {
      final tLower = r.title.toLowerCase();
      // Only return recommendations matching an active device
      return activeNames.any((n) => tLower.contains(n) || n.contains(tLower));
    }).map((r) {
      if (appliedIds.contains(r.id)) {
        return Recommendation(id: r.id, title: r.title, detail: r.detail, estimatedSaving: r.estimatedSaving, applied: true);
      }
      return r;
    }).toList();
  }

  static Future<void> applyRecommendation(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = await AuthRepositoryImpl.getMe();
    final prefs = await SharedPreferences.getInstance();
    final appliedIds = prefs.getStringList('applied_recommendations_${user.id}') ?? [];
    if (!appliedIds.contains(id)) {
      appliedIds.add(id);
      await prefs.setStringList('applied_recommendations_${user.id}', appliedIds);
    }
  }

  static Future<BillPrediction> getBillPrediction() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final devices = await DevicesRepositoryImpl.getDevices();
    final activeDevices = devices.where((d) => d.status == DeviceStatus.active).toList();
    if (activeDevices.isEmpty) {
      return BillPrediction(projectedCost: 0, projectedKwh: 0, confidence: 0, closingDate: DateTime.now().add(const Duration(days: 15)).toIso8601String());
    }

    double baseCost = activeDevices.length * 20.0 * 0.78 * 1.5; // roughly the projected cost from Dashboard
    
    final recs = await getRecommendations();
    double appliedSavings = 0;
    for (var r in recs) {
      if (r.applied) {
        appliedSavings += r.estimatedSaving;
      }
    }
    
    double finalCost = baseCost - appliedSavings;
    if (finalCost < 0) finalCost = 0;

    return BillPrediction(
      projectedCost: finalCost, 
      projectedKwh: activeDevices.length * 20.0 * 1.5, 
      confidence: 0.95, 
      closingDate: DateTime.now().add(const Duration(days: 15)).toIso8601String()
    );
  }

  static Future<List<ConsumptionRanking>> getRanking({String? period}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final devices = await DevicesRepositoryImpl.getDevices();
    final activeDevices = devices.where((d) => d.status == DeviceStatus.active).toList();
    if (activeDevices.isEmpty) return [];

    // Base data generated from actual devices
    List<ConsumptionRanking> baseData = [];
    for (int i = 0; i < activeDevices.length; i++) {
      double kwh = 120.0 - (i * 15);
      if (kwh < 10) kwh = 10;
      baseData.add(ConsumptionRanking(
        rank: i + 1, 
        deviceName: activeDevices[i].deviceName, 
        kwh: kwh, 
        cost: kwh * 0.78
      ));
    }

    if (period == null || period == 'Este Mes' || period == 'This Month') {
      return baseData;
    }

    // Generate variation based on period string length
    double multiplier = 1.0;
    if (period.contains('Pasado') || period.contains('Last')) {
      multiplier = 0.85; // 15% less
    } else if (period.contains('Semana') || period.contains('Week')) {
      multiplier = 0.25; // 25% of month
    } else if (period.contains('Año') || period.contains('Year')) {
      multiplier = 10.5; // 10.5x month
    }

    return baseData.map((e) => ConsumptionRanking(
      rank: e.rank,
      deviceName: e.deviceName,
      kwh: e.kwh * multiplier,
      cost: e.cost * multiplier,
    )).toList();
  }
}
