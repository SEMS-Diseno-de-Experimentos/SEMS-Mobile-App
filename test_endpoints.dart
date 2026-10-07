import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
  
  try {
    // 1. Login to get token
    final loginRes = await dio.post('/api/v1/auth/login', data: {
      'emailAddress': 'john.doe@example.com',
      'password': 'password123'
    });
    
    final token = loginRes.data['token'];
    print('Got token: $token');
    
    dio.options.headers['Authorization'] = 'Bearer $token';
    
    // 2. Get Me to get user ID
    final meRes = await dio.get('/api/v1/auth/me');
    final userId = meRes.data['user_id'];
    print('User ID: $userId');
    
    // 3. Test Subscription endpoints
    try {
      final subRes = await dio.get('/api/v1/subscriptions/users/$userId');
      print('Subscriptions: ${subRes.data}');
    } catch(e) {
      print('Subscription Error: $e');
      if (e is DioException) {
        print('Response: ${e.response?.data}');
      }
    }
    
    try {
      final planRes = await dio.get('/api/v1/subscription-plans');
      print('Plans: ${planRes.data}');
    } catch(e) {
      print('Plans Error: $e');
    }
    
    // 4. Test Analytics endpoints
    try {
      final predRes = await dio.get('/api/v1/analytics/bill-predictions/user/$userId');
      print('Predictions: ${predRes.data}');
    } catch(e) {
      print('Predictions Error: $e');
    }
    
    try {
      final recRes = await dio.get('/api/v1/analytics/recommendations/user/$userId');
      print('Recommendations: ${recRes.data}');
    } catch(e) {
      print('Recommendations Error: $e');
    }
    
    try {
      final rankRes = await dio.get('/api/v1/analytics/consumption-rankings/user/$userId');
      print('Rankings: ${rankRes.data}');
    } catch(e) {
      print('Rankings Error: $e');
    }
    
  } catch(e) {
    if (e is DioException) {
      print('Login Error: ${e.response?.statusCode} ${e.response?.statusMessage}');
      print('Data: ${e.response?.data}');
    } else {
      print('Error: $e');
    }
  }
}
