import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
  try {
    final res = await dio.get('/api/v1/subscription-plans');
    print(res.statusCode);
  } catch(e) {
    if (e is DioException) {
      print('DioException: ${e.response?.statusCode} ${e.response?.statusMessage}');
      print('Response Data: ${e.response?.data}');
    } else {
      print(e);
    }
  }
}
