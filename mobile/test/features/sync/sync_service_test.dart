import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/api_exception.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/features/sync/sync_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late AppDatabase database;
  late _MockApiClient apiClient;
  late SyncService syncService;

  Future<int> seedInspection({
    required String clientId,
    required String status,
  }) {
    return database.insertInspection(InspectionsCompanion.insert(
      clientId: clientId,
      workOrderId: 'wo_1001',
      observation: 'Observação de teste para sincronização',
      latitude: -7.12,
      longitude: -34.85,
      capturedAt: DateTime(2026, 8, 17).toIso8601String(),
      status: status,
      createdAt: DateTime(2026, 8, 17).toIso8601String(),
    ));
  }

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    apiClient = _MockApiClient();
    syncService = SyncService(
      database: database,
      apiClient: apiClient,
      connectivityService: _MockConnectivityService(),
    );
  });

  tearDown(() => database.close());

  test('marks a pending inspection as synced when the API accepts it', () async {
    await seedInspection(clientId: 'c1', status: InspectionStatus.pending);

    when(() => apiClient.post<Map<String, dynamic>>('/inspections', data: any(named: 'data')))
        .thenAnswer((_) async => Response<Map<String, dynamic>>(
              requestOptions: RequestOptions(path: '/inspections'),
              statusCode: 201,
              data: {
                'id': 'insp_9002',
                'syncedAt': '2026-08-17T12:00:00.000Z',
              },
            ));

    await syncService.syncAll();

    final row = await database.findByClientId('c1');
    expect(row!.status, InspectionStatus.synced);
    expect(row.serverId, 'insp_9002');
    expect(row.syncedAt, '2026-08-17T12:00:00.000Z');
    expect(row.errorMessage, isNull);
  });

  test('marks the inspection as failed with the error message when the API rejects it', () async {
    await seedInspection(clientId: 'c2', status: InspectionStatus.pending);

    when(() => apiClient.post<Map<String, dynamic>>('/inspections', data: any(named: 'data')))
        .thenThrow(ApiException(message: 'Sem conexão com o servidor.'));

    await syncService.syncAll();

    final row = await database.findByClientId('c2');
    expect(row!.status, InspectionStatus.failed);
    expect(row.errorMessage, 'Sem conexão com o servidor.');
  });

  test('never sends drafts to the API', () async {
    await seedInspection(clientId: 'c3', status: InspectionStatus.draft);

    await syncService.syncAll();

    verifyNever(() => apiClient.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        ));
    final row = await database.findByClientId('c3');
    expect(row!.status, InspectionStatus.draft);
  });

  test('a failed item becomes eligible for automatic retry on the next syncAll', () async {
    await seedInspection(clientId: 'c4', status: InspectionStatus.failed);

    when(() => apiClient.post<Map<String, dynamic>>('/inspections', data: any(named: 'data')))
        .thenAnswer((_) async => Response<Map<String, dynamic>>(
              requestOptions: RequestOptions(path: '/inspections'),
              statusCode: 200,
              data: {'id': 'insp_9003', 'syncedAt': '2026-08-17T12:05:00.000Z'},
            ));

    await syncService.syncAll();

    final row = await database.findByClientId('c4');
    expect(row!.status, InspectionStatus.synced);
  });

  test('retry(localId) resyncs only the targeted inspection', () async {
    final targetId = await seedInspection(clientId: 'c5', status: InspectionStatus.failed);
    await seedInspection(clientId: 'c6', status: InspectionStatus.pending);

    when(() => apiClient.post<Map<String, dynamic>>('/inspections', data: any(named: 'data')))
        .thenAnswer((_) async => Response<Map<String, dynamic>>(
              requestOptions: RequestOptions(path: '/inspections'),
              statusCode: 200,
              data: {'id': 'insp_9004', 'syncedAt': '2026-08-17T12:10:00.000Z'},
            ));

    await syncService.retry(targetId);

    verify(() => apiClient.post<Map<String, dynamic>>('/inspections', data: any(named: 'data')))
        .called(1);
    final synced = await database.findByClientId('c5');
    final untouched = await database.findByClientId('c6');
    expect(synced!.status, InspectionStatus.synced);
    expect(untouched!.status, InspectionStatus.pending);
  });
}
