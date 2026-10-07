import 'package:flutter_application_1/core/config/api.dart';
import 'package:flutter_application_1/features/devices/domain/entities/device.dart';
import 'package:flutter_application_1/features/auth/data/repositories/auth_repository_impl.dart';

class DevicesRepositoryImpl {
  static const String _base = '/api/v1/device-management';
  static const String _orgBase = '/api/v1/organizations';

  static Future<List<Device>> getDevices() async {
    final user = await AuthRepositoryImpl.getMe();
    final response = await api.get('$_base/users/${user.id}/devices');
    final data = response.data as List;
    return data.map((json) => Device.fromJson(json)).toList();
  }

  static Future<Device> createDevice(Device device) async {
    final user = await AuthRepositoryImpl.getMe();
    final deviceWithUser = Device(
      deviceId: device.deviceId,
      userId: user.id,
      externalDeviceCode: device.externalDeviceCode,
      deviceName: device.deviceName,
      deviceType: device.deviceType,
      brand: device.brand,
      model: device.model,
      connectionProtocol: device.connectionProtocol,
      status: device.status,
    );

    final response = await api.post('$_base/devices', data: deviceWithUser.toJson());
    return Device.fromJson(response.data);
  }

  static Future<Device> updateDevice(Device device) async {
    final response = await api.put('$_base/devices/${device.deviceId}', data: device.toJson());
    return Device.fromJson(response.data);
  }

  static Future<void> deleteDevice(String deviceId) async {
    await api.delete('$_base/devices/$deviceId');
  }
}
