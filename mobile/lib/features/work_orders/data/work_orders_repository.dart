import '../../../core/api/api_client.dart';
import '../../../core/database/app_database.dart';
import 'work_order.dart';

class WorkOrdersRepository {
  WorkOrdersRepository({
    required ApiClient apiClient,
    required AppDatabase database,
  })  : _apiClient = apiClient,
        _database = database;

  final ApiClient _apiClient;
  final AppDatabase _database;

  /// Fetches the latest list from the API and refreshes the local cache.
  /// Callers should fall back to [watchCached] when this throws (offline).
  Future<void> refresh() async {
    final response = await _apiClient.get<List<dynamic>>('/work-orders');
    final items = response.data!
        .map((e) => WorkOrder.fromJson(e as Map<String, dynamic>))
        .toList();
    await _database.replaceWorkOrders(
      items.map((e) => e.toCacheRow()).toList(),
    );
  }

  Stream<List<WorkOrder>> watchCached() {
    return _database
        .watchWorkOrders()
        .map((rows) => rows.map(WorkOrder.fromCache).toList());
  }
}
