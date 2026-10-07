/// Alert severity.
enum AlertSeverity { low, medium, high }

/// Alert status.
enum AlertStatus { active, acknowledged, resolved }

/// Alert type.
enum AlertType { threshold, anomaly, inactivity }

/// Alert model — mirrors types/alerts.ts Alert.
class Alert {
  final String id;
  final AlertType type;
  final String title;
  final String deviceName;
  final String message;
  final AlertSeverity severity;
  AlertStatus status;
  final String createdAt;

  Alert({
    required this.id,
    required this.type,
    required this.title,
    required this.deviceName,
    required this.message,
    required this.severity,
    required this.status,
    required this.createdAt,
  });
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
