/// Error surfaced from the mock API, normalized from Dio's exceptions.
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors,
  });

  final String message;
  final int? statusCode;
  final Map<String, List<String>>? fieldErrors;

  bool get isNetworkError => statusCode == null;
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}
