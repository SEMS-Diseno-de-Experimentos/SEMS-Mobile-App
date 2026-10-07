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
  static const String _orgBase = '/api/v1/organizations';
  static const String _energyReadings = '/api/v1/energy-readings';
  static const String _devicesBase = '/api/v1/device-management';

  static Future<DashboardSummary> getSummary() async {
    final user = await AuthRepositoryImpl.getMe();
    final devices = await DevicesRepositoryImpl.getDevices();
    final activeDevices = devices.where((d) => d.status == DeviceStatus.active).toList();
    final alerts = await AlertsRepositoryImpl.getAlerts(status: AlertStatus.active);
    final prediction = await AnalyticsRepositoryImpl.getBillPrediction();
    
    double currentKwh = 0;
    double currentCost = 0;
    
    try {
      final res = await api.get('$_energyReadings/user/${user.id}', queryParameters: {'limit': 500});
      if (res.data != null && res.data is List) {
        for (var r in res.data) {
          double kwh = (r['energy_kwh'] ?? 0).toDouble();
          currentKwh += kwh;
          currentCost += kwh * 0.78; // Fallback tariff
        }
      }
    } catch (_) {
      // Fallback
      currentKwh = activeDevices.length * 20.0;
      currentCost = currentKwh * 0.78; 
    }

    return DashboardSummary(
      currentMonthCost: currentCost,
      savingAmount: currentCost * 0.1,
      savingPct: currentCost > 0 ? 10.0 : 0.0,
      projectedCost: prediction.projectedCost > 0 ? prediction.projectedCost : currentCost * 1.5,
      totalKwh: currentKwh,
      activeDevices: activeDevices.length,
      unreadAlerts: alerts.length,
    );
  }

  static Future<List<EnergyReading>> getRecentReadings() async {
    final user = await AuthRepositoryImpl.getMe();
    try {
      final res = await api.get('$_energyReadings/user/${user.id}', queryParameters: {'limit': 100});
      if (res.data != null && res.data is List) {
        final Map<String, EnergyReading> byDay = {};
        for (var r in res.data) {
          final dateStr = r['timestamp'] as String;
          final day = dateStr.substring(0, 10);
          final kwh = (r['energy_kwh'] ?? 0).toDouble();
          if (byDay.containsKey(day)) {
            final old = byDay[day]!;
            byDay[day] = EnergyReading(date: day, kwh: old.kwh + kwh, cost: old.cost + (kwh * 0.78));
          } else {
            byDay[day] = EnergyReading(date: day, kwh: kwh, cost: kwh * 0.78);
          }
        }
        if (byDay.isNotEmpty) {
           final sorted = byDay.values.toList()..sort((a, b) => a.date.compareTo(b.date));
           return sorted;
        }
      }
    } catch (_) {}
    
    // Fallback
    final devices = await DevicesRepositoryImpl.getDevices();
    final activeDevices = devices.where((d) => d.status == DeviceStatus.active).toList();
    if (activeDevices.isEmpty) return [];
    
    final baseKwh = activeDevices.length * 2.5;
    return List.generate(7, (i) => EnergyReading(
      date: DateTime.now().subtract(Duration(days: 6 - i)).toIso8601String().substring(0, 10),
      kwh: baseKwh + (i % 3) * 1.5,
      cost: (baseKwh + (i % 3) * 1.5) * 0.78,
    ));
  }
  
  static Future<List<Anomaly>> getActiveAnomalies() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final devices = await DevicesRepositoryImpl.getDevices();
    if (devices.isEmpty) return [];
    
    final alerts = await AlertsRepositoryImpl.getAlerts(status: AlertStatus.active);
    
    final deviceNames = devices.map((d) => d.deviceName.toLowerCase()).toSet();
    final validAlerts = alerts.where((a) {
       final lower = a.title.toLowerCase();
       return lower.contains('consumo') || deviceNames.any((name) => lower.contains(name) || name.contains(lower));
    }).toList();
    
    final anomalies = validAlerts.map((a) => Anomaly(
      id: a.id,
      deviceName: a.title,
      description: a.message,
      severity: a.severity.name.toUpperCase(),
      detectedAt: a.createdAt,
      resolved: a.status == AlertStatus.resolved,
    )).toList();

    // Check goal
    final prefs = await SharedPreferences.getInstance();
    final goalStr = prefs.getString('consumption_goal');
    if (goalStr != null) {
      final goal = double.tryParse(goalStr) ?? 99999;
      final currentKwh = devices.length * 20.0; 
      if (goal < currentKwh) {
        // Exceeded! Inject dynamic alerts
        anomalies.add(Anomaly(
          id: 'goal-alert-1',
          deviceName: '¡Meta Global Excedida!',
          description: 'El consumo actual ($currentKwh kWh) superó la meta mensual de $goal kWh.',
          severity: 'HIGH',
          detectedAt: DateTime.now().toIso8601String(),
          resolved: false,
        ));
      }
    }

    return anomalies;
  }
}
