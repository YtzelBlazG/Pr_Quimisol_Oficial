import 'package:dio/dio.dart';
import '../config/env.dart';

class DioClient {
  static final Dio _dio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl));
  static Dio get instance => _dio;
}
