import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/config/api.dart';

class DemoSeeder {
  static Future<void> ensureSeeded(String userId) async {
    try {
      final res = await api.get('/api/v1/users/$userId/organizations');
      if ((res.data as List).isEmpty) {
        print('User has no data, seeding demo data...');
        await seedData(userId);
      }
    } catch (_) {
      // If error (e.g. 404), try seeding anyway
      await seedData(userId);
    }
  }

  static Future<void> seedData(String userId) async {
    try {
      final random = Random();
      
      // 1. Create Organization
      final orgRes = await api.post('/api/v1/organizations', data: {
        'legal_name': 'Hogar Smart',
        'tax_id': '20${random.nextInt(900000000) + 100000000}',
        'business_type': 'OTHER',
        'owner_user_id': userId,
      });
      final orgId = orgRes.data['organization_id'];

      // 2. Create Site
      final siteRes = await api.post('/api/v1/organizations/$orgId/sites', data: {
        'site_code': 'CASA-001',
        'name': 'Hogar Principal',
        'contracted_power_kw': 10,
        'tariff_category': 'BT5B',
      });
      final siteId = siteRes.data['site_id'];

      // 3. Create Meter
      final meterRes = await api.post('/api/v1/energy-meters', data: {
        'user_id': userId,
        'meter_serial': 'MTR-${random.nextInt(9999)}',
        'model': 'SmartMeter X1',
        'brand': 'Acme',
        'location': 'Tablero Principal',
        'firmware_version': '1.0.0',
        'max_power_watts': 10000,
      });
      final meterId = meterRes.data['id'];

      // 4. Create Devices
      final dev1Res = await api.post('/api/v1/device-management/devices', data: {
        'userId': userId,
        'siteId': siteId,
        'externalDeviceCode': 'AC-${random.nextInt(9999)}',
        'deviceName': 'Aire Acondicionado',
        'deviceType': 'AC',
        'brand': 'LG',
        'model': 'Inverter',
        'connectionProtocol': 'WIFI'
      });
      final device1Id = dev1Res.data['device_id'];

      final dev2Res = await api.post('/api/v1/device-management/devices', data: {
        'userId': userId,
        'siteId': siteId,
        'externalDeviceCode': 'LGT-${random.nextInt(9999)}',
        'deviceName': 'Luces Comedor',
        'deviceType': 'LIGHTING',
        'brand': 'Philips',
        'model': 'Hue',
        'connectionProtocol': 'BLUETOOTH'
      });
      final device2Id = dev2Res.data['device_id'];

      final dev3Res = await api.post('/api/v1/device-management/devices', data: {
        'userId': userId,
        'siteId': siteId,
        'externalDeviceCode': 'TV-${random.nextInt(9999)}',
        'deviceName': 'Televisor Sala',
        'deviceType': 'TV',
        'brand': 'Samsung',
        'model': 'SmartTV',
        'connectionProtocol': 'WIFI'
      });
      final device3Id = dev3Res.data['device_id'];

      // Update statuses to make them varied
      await api.patch('/api/v1/device-management/devices/$device2Id/status', data: {'status': 'INACTIVE'});
      await api.patch('/api/v1/device-management/devices/$device3Id/status', data: {'status': 'DISCONNECTED'});

      // 5. Generate Energy Readings
      for (int i = 0; i < 7; i++) {
        for (int j = 0; j < 3; j++) {
          await api.post('/api/v1/energy-readings', data: {
            'meter_id': meterId,
            'device_id': device1Id,
            'user_id': userId,
            'timestamp': DateTime.now().subtract(Duration(days: i, hours: j)).toIso8601String(),
            'reading_type': 'CONSUMPTION',
            'energy_kwh': random.nextDouble() * 2,
            'power_watts': random.nextDouble() * 2000,
            'voltage': 220.0,
            'current': random.nextDouble() * 10,
            'phase': '1',
            'frequency': 60.0
          });
        }
      }

      // 6. Recommendation
      await api.post('/api/v1/analytics/recommendations', data: {
        'user_id': userId,
        'device_id': device2Id,
        'recommendation_type': 'USAGE_OPTIMIZATION',
        'title': 'Apaga el Aire Acondicionado',
        'description': 'Usa el temporizador para apagar a las 3 AM.',
        'estimated_saving_kwh': 15.5,
        'estimated_saving_amount': 35.50,
        'currency': 'PEN',
        'status': 'APPLIED',
        'generated_at': DateTime.now().toIso8601String()
      });

      await api.post('/api/v1/analytics/recommendations', data: {
        'user_id': userId,
        'device_id': device3Id,
        'recommendation_type': 'USAGE_OPTIMIZATION',
        'title': 'Reduce el uso de TV',
        'description': 'Apaga la TV de noche para ahorrar.',
        'estimated_saving_kwh': 5.5,
        'estimated_saving_amount': 15.00,
        'currency': 'PEN',
        'status': 'PENDING',
        'generated_at': DateTime.now().toIso8601String()
      });

      // 7. Alert
      await api.post('/api/v1/alerts', data: {
        'user_id': userId,
        'device_id': device3Id,
        'alert_type': 'CONSUMPTION_SPIKE',
        'title': 'Pico de consumo inusual',
        'message': 'El Televisor está consumiendo un 30% más de lo habitual.',
        'severity': 'HIGH',
        'status': 'TRIGGERED',
        'triggered_at': DateTime.now().toIso8601String()
      });

      await api.post('/api/v1/alerts', data: {
        'user_id': userId,
        'device_id': device1Id,
        'alert_type': 'DEVICE_OFFLINE',
        'title': 'Aire Acondicionado desconectado',
        'message': 'Se perdió la conexión WiFi del dispositivo.',
        'severity': 'MEDIUM',
        'status': 'RESOLVED',
        'triggered_at': DateTime.now().subtract(Duration(hours: 5)).toIso8601String()
      });

      // 8. Subscription
      try {
        final plansRes = await api.get('/api/v1/subscription-plans');
        if (plansRes.data is List && (plansRes.data as List).isNotEmpty) {
          final planId = plansRes.data[0]['plan_id'];
          await api.post('/api/v1/subscriptions', data: {
            'user_id': userId,
            'plan_id': planId
          });
        }
      } catch (_) {
        // Skip if plans endpoint fails
      }
    } catch (e) {
      if (e is DioException) {
        print('Error seeding demo data: ${e.response?.data}');
      } else {
        print('Error seeding demo data: $e');
      }
    }
  }
}
