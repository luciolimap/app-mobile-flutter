import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/api/api_client.dart';
import 'core/database/app_database.dart';
import 'core/services/connectivity_service.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/ui/login_page.dart';
import 'features/inspection/data/form_schema_repository.dart';
import 'features/inspection/data/inspection_repository.dart';
import 'features/sync/sync_service.dart';
import 'features/work_orders/data/work_orders_repository.dart';
import 'home_shell.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => TokenStorage()),
        RepositoryProvider(
          create: (context) =>
              ApiClient(tokenStorage: context.read<TokenStorage>()),
        ),
        RepositoryProvider(
          create: (context) =>
              FormSchemaRepository(apiClient: context.read<ApiClient>()),
        ),
        RepositoryProvider(create: (_) => AppDatabase()),
        RepositoryProvider(create: (_) => ConnectivityService()),
        RepositoryProvider(
          create: (context) => AuthRepository(
            apiClient: context.read<ApiClient>(),
            tokenStorage: context.read<TokenStorage>(),
          ),
        ),
        RepositoryProvider(
          create: (context) => WorkOrdersRepository(
            apiClient: context.read<ApiClient>(),
            database: context.read<AppDatabase>(),
          ),
        ),
        RepositoryProvider(
          create: (context) =>
              InspectionRepository(database: context.read<AppDatabase>()),
        ),
        RepositoryProvider(
          create: (context) => SyncService(
            database: context.read<AppDatabase>(),
            apiClient: context.read<ApiClient>(),
            connectivityService: context.read<ConnectivityService>(),
          )..start(),
        ),
      ],
      child: BlocProvider(
        create: (context) => AuthBloc(
          authRepository: context.read<AuthRepository>(),
        )..add(const AuthSessionRequested()),
        child: MaterialApp(
          title: 'Inspeção de Campo — Orbytis',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.light,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
            useMaterial3: true,
            // Slightly higher-contrast surfaces than the Material 3 default
            // dark palette, for readability in direct sunlight outdoors.
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          themeMode: ThemeMode.system,
          home: const AuthGate(),
        ),
      ),
    );
  }
}

/// Blocks the authenticated area of the app until a valid token exists,
/// per the "bloquear rotas autenticadas sem token" requirement.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.unknown:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.unauthenticated:
            return const LoginPage();
          case AuthStatus.authenticated:
            return const HomeShell();
        }
      },
    );
  }
}
