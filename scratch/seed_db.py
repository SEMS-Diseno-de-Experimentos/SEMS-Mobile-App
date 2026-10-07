import urllib.request
import json
import time
import uuid

BASE_URL = 'http://localhost:8080/api/v1'

def post(path, data, token=None):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    req = urllib.request.Request(BASE_URL + path, data=json.dumps(data).encode('utf-8'), headers=headers, method='POST')
    try:
        with urllib.request.urlopen(req) as res:
            return json.loads(res.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        print(f'Error {path}: {e.code} - {e.read().decode("utf-8")}')
        return None
    except Exception as e:
        print(f'Error {path}: {e}')
        return None

def main():
    print("Iniciando simulación de datos completa...")
    
    email = f'demo_{uuid.uuid4().hex[:6]}@sems.com'
    print(f"Registrando usuario {email}...")
    user_res = post('/auth/register', {
        'emailAddress': email,
        'password': 'Password123!'
    })
    
    if not user_res:
        print("Fallo el registro, abortando.")
        return

    token = user_res['token']
    user_id = user_res['userId']
    print(f"Usuario registrado: {user_id}")

    import random
    print("Creando organización...")
    org = post('/organizations', {
        'legal_name': f'Demo Corp {uuid.uuid4().hex[:4]}',
        'tax_id': f'20{random.randint(100000000, 999999999)}',
        'business_type': 'RESTAURANT',
        'owner_user_id': user_id
    }, token)
    
    if not org:
        return
    org_id = org['organization_id']

    print("Creando sitio (local)...")
    site = post(f'/organizations/{org_id}/sites', {
        'site_code': 'LOC-001',
        'name': 'Restaurante Central',
        'contracted_power_kw': 50,
        'tariff_category': 'BT5B'
    }, token)
    
    if not site:
        return
    site_id = site['site_id']

    print("Registrando medidor principal...")
    meter = post('/energy-meters', {
        'user_id': user_id,
        'meter_serial': f'MTR-DEMO-{uuid.uuid4().hex[:6]}',
        'model': 'SmartMeter X1',
        'brand': 'Acme',
        'location': 'Tablero Principal',
        'firmware_version': '1.0.0',
        'max_power_watts': 10000
    }, token)
    meter_id = meter['id'] if meter else None

    print("Registrando dispositivo 1 (Aire Acondicionado)...")
    device1 = post('/device-management/devices', {
        'userId': user_id,
        'siteId': site_id,
        'externalDeviceCode': f'AC-DEMO-{uuid.uuid4().hex[:6]}',
        'deviceName': 'Aire Acondicionado',
        'deviceType': 'AC',
        'brand': 'LG',
        'model': 'Dual Inverter',
        'connectionProtocol': 'WiFi'
    }, token)
    
    if device1:
        post(f'/device-management/devices/{device1["deviceId"]}/status', {'status': 'INACTIVE'}, token)

    print("Registrando dispositivo 2 (Iluminación)...")
    device2 = post('/device-management/devices', {
        'userId': user_id,
        'siteId': site_id,
        'externalDeviceCode': f'LGT-DEMO-{uuid.uuid4().hex[:6]}',
        'deviceName': 'Luces Comedor',
        'deviceType': 'LIGHTING',
        'brand': 'Philips',
        'model': 'Hue Pro',
        'connectionProtocol': 'Zigbee'
    }, token)
    
    if device2:
        post(f'/device-management/devices/{device2["deviceId"]}/status', {'status': 'ARCHIVED'}, token)

    print("Registrando dispositivo 3 (Televisor)...")
    device3 = post('/device-management/devices', {
        'userId': user_id,
        'siteId': site_id,
        'externalDeviceCode': f'TV-DEMO-{uuid.uuid4().hex[:6]}',
        'deviceName': 'Televisor Recepción',
        'deviceType': 'TV',
        'brand': 'Samsung',
        'model': 'SmartTV 55',
        'connectionProtocol': 'WiFi'
    }, token)
    
    device3_id = device3['deviceId'] if device3 else None

    print("Generando lecturas de energía para la gráfica (14 días)...")
    for i in range(14):
        for j in range(5):
            post('/energy/simulate-readings', {
                'UserId': user_id,
                'DeviceId': device3_id,
                'MeterId': meter_id,
                'PowerWatts': 150 + (i*10) + (j*5),
                'Voltage': 220,
                'Current': 0.7
            })
            time.sleep(0.05)

    if device3_id:
        print("Generando Recomendación de IA...")
        post('/analytics/recommendations', {
            'user_id': user_id,
            'device_id': device3_id,
            'recommendation_type': 'USAGE_REDUCTION',
            'title': 'Reduce el uso de TV',
            'description': 'Apaga la TV de noche para ahorrar S/ 15 al mes.',
            'estimated_saving_kwh': 12.5,
            'estimated_saving_amount': 15.00,
            'currency': 'PEN'
        }, token)
        
        print("Generando Alerta de Consumo...")
        post('/alerts', {
            'user_id': user_id,
            'device_id': device3_id,
            'alert_type': 'CONSUMPTION_SPIKE',
            'title': 'Pico de consumo inusual',
            'message': 'El Televisor de Recepción está consumiendo un 30% más de lo habitual.',
            'severity': 'HIGH',
            'status': 'TRIGGERED',
            'triggered_at': '2026-09-12T12:00:00Z'
        }, token)

    print("Datos simulados insertados correctamente en el Backend.")

if __name__ == '__main__':
    main()
