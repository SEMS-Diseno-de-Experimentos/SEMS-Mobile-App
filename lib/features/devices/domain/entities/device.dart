/// Device status.
enum DeviceStatus { active, inactive, disconnected }

/// Device model — mirrors types/index.ts Device.
class Device {
  final String deviceId;
  final String externalDeviceCode;
  final String userId;
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
        deviceId: j['deviceId'] as String? ?? '',
        externalDeviceCode: j['externalDeviceCode'] as String? ?? '',
        userId: j['userId'] as String? ?? '',
        deviceName: j['deviceName'] as String? ?? '',
        deviceType: j['deviceType'] as String? ?? '',
        brand: j['brand'] as String? ?? '',
        model: j['model'] as String? ?? '',
        connectionProtocol: j['connectionProtocol'] as String? ?? '',
        status: _parseStatus(j['status']),
        registeredAt: j['registeredAt'] as String?,
        updatedAt: j['updatedAt'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'deviceName': deviceName,
        'deviceType': deviceType,
        'brand': brand,
        'model': model,
        'connectionProtocol': connectionProtocol,
        'externalDeviceCode': externalDeviceCode,
        'userId': userId,
        'status': status.name.toUpperCase(),
      };

  static DeviceStatus _parseStatus(dynamic v) {
    final s = (v as String? ?? '').toUpperCase();
    if (s == 'INACTIVE') return DeviceStatus.inactive;
    if (s == 'DISCONNECTED') return DeviceStatus.disconnected;
    return DeviceStatus.active;
  }
}
