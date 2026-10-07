import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
  
  try {
    // 3. Simulate readings
    print('Starting IoT Simulation (Sending 10 readings over 10 seconds)...');
    
    for (int i = 1; i <= 10; i++) {
      // Simulate high power to trigger recommendation (e.g. 5000 Watts)
      double powerWatts = 5000.0 + (i * 10);
      
      final res = await dio.post('/api/v1/energy/simulate-readings', data: {
        'powerWatts': powerWatts,
        'voltage': 220.0,
        'current': powerWatts / 220.0
      });
      
      print('Sent reading $i: $powerWatts Watts -> Device ${res.data['deviceId']}');
      await Future.delayed(Duration(seconds: 1));
    }
    
    print('Simulation complete. You can now check the app Dashboard and Alerts!');

  } catch (e) {
    if (e is DioException) {
      print('API Error: ${e.response?.statusCode} - ${e.response?.data}');
    } else {
      print('Error: $e');
    }
  }
}
