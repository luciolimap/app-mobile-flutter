import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/work_orders/bloc/work_orders_bloc.dart';
import 'package:mobile/features/work_orders/data/work_order.dart';
import 'package:mobile/features/work_orders/ui/work_orders_page.dart';

class _MockWorkOrdersBloc extends MockBloc<WorkOrdersEvent, WorkOrdersState>
    implements WorkOrdersBloc {}

WorkOrder _buildWorkOrder(String id, {String title = 'Inspeção de poste'}) =>
    WorkOrder(
      id: id,
      code: 'OS-$id',
      title: title,
      description: 'Verificar estado do poste.',
      address: 'Rua das Acácias, 120',
      priority: 'high',
      status: 'open',
      latitude: -7.1195,
      longitude: -34.8450,
      scheduledAt: '2026-07-28T13:00:00.000Z',
      updatedAt: '2026-07-26T12:00:00.000Z',
    );

Future<void> _pump(WidgetTester tester, WorkOrdersBloc bloc) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: BlocProvider<WorkOrdersBloc>.value(
        value: bloc,
        child: const WorkOrdersPage(),
      ),
    ),
  ));
}

void main() {
  late _MockWorkOrdersBloc bloc;

  setUp(() {
    bloc = _MockWorkOrdersBloc();
  });

  testWidgets('shows a spinner while loading with no cached items', (tester) async {
    whenListen(
      bloc,
      const Stream<WorkOrdersState>.empty(),
      initialState: const WorkOrdersState(status: WorkOrdersStatus.loading),
    );

    await _pump(tester, bloc);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the error view with a retry button on failure', (tester) async {
    whenListen(
      bloc,
      const Stream<WorkOrdersState>.empty(),
      initialState: const WorkOrdersState(
        status: WorkOrdersStatus.failure,
        errorMessage: 'Sem conexão com o servidor.',
      ),
    );

    await _pump(tester, bloc);

    expect(find.text('Sem conexão com o servidor.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Tentar novamente'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no work orders', (tester) async {
    whenListen(
      bloc,
      const Stream<WorkOrdersState>.empty(),
      initialState: const WorkOrdersState(status: WorkOrdersStatus.success),
    );

    await _pump(tester, bloc);

    expect(find.text('Nenhuma ordem de serviço encontrada.'), findsOneWidget);
  });

  testWidgets('renders each work order with pt-BR priority/status labels', (tester) async {
    whenListen(
      bloc,
      const Stream<WorkOrdersState>.empty(),
      initialState: WorkOrdersState(
        status: WorkOrdersStatus.success,
        items: [
          _buildWorkOrder('wo_1', title: 'Inspeção de poste'),
          _buildWorkOrder('wo_2', title: 'Vistoria de caixa de passagem'),
        ],
      ),
    );

    await _pump(tester, bloc);

    expect(find.text('Inspeção de poste'), findsOneWidget);
    expect(find.text('Vistoria de caixa de passagem'), findsOneWidget);
    expect(find.text('ALTA'), findsNWidgets(2));
    expect(find.text('Aberta'), findsNWidgets(2));
  });
}
