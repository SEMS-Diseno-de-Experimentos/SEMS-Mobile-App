import 'package:flutter_application_1/core/config/api.dart';
import 'package:flutter_application_1/features/alerts/domain/entities/alert.dart';
import 'package:flutter_application_1/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_application_1/features/devices/data/repositories/devices_repository_impl.dart';
import 'package:flutter_application_1/features/devices/domain/entities/device.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertsRepositoryImpl {
  static const String _base = '/api/v1';

  static Future<List<Alert>> getAlerts({AlertStatus? status}) async {
    final user = await AuthRepositoryImpl.getMe();
    final devices = await DevicesRepositoryImpl.getDevices();
    final nameById = {for (var d in devices) d.deviceId: d.deviceName};

    List<Alert> alerts = [];
    try {
      final response = await api.get('$_base/users/${user.id}/alerts');
      final data = response.data as List;

      alerts = data.map((json) {
        final m = json as Map<String, dynamic>;
        final alert = Alert.fromJson(m);
        final devId = m['device_id']?.toString() ?? '';
        final devName = nameById[devId] ?? (devId.isNotEmpty ? 'Dispositivo ${devId.substring(0, 6)}' : alert.deviceName);
        return Alert(
          id: alert.id,
          type: alert.type,
          title: alert.title,
          deviceName: devName,
          message: alert.message,
          severity: alert.severity,
          status: alert.status,
          createdAt: alert.createdAt,
          measuredKw: alert.measuredKw,
          contractedKw: alert.contractedKw,
          headroomKw: alert.headroomKw,
          siteId: alert.siteId,
        );
      }).toList();
    } catch (_) {}

    // -------------------------------------------------------------
    // Chequeo de Tope/Límite de Consumo de Organización
    // -------------------------------------------------------------
    final prefs = await SharedPreferences.getInstance();
    double? goal;
    final savedGoalStr = prefs.getString('consumption_goal_${user.id}') ?? prefs.getString('consumption_goal');
    if (savedGoalStr != null && double.tryParse(savedGoalStr) != null) {
      goal = double.tryParse(savedGoalStr);
    } else {
      try {
        final goalRes = await api.get('/api/v1/users/${user.id}/goals');
        if (goalRes.data != null && goalRes.data['monthly_goal_kwh'] != null) {
          goal = (goalRes.data['monthly_goal_kwh'] as num).toDouble();
        }
      } catch (_) {}
    }
    goal ??= 350.0;

    // Obtener consumo actual acumulado
    double currentKwh = 0.0;
    try {
      final res = await api.get('/api/v1/energy-readings/user/${user.id}', queryParameters: {'limit': 500});
      if (res.data != null && res.data is List) {
        for (var r in res.data) {
          currentKwh += (r['energy_kwh'] as num?)?.toDouble() ?? 0.0;
        }
      }
    } catch (_) {
      currentKwh = devices.where((d) => d.status == DeviceStatus.active).length * 20.0;
    }

    if (goal != null && goal > 0 && currentKwh > 0) {
      if (currentKwh >= goal) {
        final savedStatus = prefs.getString('alert_status_goal_exceeded_${user.id}');
        final alertStatus = savedStatus == 'resolved'
            ? AlertStatus.resolved
            : (savedStatus == 'acknowledged' ? AlertStatus.acknowledged : AlertStatus.active);

        alerts.insert(
          0,
          Alert(
            id: 'goal-exceeded-${user.id}',
            type: AlertType.threshold,
            title: 'Tope de consumo mensual superado',
            deviceName: 'Límite de Organización (${goal.toStringAsFixed(0)} kWh)',
            message: 'El consumo acumulado (${currentKwh.toStringAsFixed(1)} kWh) ha superado el tope mensual establecido de ${goal.toStringAsFixed(0)} kWh.',
            severity: AlertSeverity.critical,
            status: alertStatus,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      } else if (currentKwh >= (goal * 0.85)) {
        final savedStatus = prefs.getString('alert_status_goal_warning_${user.id}');
        final alertStatus = savedStatus == 'resolved'
            ? AlertStatus.resolved
            : (savedStatus == 'acknowledged' ? AlertStatus.acknowledged : AlertStatus.active);

        alerts.insert(
          0,
          Alert(
            id: 'goal-warning-${user.id}',
            type: AlertType.threshold,
            title: 'Consumo próximo al tope (${((currentKwh / goal) * 100).toStringAsFixed(0)}%)',
            deviceName: 'Límite de Organización (${goal.toStringAsFixed(0)} kWh)',
            message: 'El consumo acumulado (${currentKwh.toStringAsFixed(1)} kWh) ha alcanzado el ${((currentKwh / goal) * 100).toStringAsFixed(0)}% del tope mensual establecido (${goal.toStringAsFixed(0)} kWh).',
            severity: AlertSeverity.warning,
            status: alertStatus,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }
    }

    if (status != null) {
      return alerts.where((a) => a.status == status).toList();
    }
    return alerts;
  }

  static Future<void> _updateAlertStatus(String alertId, String status) async {
    if (alertId.startsWith('goal-')) {
      final user = await AuthRepositoryImpl.getMe();
      final prefs = await SharedPreferences.getInstance();
      if (alertId.contains('exceeded')) {
        await prefs.setString('alert_status_goal_exceeded_${user.id}', status);
      } else {
        await prefs.setString('alert_status_goal_warning_${user.id}', status);
      }
      return;
    }

    final body = {'status': status};
    if (status == 'resolved') {
      body['resolved_at'] = DateTime.now().toUtc().toIso8601String();
    }
    try {
      await api.patch('$_base/alerts/$alertId/status', data: body);
    } catch (_) {}
  }

  static Future<void> acknowledgeAlert(String alertId) async {
    await _updateAlertStatus(alertId, 'acknowledged');
  }

  static Future<void> resolveAlert(String alertId) async {
    await _updateAlertStatus(alertId, 'resolved');
  }

  static Future<void> undoAlert(String alertId) async {
    await _updateAlertStatus(alertId, 'open');
  }
}
