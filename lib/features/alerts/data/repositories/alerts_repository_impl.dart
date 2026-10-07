import 'package:flutter_application_1/core/config/api.dart';
import 'package:flutter_application_1/features/alerts/domain/entities/alert.dart';
import 'package:flutter_application_1/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_application_1/features/devices/data/repositories/devices_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertsRepositoryImpl {

  static const String _base = '/api/v1';

  static Future<List<Alert>> getAlerts({AlertStatus? status}) async {
    final user = await AuthRepositoryImpl.getMe();
    final devices = await DevicesRepositoryImpl.getDevices();
    final nameById = {for (var d in devices) d.deviceId: d.deviceName};

    final response = await api.get('$_base/users/${user.id}/alerts');
    final data = response.data as List;
    
    final alerts = data.map((json) {
      final id = json['device_id']?.toString() ?? '';
      return Alert(
        id: json['alert_id']?.toString() ?? '',
        type: _parseType(json['alert_type']?.toString() ?? ''),
        title: json['title']?.toString() ?? json['message']?.toString() ?? 'Alerta',
        deviceName: nameById[id] ?? (id.isNotEmpty ? 'Dispositivo ${id.substring(0, 6)}' : ''),
        message: json['message']?.toString() ?? '',
        severity: _parseSeverity(json['severity']?.toString() ?? ''),
        status: _parseStatus(json['status']?.toString() ?? ''),
        createdAt: (json['triggered_at']?.toString() ?? '').split('T').first + ' ' + (json['triggered_at']?.toString() ?? '').split('T').last.split('.').first,
      );
    }).toList();

    if (status != null) {
      return alerts.where((a) => a.status == status).toList();
    }
    return alerts;
  }

  static Future<void> _updateAlertStatus(String alertId, String status) async {
    final body = {'status': status};
    if (status == 'resolved') {
      body['resolved_at'] = DateTime.now().toUtc().toIso8601String();
    }
    await api.patch('$_base/alerts/$alertId/status', data: body);
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

  static AlertType _parseType(String s) {
    if (s.contains('ANOMALY')) return AlertType.anomaly;
    if (s.contains('INACTIVITY')) return AlertType.inactivity;
    return AlertType.threshold;
  }

  static AlertSeverity _parseSeverity(dynamic s) {
    if (s == 3 || s == 'HIGH') return AlertSeverity.high;
    if (s == 2 || s == 'MEDIUM') return AlertSeverity.medium;
    return AlertSeverity.low;
  }

  static AlertStatus _parseStatus(dynamic s) {
    if (s == 2 || s == 'ACKNOWLEDGED' || s == 'READ') return AlertStatus.acknowledged;
    if (s == 3 || s == 'RESOLVED') return AlertStatus.resolved;
    return AlertStatus.active;
  }
}
