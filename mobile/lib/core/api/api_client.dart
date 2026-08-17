import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Base URL for the mock API.
///
/// `10.0.2.2` is the special alias the Android emulator uses to reach
/// `localhost` on the host machine. For a physical device on the same
/// Wi-Fi network, replace this with the host machine's LAN IP
/// (e.g. `http://192.168.0.10:3000`) — see the README.
const String kApiBaseUrl = 'http://10.0.2.2:3000';

/// Thin wrapper around Dio: attaches the bearer token to every request
/// (except login) and normalizes errors into [ApiException].
class ApiClient {
  ApiClient({required TokenStorage tokenStorage, Dio? dio})
      : _tokenStorage = tokenStorage,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: kApiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!options.path.contains('/auth/login')) {
          final token = await _tokenStorage.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
    ));
  }

  final TokenStorage _tokenStorage;
  final Dio _dio;

  Dio get raw => _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) {
    return _guard(() => _dio.get<T>(path, queryParameters: query));
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return _guard(() => _dio.post<T>(path, data: data));
  }

  Future<Response<T>> _guard<T>(Future<Response<T>> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final response = e.response;
    if (response == null) {
      return ApiException(
        message: 'Sem conexão com o servidor. Verifique sua internet.',
      );
    }
    final data = response.data;
    String message = 'Erro inesperado (${response.statusCode}).';
    Map<String, List<String>>? fieldErrors;
    if (data is Map) {
      if (data['message'] is String) message = data['message'] as String;
      final rawErrors = data['errors'];
      if (rawErrors is Map) {
        fieldErrors = rawErrors.map(
          (key, value) => MapEntry(
            key.toString(),
            (value as List).map((v) => v.toString()).toList(),
          ),
        );
      }
    }
    return ApiException(
      message: message,
      statusCode: response.statusCode,
      fieldErrors: fieldErrors,
    );
  }
}
