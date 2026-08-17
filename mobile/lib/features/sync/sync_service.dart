import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/database/app_database.dart';
import '../../core/services/connectivity_service.dart';

/// Owns the sync queue: pushes pending/failed local inspections to the
/// API, retrying automatically whenever connectivity comes back, and
/// on demand (manual sync button / retry action).
class SyncService {
  SyncService({
    required AppDatabase database,
    required ApiClient apiClient,
    required ConnectivityService connectivityService,
  })  : _database = database,
        _apiClient = apiClient,
        _connectivityService = connectivityService;

  final AppDatabase _database;
  final ApiClient _apiClient;
  final ConnectivityService _connectivityService;

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;

  /// Starts listening for connectivity changes to trigger automatic sync.
  /// Call once at app startup.
  void start() {
    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen((isOnline) {
      if (isOnline) syncAll();
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Attempts to sync every pending/failed inspection currently queued.
  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final queued = await _database.pendingOrFailedInspections();
      for (final item in queued) {
        await _syncOne(item);
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Retries a single inspection by its local id (used by the "tentar
  /// novamente" action in the history screen).
  Future<void> retry(int localId) async {
    final item = await (_database.select(_database.inspections)
          ..where((t) => t.localId.equals(localId)))
        .getSingleOrNull();
    if (item == null) return;
    await _syncOne(item);
  }

  Future<void> _syncOne(InspectionRow item) async {
    if (item.status == InspectionStatus.draft) return;

    try {
      final formData = FormData.fromMap({
        'clientId': item.clientId,
        'workOrderId': item.workOrderId,
        'observation': item.observation,
        if (item.condition != null) 'condition': item.condition,
        'latitude': item.latitude,
        'longitude': item.longitude,
        'capturedAt': item.capturedAt,
        if (item.photoPath != null && File(item.photoPath!).existsSync())
          'photo': await MultipartFile.fromFile(item.photoPath!),
      });

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/inspections',
        data: formData,
      );
      final data = response.data!;

      await _database.updateInspection(item.copyWith(
        status: InspectionStatus.synced,
        serverId: Value(data['id'] as String?),
        syncedAt: Value(data['syncedAt'] as String? ?? DateTime.now().toIso8601String()),
        errorMessage: const Value(null),
      ));
    } on ApiException catch (e) {
      await _database.updateInspection(item.copyWith(
        status: InspectionStatus.failed,
        errorMessage: Value(e.message),
      ));
    }
  }
}
