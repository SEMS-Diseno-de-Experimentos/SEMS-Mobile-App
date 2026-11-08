import 'dart:math';
import 'package:flutter_application_1/core/config/api.dart';
import 'package:flutter_application_1/features/devices/data/repositories/devices_repository_impl.dart';

class DemoSeeder {
  static Future<void> ensureSeeded(String userId) async {
    try {
      final devices = await DevicesRepositoryImpl.getDevices();
      if (devices.isEmpty) {
        await seedData(userId);
      }
    } catch (_) {
      await seedData(userId);
    }
  }

  static Future<void> seedData(String userId) async {
    try {
      final random = Random();

      // 1. Organitzación y Sede
      String siteId = '';
      try {
        final orgsRes = await api.get('/api/v1/users/$userId/organizations');
        final orgsList = orgsRes.data as List;
        if (orgsList.isNotEmpty) {
          final orgId = orgsList[0]['organization']['organization_id'];
          final sitesRes = await api.get('/api/v1/organizations/$orgId/sites');
          final sitesList = sitesRes.data as List;
          if (sitesList.isNotEmpty) {
            siteId = sitesList[0]['site_id'].toString();
          }
        }
      } catch (_) {}

      if (siteId.isEmpty) {
        final orgNames = [
          'Comercial Lima Smart S.A.C.',
          'Supermercados del Centro',
          'Inversiones & Retail Express',
          'Mercados Globales S.A.C.',
          'Distribuidora San Isidro',
        ];
        final orgName = orgNames[random.nextInt(orgNames.length)];
        final taxId = '20${100000000 + random.nextInt(899999999)}';

        final orgRes = await api.post('/api/v1/organizations', data: {
          'legal_name': orgName,
          'tax_id': taxId,
          'business_type': 'SUPERMARKET',
          'owner_user_id': userId,
        });
        final orgId = orgRes.data['organization_id'];

        final siteRes = await api.post('/api/v1/organizations/$orgId/sites', data: {
          'site_code': 'SEDE-0${random.nextInt(9) + 1}',
          'name': 'Sede Principal',
          'contracted_power_kw': 35.0 + random.nextInt(25),
          'tariff_category': 'BT3',
          'floor_area_m2': 200.0 + random.nextInt(250),
        });
        siteId = siteRes.data['site_id'].toString();
      }

      // 2. Medidor Principal
      String meterId = '';
      try {
        final meterRes = await api.post('/api/v1/energy-meters', data: {
          'user_id': userId,
          'site_id': siteId,
          'meter_serial': 'MTR-${10000 + random.nextInt(90000)}',
          'model': 'SmartMeter PRO-X${random.nextInt(5) + 1}',
          'brand': 'SEMS Power',
          'location': 'Tablero General Principal',
          'firmware_version': '3.2.${random.nextInt(9)}',
          'max_power_watts': 40000,
        });
        meterId = (meterRes.data['id'] ?? meterRes.data['meter_id'] ?? '').toString();
      } catch (_) {}

      // 3. Catálogo de Dispositivos (4 a 9 dispositivos al azar con settings al azar)
      final catalog = [
        {
          'name': 'Aire Acondicionado Inverter',
          'type': 'HVAC',
          'brands': ['Daikin', 'Carrier', 'LG', 'Mitsubishi'],
          'models': ['Inverter 24K', 'VRV-IV', 'Multi-V 5', 'PowerAir 36'],
          'protocols': ['WIFI', 'ZIGBEE', 'MATTER'],
          'watts': 3200.0,
        },
        {
          'name': 'Cámara Frigorífica Carnes',
          'type': 'REFRIGERATION',
          'brands': ['Danfoss', 'Bitzer', 'Copeland', 'Hussmann'],
          'models': ['Optima Plus', 'Ecoline 2G', 'Scroll ZB', 'ColdStore 100'],
          'protocols': ['ZIGBEE', 'WIFI'],
          'watts': 4500.0,
        },
        {
          'name': 'Vitrina Refrigerada Bebidas',
          'type': 'REFRIGERATION',
          'brands': ['Carrier', 'Bizerba', 'Koxka', 'Fricon'],
          'models': ['FrostLine 3', 'CoolDisplay 200', 'VisioVitr', 'ProChill'],
          'protocols': ['WIFI', 'BLUETOOTH'],
          'watts': 1600.0,
        },
        {
          'name': 'Iluminación LED Salón Principal',
          'type': 'LIGHTING',
          'brands': ['Philips', 'Osram', 'Signify', 'Sylvania'],
          'models': ['CoreLine 45W', 'SubstiTUBE T8', 'SmartPanel', 'Ledvance Pro'],
          'protocols': ['ZIGBEE', 'BLUETOOTH'],
          'watts': 850.0,
        },
        {
          'name': 'Iluminación Fachada y Rótulo',
          'type': 'LIGHTING',
          'brands': ['Philips', 'General Electric', 'Osram'],
          'models': ['FloodLight 150', 'DecoSign LED', 'OutLux 80'],
          'protocols': ['BLUETOOTH', 'WIFI'],
          'watts': 400.0,
        },
        {
          'name': 'Horno Convector Eléctrico',
          'type': 'MACHINERY',
          'brands': ['Rational', 'Unox', 'BakeOff', 'Lainox'],
          'models': ['iCombi Classic', 'Cheftop Mind.Maps', 'BakeMaster 6', 'Naboo 5'],
          'protocols': ['WIFI'],
          'watts': 5500.0,
        },
        {
          'name': 'Compresor de Aire Auxiliar',
          'type': 'MACHINERY',
          'brands': ['Atlas Copco', 'Kaeser', 'Ingersoll Rand', 'Bitzer'],
          'models': ['GA 11 VSD', 'Aircenter SK', 'UP6 15', 'CS-200'],
          'protocols': ['ZIGBEE', 'WIFI'],
          'watts': 3000.0,
        },
        {
          'name': 'Servidor Central y CCTV',
          'type': 'ELECTRONICS',
          'brands': ['Schneider Electric', 'APC', 'Dell', 'Hikvision'],
          'models': ['Smart-UPS 3000', 'PowerEdge R440', 'NVR-Pro 32CH', 'Back-UPS Pro'],
          'protocols': ['WIFI'],
          'watts': 1100.0,
        },
        {
          'name': 'Terminales POS y Cajas',
          'type': 'ELECTRONICS',
          'brands': ['HP', 'NCR', 'Posiflex', 'Toshiba'],
          'models': ['Engage One Pro', 'RealPOS 70', 'XT-3815', 'SurePOS 500'],
          'protocols': ['WIFI'],
          'watts': 350.0,
        },
        {
          'name': 'Sistema de Extracción de Aire',
          'type': 'HVAC',
          'brands': ['Soler & Palau', 'Vortice', 'Casals', 'Systemair'],
          'models': ['TD-Silent 1000', 'Lineo 200', 'BoxFan Silent', 'K-Vent 160'],
          'protocols': ['MATTER', 'WIFI'],
          'watts': 750.0,
        },
        {
          'name': 'Congelador Isla Autoservicio',
          'type': 'REFRIGERATION',
          'brands': ['AHT', 'Liebherr', 'Bosch', 'Carrier'],
          'models': ['Miami 250', 'GGPv 6570', 'SuperFreeze 500', 'IslandCool 2'],
          'protocols': ['WIFI'],
          'watts': 1900.0,
        },
        {
          'name': 'Calentador Industrial de Agua',
          'type': 'APPLIANCE',
          'brands': ['Rheem', 'Bosch', 'Sole', 'Ariston'],
          'models': ['Commercial 80L', 'Therm 6000', 'MaxiAqua 100', 'ProTech 50'],
          'protocols': ['BLUETOOTH', 'WIFI'],
          'watts': 2500.0,
        },
      ];

      // Exactamente entre 4 y 9 dispositivos
      final int deviceCount = 4 + random.nextInt(6);
      catalog.shuffle(random);
      final selectedTemplates = catalog.take(deviceCount).toList();

      final List<Map<String, dynamic>> createdDevices = [];

      for (int i = 0; i < selectedTemplates.length; i++) {
        final t = selectedTemplates[i];
        final brands = t['brands'] as List<String>;
        final models = t['models'] as List<String>;
        final protocols = t['protocols'] as List<String>;

        final brand = brands[random.nextInt(brands.length)];
        final model = models[random.nextInt(models.length)];
        final proto = protocols[random.nextInt(protocols.length)];
        final code = 'DEV-${10000 + random.nextInt(90000)}';

        // 80% ACTIVE, 10% INACTIVE, 10% MAINTENANCE
        final statusRoll = random.nextInt(10);
        final statusStr = statusRoll == 0 ? 'INACTIVE' : (statusRoll == 1 ? 'MAINTENANCE' : 'ACTIVE');

        try {
          final devRes = await api.post('/api/v1/device-management/devices', data: {
            'externalDeviceCode': code,
            'userId': userId,
            'siteId': siteId,
            'deviceName': t['name'],
            'deviceType': t['type'],
            'brand': brand,
            'model': model,
            'connectionProtocol': proto,
          });

          final devId = (devRes.data['deviceId'] ?? devRes.data['device_id'] ?? devRes.data['id'] ?? '').toString();

          if (statusStr != 'ACTIVE' && devId.isNotEmpty) {
            await api.patch('/api/v1/device-management/devices/$devId/status', data: {'status': statusStr});
          }

          createdDevices.add({
            'id': devId,
            'name': t['name'],
            'watts': (t['watts'] as num).toDouble(),
          });
        } catch (_) {}
      }

      // 4. Lecturas de Energía (para graficar Dashboard)
      if (meterId.isNotEmpty && createdDevices.isNotEmpty) {
        final List<Future> readingFutures = [];
        for (int day = 0; day < 4; day++) {
          final timestamp = DateTime.now().toUtc().subtract(Duration(days: day, hours: 2)).toIso8601String();
          for (var dev in createdDevices) {
            final devId = dev['id'] as String;
            final watts = dev['watts'] as double;
            final kwh = (watts / 1000.0) * (1.5 + random.nextDouble() * 2.0);

            readingFutures.add(
              api.post('/api/v1/energy-readings', data: {
                'user_id': userId,
                'meter_id': meterId,
                'device_id': devId,
                'power_watts': watts,
                'voltage': 220.0 + random.nextDouble() * 5.0,
                'current': (watts / 220.0),
                'frequency': 60.0,
                'energy_kwh': double.parse(kwh.toStringAsFixed(2)),
                'timestamp': timestamp,
                'reading_type': 'CONSUMPTION',
                'phase': '1',
              }).catchError((_) => null),
            );
          }
        }
        await Future.wait(readingFutures);
      }

      // 5. Alertas al Azar vinculadas a los dispositivos creados
      if (createdDevices.isNotEmpty) {
        final alertTemplates = [
          {
            'type': 'CONSUMPTION_SPIKE',
            'title': 'Pico de consumo inusual',
            'msg': 'Se detectó una demanda 35% superior a la línea base programada.',
            'sev': 'HIGH',
          },
          {
            'type': 'DEVICE_OFFLINE',
            'title': 'Dispositivo fuera de línea',
            'msg': 'El dispositivo perdió la señal de telemetría IoT.',
            'sev': 'MEDIUM',
          },
          {
            'type': 'THRESHOLD_EXCEEDED',
            'title': 'Consumo fuera de horario comercial',
            'msg': 'Consumo activo detectado fuera de la ventana operativa autorizada.',
            'sev': 'HIGH',
          },
          {
            'type': 'ANOMALY',
            'title': 'Factor de potencia bajo',
            'msg': 'Medición de factor de potencia inductivo menor a 0.85.',
            'sev': 'MEDIUM',
          },
          {
            'type': 'CONSUMPTION_SPIKE',
            'title': 'Alerta preventiva de sobrecarga',
            'msg': 'El equipo reporta ciclos continuos sin modulación térmica.',
            'sev': 'CRITICAL',
          },
        ];

        alertTemplates.shuffle(random);
        final alertCount = min(createdDevices.length, 2 + random.nextInt(3)); // 2 a 4 alertas

        for (int i = 0; i < alertCount; i++) {
          final t = alertTemplates[i % alertTemplates.length];
          final dev = createdDevices[i];
          try {
            await api.post('/api/v1/alerts', data: {
              'user_id': userId,
              'device_id': dev['id'],
              'alert_type': t['type'],
              'title': '${t['title']} (${dev['name']})',
              'message': t['msg'],
              'severity': t['sev'],
              'status': 'active',
              'triggered_at': DateTime.now().toUtc().subtract(Duration(hours: random.nextInt(48))).toIso8601String(),
            });
          } catch (_) {}
        }
      }

      // 6. Recomendaciones de IA en Analíticas (incluyendo recomendación de ~7 soles)
      final recTemplates = [
        {
          'title': 'Desconectar Terminales al Cierre',
          'desc': 'Apagar terminales POS y equipos en reposo durante la noche.',
          'kwh': 9.0,
          'amount': 7.00,
        },
        {
          'title': 'Optimizar Climatización HVAC',
          'desc': 'Configurar termostatos a 24°C durante el horario de mayor afluencia.',
          'kwh': 18.0,
          'amount': 15.50,
        },
        {
          'title': 'Modulación de Frío en Horario Punta',
          'desc': 'Pre-enfriar antes de las 18:00 y reducir compresores entre 18:00 y 23:00.',
          'kwh': 32.0,
          'amount': 25.00,
        },
        {
          'title': 'Atenuación LED en Zonas Secundarias',
          'desc': 'Reducir la intensidad al 70% en pasillos de almacén y oficinas.',
          'kwh': 12.0,
          'amount': 10.00,
        },
      ];

      for (int i = 0; i < recTemplates.length; i++) {
        final r = recTemplates[i];
        final devId = createdDevices.isNotEmpty ? createdDevices[i % createdDevices.length]['id'] : null;
        try {
          await api.post('/api/v1/analytics/recommendations', data: {
            'user_id': userId,
            'device_id': devId,
            'recommendation_type': 'USAGE_OPTIMIZATION',
            'title': r['title'],
            'description': r['desc'],
            'estimated_saving_kwh': r['kwh'],
            'estimated_saving_amount': r['amount'],
            'currency': 'PEN',
            'status': 'PENDING',
            'generated_at': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (_) {}
      }

      // 7. Suscripción por defecto (Plan Pro)
      try {
        final plansRes = await api.get('/api/v1/subscription-plans');
        if (plansRes.data is List && (plansRes.data as List).isNotEmpty) {
          final plan = (plansRes.data as List).firstWhere(
            (p) => (p['name'] ?? '').toString().toLowerCase().contains('pro'),
            orElse: () => plansRes.data[0],
          );
          final planId = plan['plan_id'] ?? plan['id'];
          await api.post('/api/v1/subscriptions', data: {
            'userId': userId,
            'planId': planId,
          });
        }
      } catch (_) {}

      // 8. Pronóstico de Facturación Base
      try {
        await api.post('/api/v1/analytics/bill-predictions', data: {
          'user_id': userId,
          'prediction_year': DateTime.now().year,
          'prediction_month': DateTime.now().month,
          'period_start': DateTime.now().toUtc().subtract(const Duration(days: 15)).toIso8601String(),
          'period_end': DateTime.now().toUtc().add(const Duration(days: 15)).toIso8601String(),
          'estimated_kwh': 450.0,
          'estimated_amount': 380.0,
          'currency': 'PEN',
          'tariff_used': 0.78,
          'error_margin_percentage': 5.0,
        });
      } catch (_) {}
    } catch (_) {}
  }
}
