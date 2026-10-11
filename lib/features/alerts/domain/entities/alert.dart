/// Alert severity.
enum AlertSeverity { low, medium, high, warning, critical, info }

/// Alert status.
enum AlertStatus { active, acknowledged, resolved }

/// Alert type.
enum AlertType { threshold, anomaly, inactivity, demand }

/// Alert model — mirrors al_alerts from SEMS backend.
class Alert {
  final String id;
  final AlertType type;
  final String title;
  final String deviceName;
  final String message;
  final AlertSeverity severity;
  AlertStatus status;
  final String createdAt;
  final double? measuredKw;
  final double? contractedKw;
  final double? headroomKw;
  final String? siteId;

  Alert({
    required this.id,
    required this.type,
    required this.title,
    required this.deviceName,
    required this.message,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.measuredKw,
    this.contractedKw,
    this.headroomKw,
    this.siteId,
  });

  factory Alert.fromJson(Map<String, dynamic> j) {
    final alertTypeStr = (j['alert_type'] ?? j['alertType'] ?? 'demand').toString().toLowerCase();
    final sevStr = (j['severity'] ?? 'warning').toString().toLowerCase();
    final statusStr = (j['status'] ?? 'active').toString().toLowerCase();

    return Alert(
      id: (j['alert_id'] ?? j['id'] ?? '').toString(),
      type: _parseType(alertTypeStr),
      title: (j['title'] ?? 'Aviso de potencia').toString(),
      deviceName: (j['device_name'] ?? j['deviceName'] ?? (j['device_id'] != null ? 'Dispositivo' : 'Suministro Comercial')).toString(),
      message: (j['message'] ?? '').toString(),
      severity: _parseSeverity(sevStr),
      status: _parseStatus(statusStr),
      createdAt: (j['triggered_at'] ?? j['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
      measuredKw: (j['measured_kw'] ?? j['measuredKw']) != null ? double.tryParse(j['measured_kw']?.toString() ?? j['measuredKw']?.toString() ?? '') : null,
      contractedKw: (j['contracted_kw'] ?? j['contractedKw']) != null ? double.tryParse(j['contracted_kw']?.toString() ?? j['contractedKw']?.toString() ?? '') : null,
      headroomKw: (j['headroom_kw'] ?? j['headroomKw']) != null ? double.tryParse(j['headroom_kw']?.toString() ?? j['headroomKw']?.toString() ?? '') : null,
      siteId: (j['site_id'] ?? j['siteId'])?.toString(),
    );
  }

  static AlertType _parseType(String t) {
    if (t.contains('anomaly')) return AlertType.anomaly;
    if (t.contains('inactivity')) return AlertType.inactivity;
    if (t.contains('threshold')) return AlertType.threshold;
    return AlertType.demand;
  }

  static AlertSeverity _parseSeverity(String s) {
    if (s.contains('crit') || s.contains('high')) return AlertSeverity.critical;
    if (s.contains('warn') || s.contains('med')) return AlertSeverity.warning;
    return AlertSeverity.info;
  }

  static AlertStatus _parseStatus(String s) {
    if (s.contains('ack')) return AlertStatus.acknowledged;
    if (s.contains('res')) return AlertStatus.resolved;
    return AlertStatus.active;
  }
}

/// Threshold configuration.
class Threshold {
  final String id;
  final String deviceName;
  final double maxKwhPerDay;
  final bool enabled;
  const Threshold({
    required this.id,
    required this.deviceName,
    required this.maxKwhPerDay,
    required this.enabled,
  });
}

/// Notification preference.
class NotificationPreference {
  final String channel; // EMAIL, SMS, PUSH
  final String label;
  bool enabled;
  NotificationPreference({
    required this.channel,
    required this.label,
    required this.enabled,
  });
}
