import 'package:dio/dio.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/config/api_endpoints.dart';

class AuthApi {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post(
      ApiEndpoints.login,
      data: {'correo': email, 'contrasena': password},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    final res = await _dio.post(ApiEndpoints.signup, data: body);
    return res.data as Map<String, dynamic>;
  }
}
