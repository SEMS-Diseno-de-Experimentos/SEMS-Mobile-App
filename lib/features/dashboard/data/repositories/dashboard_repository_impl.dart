import 'package:flutter_application_1/core/config/api.dart';
import 'package:flutter_application_1/features/devices/domain/entities/device.dart';
import 'package:flutter_application_1/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_application_1/features/monitoring/domain/entities/energy.dart';
import 'package:flutter_application_1/features/analytics/domain/entities/analytics.dart';
import 'package:flutter_application_1/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_application_1/features/devices/data/repositories/devices_repository_impl.dart';
import 'package:flutter_application_1/features/alerts/data/repositories/alerts_repository_impl.dart';
import 'package:flutter_application_1/features/alerts/domain/entities/alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/features/analytics/data/repositories/analytics_repository_impl.dart';

class DashboardRepositoryImpl {
  static const String _energyReadings = '/api/v1/energy-readings';

  static Future<DashboardSummary> getSummary() async {
    final user = await AuthRepositoryImpl.getMe();
    final devices = await DevicesRepositoryImpl.getDevices();
    final activeDevices = devices
        .where((d) => d.status == DeviceStatus.active)
        .toList();
    final alerts = await AlertsRepositoryImpl.getAlerts(
      status: AlertStatus.active,
    );
    final prediction = await AnalyticsRepositoryImpl.getBillPrediction();
    final recs = await AnalyticsRepositoryImpl.getRecommendations();

    double currentKwh = 0;
    double currentCost = 0;

    try {
      final res = await api.get(
        '$_energyReadings/user/${user.id}',
        queryParameters: {'limit': 500},
      );
      if (res.data != null && res.data is List) {
        for (var r in res.data) {
          double kwh = (r['energy_kwh'] as num?)?.toDouble() ?? 0.0;
          currentKwh += kwh;
          currentCost += kwh * 0.78;
        }
      }
    } catch (_) {
      currentKwh = activeDevices.length * 20.0;
      currentCost = currentKwh * 0.78;
    }

    double appliedSavings = 0.0;
    for (var r in recs) {
      if (r.applied) {
        appliedSavings += r.estimatedSaving;
      }
    }

    double totalSavingAmount = (currentCost * 0.1) + appliedSavings;
    double totalSavingPct = (currentCost + appliedSavings) > 0
        ? ((totalSavingAmount / (currentCost + appliedSavings)) * 100).clamp(0.0, 100.0)
        : 0.0;

    return DashboardSummary(
      currentMonthCost: currentCost,
      savingAmount: totalSavingAmount,
      savingPct: totalSavingPct,
      projectedCost: prediction.projectedCost > 0 ? prediction.projectedCost : (currentCost * 1.5 - appliedSavings).clamp(0.0, double.infinity),
      totalKwh: currentKwh,
      activeDevices: activeDevices.length,
      unreadAlerts: alerts.length,
    );
  }

  static Future<List<EnergyReading>> getRecentReadings() async {
    final user = await AuthRepositoryImpl.getMe();
    try {
      final res = await api.get(
        '$_energyReadings/user/${user.id}',
        queryParameters: {'limit': 100},
      );
      if (res.data != null && res.data is List) {
        final Map<String, EnergyReading> byDay = {};
        for (var r in res.data) {
          final dateStr = (r['timestamp'] ?? '').toString();
          final day = dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
          if (day.isEmpty) continue;
          final kwh = (r['energy_kwh'] as num?)?.toDouble() ?? 0.0;
          if (byDay.containsKey(day)) {
            final old = byDay[day]!;
            byDay[day] = EnergyReading(
              date: day,
              kwh: old.kwh + kwh,
              cost: old.cost + (kwh * 0.78),
            );
          } else {
            byDay[day] = EnergyReading(date: day, kwh: kwh, cost: kwh * 0.78);
          }
        }
        if (byDay.isNotEmpty) {
          final sorted = byDay.values.toList()
            ..sort((a, b) => a.date.compareTo(b.date));
          return sorted;
        }
      }
    } catch (_) {}

    final devices = await DevicesRepositoryImpl.getDevices();
    final activeDevices = devices
        .where((d) => d.status == DeviceStatus.active)
        .toList();
    if (activeDevices.isEmpty) return [];

    final baseKwh = activeDevices.length * 2.5;
    return List.generate(
      7,
      (i) => EnergyReading(
        date: DateTime.now()
            .subtract(Duration(days: 6 - i))
            .toIso8601String()
            .substring(0, 10),
        kwh: baseKwh + (i % 3) * 1.5,
        cost: (baseKwh + (i % 3) * 1.5) * 0.78,
      ),
    );
  }

  static Future<List<Anomaly>> getActiveAnomalies() async {
    final devices = await DevicesRepositoryImpl.getDevices();
    if (devices.isEmpty) return [];

    final alerts = await AlertsRepositoryImpl.getAlerts(
      status: AlertStatus.active,
    );

    final deviceNames = devices.map((d) => d.deviceName.toLowerCase()).toSet();
    final validAlerts = alerts.where((a) {
      final lower = a.title.toLowerCase();
      return lower.contains('consumo') ||
          lower.contains('demanda') ||
          deviceNames.any(
            (name) => lower.contains(name) || name.contains(lower),
          );
    }).toList();

    final anomalies = validAlerts
        .map(
          (a) => Anomaly(
            id: a.id,
            deviceName: a.title,
            description: a.message,
            severity: a.severity.name.toUpperCase(),
            detectedAt: a.createdAt,
            resolved: a.status == AlertStatus.resolved,
          ),
        )
        .toList();

    final user = await AuthRepositoryImpl.getMe();
    final prefs = await SharedPreferences.getInstance();
    final goalStr = prefs.getString('consumption_goal_${user.id}') ?? prefs.getString('consumption_goal');
    if (goalStr != null && double.tryParse(goalStr) != null) {
      final goal = double.parse(goalStr);
      double currentKwh = 0.0;
      try {
        final res = await api.get('/api/v1/energy-readings/user/${user.id}', queryParameters: {'limit': 500});
        if (res.data != null && res.data is List) {
          for (var r in res.data) {
            currentKwh += (r['energy_kwh'] as num?)?.toDouble() ?? 0.0;
          }
        }
      } catch (_) {
        currentKwh = devices.length * 20.0;
      }

      if (goal < currentKwh) {
        anomalies.insert(
          0,
          Anomaly(
            id: 'goal-alert-${user.id}',
            deviceName: '¡Tope de Consumo Excedido!',
            description:
                'El consumo actual (${currentKwh.toStringAsFixed(1)} kWh) superó el tope mensual establecido de ${goal.toStringAsFixed(0)} kWh.',
            severity: 'HIGH',
            detectedAt: DateTime.now().toIso8601String(),
            resolved: false,
          ),
        );
      }
    }

    return anomalies;
  }
}
