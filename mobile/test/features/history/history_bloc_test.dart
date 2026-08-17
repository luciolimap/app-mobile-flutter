import 'package:bloc_test/bloc_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/history/bloc/history_bloc.dart';
import 'package:mobile/features/sync/sync_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockSyncService extends Mock implements SyncService {}

void main() {
  late AppDatabase database;
  late _MockSyncService syncService;

  InspectionsCompanion buildInspection({
    required String clientId,
    required String status,
  }) {
    return InspectionsCompanion.insert(
      clientId: clientId,
      workOrderId: 'wo_1001',
      observation: 'Observação de teste',
      latitude: -7.12,
      longitude: -34.85,
      capturedAt: DateTime(2026, 8, 17).toIso8601String(),
      status: status,
      createdAt: DateTime(2026, 8, 17).toIso8601String(),
    );
  }

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    syncService = _MockSyncService();
    when(() => syncService.syncAll()).thenAnswer((_) async {});
    when(() => syncService.retry(any())).thenAnswer((_) async {});
  });

  tearDown(() => database.close());

  blocTest<HistoryBloc, HistoryState>(
    'loads existing inspections from the local database on start',
    setUp: () async {
      await database.insertInspection(
        buildInspection(clientId: 'a', status: InspectionStatus.pending),
      );
      await database.insertInspection(
        buildInspection(clientId: 'b', status: InspectionStatus.synced),
      );
    },
    build: () => HistoryBloc(database: database, syncService: syncService),
    act: (bloc) => bloc.add(const HistoryStarted()),
    wait: const Duration(milliseconds: 100),
    expect: () => [
      isA<HistoryState>().having((s) => s.allItems.length, 'allItems.length', 2),
    ],
  );

  blocTest<HistoryBloc, HistoryState>(
    'filters items by status, keeping only matching entries',
    setUp: () async {
      await database.insertInspection(
        buildInspection(clientId: 'a', status: InspectionStatus.pending),
      );
      await database.insertInspection(
        buildInspection(clientId: 'b', status: InspectionStatus.failed),
      );
    },
    build: () => HistoryBloc(database: database, syncService: syncService),
    act: (bloc) async {
      bloc.add(const HistoryStarted());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      bloc.add(const HistoryFilterChanged(InspectionStatus.failed));
    },
    skip: 1,
    expect: () => [
      isA<HistoryState>()
          .having((s) => s.filteredItems.length, 'filteredItems.length', 1)
          .having(
            (s) => s.filteredItems.single.clientId,
            'filteredItems.single.clientId',
            'b',
          ),
    ],
  );

  blocTest<HistoryBloc, HistoryState>(
    'manual sync toggles isSyncing and delegates to SyncService.syncAll',
    build: () => HistoryBloc(database: database, syncService: syncService),
    act: (bloc) => bloc.add(const HistorySyncNowPressed()),
    expect: () => [
      isA<HistoryState>().having((s) => s.isSyncing, 'isSyncing', true),
      isA<HistoryState>().having((s) => s.isSyncing, 'isSyncing', false),
    ],
    verify: (_) => verify(() => syncService.syncAll()).called(1),
  );

  blocTest<HistoryBloc, HistoryState>(
    'retry delegates to SyncService.retry with the tapped local id',
    build: () => HistoryBloc(database: database, syncService: syncService),
    act: (bloc) => bloc.add(const HistoryRetryPressed(7)),
    expect: () => [
      isA<HistoryState>().having((s) => s.isSyncing, 'isSyncing', true),
      isA<HistoryState>().having((s) => s.isSyncing, 'isSyncing', false),
    ],
    verify: (_) => verify(() => syncService.retry(7)).called(1),
  );
}
