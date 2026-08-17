import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Base URL for the mock API.
///
/// Points at the device's own `localhost`. For the Android emulator,
/// `10.0.2.2` is the special alias that reaches the host machine
/// directly. For a **physical device**, run:
///   `adb reverse tcp:3000 tcp:3000`
/// which forwards the device's localhost:3000 to the host machine
/// through the existing ADB connection (USB or wireless) — this works
/// even when the phone and PC can't otherwise reach each other over
/// the LAN (e.g. router client/AP isolation). See the README.
const String kApiBaseUrl = 'http://127.0.0.1:3000';

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
