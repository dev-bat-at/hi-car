import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/logger.dart';

/// Performance-optimized API Client with memory caching and Bearer Auth.
class ApiClient {
  static const String baseUrl = 'https://admintts.kingcong.shop';

  late final Dio _dio;
  final Map<String, dynamic> _memoryCache = {};

  // Singleton
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Fix for some older Android devices with outdated certificates
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          print('🚀 API Request: [${options.method}] ${options.path}');
          if (options.data != null) print('📦 Request Data: ${options.data}');
          if (options.queryParameters.isNotEmpty)
            print('🔍 Query Params: ${options.queryParameters}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print(
              '✅ API Response: [${response.statusCode}] ${response.requestOptions.path}');
          print('📄 Response Data: ${response.data}');
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (kDebugMode) {
          print(
              '❌ API Error: [${e.response?.statusCode}] ${e.requestOptions.path}');
          if (e.response?.data != null)
            print('❗ Error Data: ${e.response?.data}');
          print('💡 Message: ${e.message}');
        }

        // Capture in local logs
        AppLogger.instance.log(
          'Lỗi mạng: [${e.response?.statusCode}] ${e.requestOptions.path}',
          type: 'network_error',
          details: {
            'statusCode': e.response?.statusCode,
            'path': e.requestOptions.path,
            'data': e.response?.data,
            'message': e.message,
          },
        );

        // 🔴 Rule: 1 Account = 1 Device. Revoke on 401 Unauthorized.
        if (e.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');
          // Note: In a real app, you'd trigger a logout event here via an EventBus or a Provider.
          // For now, the next time the app checks token, it will be null.
        }
        return handler.next(e);
      },
    ));
  }

  static final ApiClient instance = ApiClient._();

  // ===== Cached Methods (Memory Cache) =====

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters, bool useCache = false}) async {
    final cacheKey = '$path${queryParameters?.toString() ?? ''}';

    if (useCache && _memoryCache.containsKey(cacheKey)) {
      if (kDebugMode) print('⏺ Using Memory Cache for: $cacheKey');
      return _memoryCache[cacheKey];
    }

    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      if (useCache) _memoryCache[cacheKey] = response;
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      // Clear relevant cache on POST (data might have changed)
      _memoryCache.clear();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  void clearCache() => _memoryCache.clear();
}
