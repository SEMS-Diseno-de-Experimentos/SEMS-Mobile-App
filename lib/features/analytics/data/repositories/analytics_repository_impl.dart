import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/config/api.dart';
import 'package:flutter_application_1/features/analytics/domain/entities/analytics.dart';
import 'package:flutter_application_1/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_application_1/features/devices/data/repositories/devices_repository_impl.dart';
import 'package:flutter_application_1/features/devices/domain/entities/device.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsRepositoryImpl {
  static const String _base = '/api/v1/analytics';

  static final ValueNotifier<int> dataChangeNotifier = ValueNotifier<int>(0);

  static void notifyDataChanged() {
    dataChangeNotifier.value++;
  }

  static final List<Recommendation> _mockRecommendations = [
    Recommendation(id: 'r1', title: 'Apaga el Aire Acondicionado', detail: 'Usa el temporizador para apagar a las 3 AM fuera de horario.', estimatedSaving: 35.50, applied: true),
    Recommendation(id: 'r2', title: 'Ajustar Cámaras de Refrigeración', detail: 'Sube 1 grado la temperatura para ahorrar en punta (18:00-23:00).', estimatedSaving: 12.50, applied: false),
    Recommendation(id: 'r3', title: 'Desconectar Cajas y Terminales', detail: 'El modo suspensión consume energía. Apágalos al cierre.', estimatedSaving: 7.00, applied: false),
    Recommendation(id: 'r4', title: 'Revisar Motores y Compresores', detail: 'Evita arranques simultáneos en hora punta.', estimatedSaving: 25.00, applied: false),
    Recommendation(id: 'r5', title: 'Iluminación LED en Sala de Ventas', detail: 'Reduce el 30% del brillo durante el horario pico.', estimatedSaving: 15.50, applied: false),
  ];

  static Future<List<Recommendation>> getRecommendations() async {
    final user = await AuthRepositoryImpl.getMe();
    final prefs = await SharedPreferences.getInstance();
    final appliedIds = prefs.getStringList('applied_recommendations_${user.id}') ?? [];

    List<Recommendation> recs = [];
    try {
      final res = await api.get('$_base/recommendations/user/${user.id}');
      final list = res.data as List;
      if (list.isNotEmpty) {
        recs = list.map((r) {
          final id = r['id']?.toString() ?? '';
          final isApplied = r['status']?.toString().toUpperCase() == 'APPLIED' || appliedIds.contains(id);
          return Recommendation(
            id: id,
            title: r['title']?.toString() ?? '',
            detail: r['description']?.toString() ?? '',
            estimatedSaving: (r['estimated_saving_amount'] as num?)?.toDouble() ?? 0.0,
            applied: isApplied,
          );
        }).toList();
      }
    } catch (_) {}

    if (recs.isEmpty) {
      final devices = await DevicesRepositoryImpl.getDevices();
      final activeDevices = devices.where((d) => d.status == DeviceStatus.active).toList();
      if (activeDevices.isEmpty) return [];

      final activeNames = activeDevices.map((d) => d.deviceName.toLowerCase()).toSet();
      final matched = _mockRecommendations.where((r) {
        final tLower = r.title.toLowerCase();
        return activeNames.any((n) => tLower.contains(n) || n.contains(tLower));
      }).toList();

      final list = matched.isNotEmpty ? matched : _mockRecommendations.take(3).toList();
      recs = list.map((r) {
        final isApplied = appliedIds.contains(r.id);
        return Recommendation(
          id: r.id,
          title: r.title,
          detail: r.detail,
          estimatedSaving: r.estimatedSaving,
          applied: isApplied,
        );
      }).toList();
    }
    return recs;
  }

  static Future<void> applyRecommendation(String id) async {
    final user = await AuthRepositoryImpl.getMe();
    final prefs = await SharedPreferences.getInstance();
    final appliedIds = prefs.getStringList('applied_recommendations_${user.id}') ?? [];
    if (!appliedIds.contains(id)) {
      appliedIds.add(id);
      await prefs.setStringList('applied_recommendations_${user.id}', appliedIds);
    }

    try {
      await api.patch('$_base/recommendations/$id/apply');
    } catch (_) {}
    notifyDataChanged();
  }

  static Future<BillPrediction> getBillPrediction() async {
    final user = await AuthRepositoryImpl.getMe();
    final recs = await getRecommendations();
    double totalAppliedSavings = 0.0;
    for (var r in recs) {
      if (r.applied) {
        totalAppliedSavings += r.estimatedSaving;
      }
    }

    try {
      final res = await api.get('$_base/bill-predictions/user/${user.id}');
      final list = res.data as List;
      if (list.isNotEmpty) {
        final p = list.first;
        final baseCost = (p['estimated_amount'] as num?)?.toDouble() ?? 0.0;
        final baseKwh = (p['estimated_kwh'] as num?)?.toDouble() ?? 0.0;
        final finalCost = (baseCost - totalAppliedSavings).clamp(0.0, double.infinity);
        final finalKwh = (baseKwh - (totalAppliedSavings / 0.78)).clamp(0.0, double.infinity);

        return BillPrediction(
          projectedCost: finalCost,
          projectedKwh: finalKwh,
          confidence: 0.95,
          closingDate: p['period_end']?.toString() ?? DateTime.now().add(const Duration(days: 15)).toIso8601String(),
        );
      }
    } catch (_) {}

    final devices = await DevicesRepositoryImpl.getDevices();
    final activeDevices = devices.where((d) => d.status == DeviceStatus.active).toList();
    if (activeDevices.isEmpty) {
      return BillPrediction(projectedCost: 0, projectedKwh: 0, confidence: 0, closingDate: DateTime.now().add(const Duration(days: 15)).toIso8601String());
    }

    double baseCost = activeDevices.length * 20.0 * 0.78 * 1.5;
    double finalCost = (baseCost - totalAppliedSavings).clamp(0.0, double.infinity);

    return BillPrediction(
      projectedCost: finalCost,
      projectedKwh: activeDevices.length * 20.0 * 1.5,
      confidence: 0.95,
      closingDate: DateTime.now().add(const Duration(days: 15)).toIso8601String(),
    );
  }

  static Future<List<ConsumptionRanking>> getRanking({String? period}) async {
    try {
      final user = await AuthRepositoryImpl.getMe();
      final res = await api.get('$_base/consumption-rankings/user/${user.id}');
      final list = res.data as List;
      if (list.isNotEmpty) {
        final rankingGroup = list.first;
        final items = (rankingGroup['rankings'] as List?) ?? [];
        if (items.isNotEmpty) {
          return items.map((i) => ConsumptionRanking(
            rank: (i['rank'] as num?)?.toInt() ?? 1,
            deviceName: i['device_name']?.toString() ?? 'Equipo',
            kwh: (i['total_kwh'] as num?)?.toDouble() ?? 0.0,
            cost: (i['estimated_amount'] as num?)?.toDouble() ?? 0.0,
          )).toList();
        }
      }
    } catch (_) {}

    final devices = await DevicesRepositoryImpl.getDevices();
    final activeDevices = devices.where((d) => d.status == DeviceStatus.active).toList();
    if (activeDevices.isEmpty) return [];

    List<ConsumptionRanking> baseData = [];
    for (int i = 0; i < activeDevices.length; i++) {
      double kwh = 120.0 - (i * 15);
      if (kwh < 10) kwh = 10;
      baseData.add(ConsumptionRanking(
        rank: i + 1,
        deviceName: activeDevices[i].deviceName,
        kwh: kwh,
        cost: kwh * 0.78,
      ));
    }
    return baseData;
  }
}
