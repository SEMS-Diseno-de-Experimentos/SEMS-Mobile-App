/// Device status.
enum DeviceStatus { active, inactive, disconnected, maintenance, removed }

/// Device model — mirrors dm_devices from SEMS backend.
class Device {
  final String deviceId;
  final String externalDeviceCode;
  final String userId;
  final String? siteId;
  final String? zoneId;
  final String deviceName;
  final String deviceType;
  final String brand;
  final String model;
  final String connectionProtocol;
  final DeviceStatus status;
  final String? registeredAt;
  final String? updatedAt;

  const Device({
    required this.deviceId,
    required this.externalDeviceCode,
    required this.userId,
    this.siteId,
    this.zoneId,
    required this.deviceName,
    required this.deviceType,
    required this.brand,
    required this.model,
    required this.connectionProtocol,
    this.status = DeviceStatus.active,
    this.registeredAt,
    this.updatedAt,
  });

  factory Device.fromJson(Map<String, dynamic> j) => Device(
        deviceId: (j['deviceId'] ?? j['device_id'] ?? '').toString(),
        externalDeviceCode: (j['externalDeviceCode'] ?? j['external_device_code'] ?? '').toString(),
        userId: (j['userId'] ?? j['user_id'] ?? '').toString(),
        siteId: (j['siteId'] ?? j['site_id'])?.toString(),
        zoneId: (j['zoneId'] ?? j['zone_id'])?.toString(),
        deviceName: (j['deviceName'] ?? j['device_name'] ?? j['name'] ?? '').toString(),
        deviceType: (j['deviceType'] ?? j['device_type'] ?? 'OTHER').toString(),
        brand: (j['brand'] ?? 'SEMS').toString(),
        model: (j['model'] ?? 'Standard').toString(),
        connectionProtocol: (j['connectionProtocol'] ?? j['connection_protocol'] ?? 'WIFI').toString(),
        status: _parseStatus(j['status']),
        registeredAt: (j['registeredAt'] ?? j['created_at'])?.toString(),
        updatedAt: (j['updatedAt'] ?? j['updated_at'])?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'externalDeviceCode': externalDeviceCode,
        'userId': userId,
        'siteId': siteId,
        'zoneId': zoneId,
        'deviceName': deviceName,
        'deviceType': deviceType,
        'brand': brand,
        'model': model,
        'connectionProtocol': _cleanProtocol(connectionProtocol),
        'status': status.name.toUpperCase(),
      };

  static String _cleanProtocol(String proto) {
    final p = proto.toUpperCase();
    if (p.contains('WIFI')) return 'WIFI';
    if (p.contains('BLUETOOTH') || p.contains('BLE')) return 'BLUETOOTH';
    if (p.contains('ZIGBEE')) return 'ZIGBEE';
    if (p.contains('MATTER')) return 'MATTER';
    return 'WIFI';
  }

  static DeviceStatus _parseStatus(dynamic v) {
    final s = (v as String? ?? '').toUpperCase();
    if (s == 'INACTIVE') return DeviceStatus.inactive;
    if (s == 'DISCONNECTED') return DeviceStatus.disconnected;
    if (s == 'MAINTENANCE') return DeviceStatus.maintenance;
    if (s == 'REMOVED') return DeviceStatus.removed;
    return DeviceStatus.active;
  }
}
