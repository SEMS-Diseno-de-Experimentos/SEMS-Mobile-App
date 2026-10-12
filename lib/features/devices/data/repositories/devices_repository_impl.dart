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

  static Future<String> _ensureUserSiteId(String userId) async {
    try {
      final res = await api.get('/api/v1/users/$userId/organizations');
      final data = res.data as List;
      if (data.isNotEmpty) {
        final org = data[0]['organization'];
        final orgId = org['organization_id'];
        final sitesRes = await api.get('$_orgBase/$orgId/sites');
        final sites = sitesRes.data as List;
        if (sites.isNotEmpty) {
          return sites[0]['site_id'].toString();
        } else {
          final newSite = await api.post('$_orgBase/$orgId/sites', data: {
            'site_code': 'LOC-01',
            'name': 'Sede Principal',
            'contracted_power_kw': 19.5,
            'tariff_category': 'BT5B',
            'floor_area_m2': 100.0,
          });
          return newSite.data['site_id'].toString();
        }
      } else {
        // Create organization and site
        final taxId = '20${DateTime.now().millisecondsSinceEpoch.toString().padRight(9, '0').substring(0, 9)}';
        final orgRes = await api.post(_orgBase, data: {
          'legal_name': 'Mi Organización',
          'trade_name': 'Mi Organización',
          'tax_id': taxId,
          'business_type': 'SUPERMARKET',
          'owner_user_id': userId,
        });
        final orgId = orgRes.data['organization_id'];
        final newSite = await api.post('$_orgBase/$orgId/sites', data: {
          'site_code': 'LOC-01',
          'name': 'Sede Principal',
          'contracted_power_kw': 19.5,
          'tariff_category': 'BT5B',
          'floor_area_m2': 100.0,
        });
        return newSite.data['site_id'].toString();
      }
    } catch (_) {
      return '00000000-0000-0000-0000-000000000001';
    }
  }

  static Future<Device> createDevice(Device device) async {
    final user = await AuthRepositoryImpl.getMe();
    String? siteId = device.siteId;
    if (siteId == null || siteId.isEmpty) {
      siteId = await _ensureUserSiteId(user.id);
    }

    final payload = {
      'externalDeviceCode': device.externalDeviceCode.isNotEmpty
          ? device.externalDeviceCode
          : 'DEV-${DateTime.now().millisecondsSinceEpoch % 100000}',
      'userId': user.id,
      'siteId': siteId,
      'zoneId': device.zoneId,
      'deviceName': device.deviceName,
      'deviceType': device.deviceType,
      'brand': device.brand,
      'model': device.model,
      'connectionProtocol': _cleanProtocol(device.connectionProtocol),
    };

    final response = await api.post('$_base/devices', data: payload);
    return Device.fromJson(response.data);
  }

  static String _cleanProtocol(String proto) {
    final p = proto.toUpperCase();
    if (p.contains('BLE') || p.contains('BLUETOOTH')) return 'BLUETOOTH';
    if (p.contains('ZIGBEE')) return 'ZIGBEE';
    if (p.contains('MATTER')) return 'MATTER';
    return 'WIFI';
  }

  static Future<Device> updateDevice(Device device) async {
    final response = await api.put('$_base/devices/${device.deviceId}', data: {
      'deviceName': device.deviceName,
      'deviceType': device.deviceType,
      'brand': device.brand,
      'model': device.model,
      'connectionProtocol': _cleanProtocol(device.connectionProtocol),
      'zoneId': device.zoneId,
    });
    return Device.fromJson(response.data);
  }

  static Future<void> deleteDevice(String deviceId) async {
    await api.delete('$_base/devices/$deviceId');
  }
}
