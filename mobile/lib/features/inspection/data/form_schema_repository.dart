import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import 'form_schema.dart';

/// Fetches the (optional, opcional-scope) dynamic form schema for a work
/// order's inspection form. Returns null on any failure — most commonly
/// because the device is offline — so the caller can fall back to the
/// fixed set of fields without the schema ever gating the form.
class FormSchemaRepository {
  FormSchemaRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<InspectionFormSchema?> fetch(String workOrderId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/work-orders/$workOrderId/form-schema',
      );
      return InspectionFormSchema.fromJson(response.data!);
    } on ApiException {
      return null;
    }
  }
}
