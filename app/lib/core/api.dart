import 'package:dio/dio.dart';

import 'app_config.dart';

class ApiException implements Exception {
  final int code;
  final String message;
  ApiException(this.code, this.message);

  @override
  String toString() => message;
}

class Api {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  static void _prepare() {
    _dio.options.baseUrl = '${AppConfig.baseUrl}/api/v1';
    if (AppConfig.token != null) {
      _dio.options.headers['Authorization'] = 'Bearer ${AppConfig.token}';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  static Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    _prepare();
    try {
      final res = await _dio.get(path, queryParameters: query);
      return _unwrap(res.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  static Future<dynamic> post(String path, {Object? data}) async {
    _prepare();
    try {
      final res = await _dio.post(path, data: data);
      return _unwrap(res.data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  static dynamic _unwrap(dynamic body) {
    if (body is Map && body['code'] is int) {
      final code = body['code'] as int;
      if (code != 0) {
        throw ApiException(code, (body['msg'] ?? '请求失败').toString());
      }
      return body['data'];
    }
    return body;
  }

  static ApiException _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return ApiException(-1, '连不上服务器\n请确认：电脑已开机、服务已启动、手机与电脑在同一 WiFi');
    }
    return ApiException(-2, e.message ?? '网络异常');
  }
}
