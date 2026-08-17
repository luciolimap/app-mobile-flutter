import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api/api_exception.dart';
import 'package:mobile/features/work_orders/bloc/work_orders_bloc.dart';
import 'package:mobile/features/work_orders/data/work_order.dart';
import 'package:mobile/features/work_orders/data/work_orders_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockWorkOrdersRepository extends Mock implements WorkOrdersRepository {}

WorkOrder _buildWorkOrder(String id) => WorkOrder(
      id: id,
      code: 'OS-$id',
      title: 'Inspeção de poste $id',
      description: 'Verificar estado do poste.',
      address: 'Rua das Acácias, 120',
      priority: 'high',
      status: 'open',
      latitude: -7.1195,
      longitude: -34.8450,
      scheduledAt: '2026-07-28T13:00:00.000Z',
      updatedAt: '2026-07-26T12:00:00.000Z',
    );

void main() {
  late _MockWorkOrdersRepository repository;

  setUp(() {
    repository = _MockWorkOrdersRepository();
  });

  blocTest<WorkOrdersBloc, WorkOrdersState>(
    'loads the cache and refreshes successfully',
    setUp: () {
      when(() => repository.watchCached())
          .thenAnswer((_) => Stream.value([_buildWorkOrder('wo_1')]));
      when(() => repository.refresh()).thenAnswer((_) async {});
    },
    build: () => WorkOrdersBloc(repository: repository),
    act: (bloc) => bloc.add(const WorkOrdersStarted()),
    wait: const Duration(milliseconds: 100),
    verify: (bloc) {
      expect(bloc.state.status, WorkOrdersStatus.success);
      expect(bloc.state.items.length, 1);
      expect(bloc.state.errorMessage, isNull);
    },
  );

  blocTest<WorkOrdersBloc, WorkOrdersState>(
    'shows a failure state when the refresh fails with an empty cache',
    setUp: () {
      when(() => repository.watchCached()).thenAnswer((_) => const Stream.empty());
      when(() => repository.refresh()).thenThrow(
        ApiException(message: 'Sem conexão com o servidor.'),
      );
    },
    build: () => WorkOrdersBloc(repository: repository),
    act: (bloc) => bloc.add(const WorkOrdersStarted()),
    wait: const Duration(milliseconds: 100),
    verify: (bloc) {
      expect(bloc.state.status, WorkOrdersStatus.failure);
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.errorMessage, 'Sem conexão com o servidor.');
    },
  );

  blocTest<WorkOrdersBloc, WorkOrdersState>(
    'keeps showing cached items (cache-first) when a later refresh fails',
    setUp: () => when(() => repository.watchCached())
        .thenAnswer((_) => Stream.value([_buildWorkOrder('wo_1')])),
    build: () => WorkOrdersBloc(repository: repository),
    act: (bloc) async {
      // First load succeeds: cache populated, status settles to success.
      when(() => repository.refresh()).thenAnswer((_) async {});
      bloc.add(const WorkOrdersStarted());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Pull-to-refresh now fails (e.g. offline) with items already cached.
      when(() => repository.refresh()).thenThrow(
        ApiException(message: 'Sem conexão com o servidor.'),
      );
      bloc.add(const WorkOrdersRefreshRequested());
    },
    wait: const Duration(milliseconds: 100),
    verify: (bloc) {
      // Cache-first fallback: still "success" with the cached item shown,
      // not "failure" — only the error message surfaces alongside it.
      expect(bloc.state.status, WorkOrdersStatus.success);
      expect(bloc.state.items.length, 1);
      expect(bloc.state.errorMessage, 'Sem conexão com o servidor.');
    },
  );

  blocTest<WorkOrdersBloc, WorkOrdersState>(
    'clears the error once a retried refresh succeeds',
    setUp: () => when(() => repository.watchCached()).thenAnswer((_) => const Stream.empty()),
    build: () => WorkOrdersBloc(repository: repository),
    act: (bloc) async {
      when(() => repository.refresh()).thenThrow(
        ApiException(message: 'Sem conexão com o servidor.'),
      );
      bloc.add(const WorkOrdersStarted());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      when(() => repository.refresh()).thenAnswer((_) async {});
      bloc.add(const WorkOrdersRefreshRequested());
    },
    wait: const Duration(milliseconds: 100),
    verify: (bloc) {
      expect(bloc.state.status, WorkOrdersStatus.success);
      expect(bloc.state.errorMessage, isNull);
    },
  );
}
