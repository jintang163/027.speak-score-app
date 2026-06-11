import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../config/api_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onResponse: _onResponse,
      onError: _onError,
    ));
  }

  Dio get dio => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    handler.next(response);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final refreshResponse = await _dio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
            options: Options(headers: {'Authorization': ''}),
          );

          if (refreshResponse.statusCode == 200) {
            final data = refreshResponse.data['data'] ?? refreshResponse.data;
            final newAccessToken = data['accessToken'] as String?;
            final newRefreshToken = data['refreshToken'] as String?;

            if (newAccessToken != null) {
              await _secureStorage.write(
                  key: 'access_token', value: newAccessToken);
              if (newRefreshToken != null) {
                await _secureStorage.write(
                    key: 'refresh_token', value: newRefreshToken);
              }

              err.requestOptions.headers['Authorization'] =
                  'Bearer $newAccessToken';
              final retryResponse = await _dio.fetch(err.requestOptions);
              return handler.resolve(retryResponse);
            }
          }
        } catch (_) {
          // refresh failed, fall through to clear tokens
        }

        await _secureStorage.delete(key: 'access_token');
        await _secureStorage.delete(key: 'refresh_token');
      }
    }
    handler.next(err);
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> upload(
    String path, {
    required String filePath,
    required String fileName,
    String fieldName = 'file',
    Map<String, dynamic>? extraFields,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath, filename: fileName),
      if (extraFields != null) ...extraFields,
    });

    return _dio.post(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onSendProgress,
    );
  }

  Future<String> download(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? savePath,
  }) async {
    final directory = await getTemporaryDirectory();
    final fileName = savePath ?? 'download_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final fullPath = '${directory.path}/$fileName';

    await _dio.download(
      path,
      fullPath,
      queryParameters: queryParameters,
    );

    return fullPath;
  }
}
