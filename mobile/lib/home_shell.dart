import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/database/app_database.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/history/bloc/history_bloc.dart';
import 'features/history/ui/history_page.dart';
import 'features/sync/sync_service.dart';
import 'features/work_orders/bloc/work_orders_bloc.dart';
import 'features/work_orders/data/work_orders_repository.dart';
import 'features/work_orders/ui/work_orders_page.dart';

/// Post-login shell: bottom navigation between the work order list and
/// the local inspection history/sync status.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = ['Ordens de Serviço', 'Histórico de Inspeções'];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => WorkOrdersBloc(
            repository: context.read<WorkOrdersRepository>(),
          )..add(const WorkOrdersStarted()),
        ),
        BlocProvider(
          create: (context) => HistoryBloc(
            database: context.read<AppDatabase>(),
            syncService: context.read<SyncService>(),
          )..add(const HistoryStarted()),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_index]),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sair',
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            ),
          ],
        ),
        body: IndexedStack(
          index: _index,
          children: const [WorkOrdersPage(), HistoryPage()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              label: 'Ordens',
            ),
            NavigationDestination(
              icon: Icon(Icons.history),
              label: 'Histórico',
            ),
          ],
        ),
      ),
    );
  }
}
