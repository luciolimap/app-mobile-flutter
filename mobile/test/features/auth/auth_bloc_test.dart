import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api/api_exception.dart';
import 'package:mobile/features/auth/bloc/auth_bloc.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/data/user.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  const user = User(
    id: 'u_001',
    name: 'Ana Técnica',
    email: 'tecnico@orbytis.com.br',
    role: 'field_technician',
  );

  setUp(() {
    repository = _MockAuthRepository();
  });

  group('AuthSessionRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits authenticated when a session already exists',
      setUp: () =>
          when(() => repository.restoreSession()).thenAnswer((_) async => user),
      build: () => AuthBloc(authRepository: repository),
      act: (bloc) => bloc.add(const AuthSessionRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.authenticated, user: user),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits unauthenticated when there is no stored session',
      setUp: () =>
          when(() => repository.restoreSession()).thenAnswer((_) async => null),
      build: () => AuthBloc(authRepository: repository),
      act: (bloc) => bloc.add(const AuthSessionRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.unauthenticated),
      ],
    );
  });

  group('AuthLoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits authenticated with the user on success',
      setUp: () => when(() => repository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => user),
      build: () => AuthBloc(authRepository: repository),
      act: (bloc) => bloc.add(const AuthLoginRequested(
        email: 'tecnico@orbytis.com.br',
        password: '123456',
      )),
      expect: () => [
        const AuthState(isSubmitting: true),
        const AuthState(status: AuthStatus.authenticated, user: user),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits an error message and stays unauthenticated on invalid credentials',
      setUp: () => when(() => repository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(ApiException(
        message: 'Credenciais inválidas',
        statusCode: 401,
      )),
      build: () => AuthBloc(authRepository: repository),
      act: (bloc) => bloc.add(const AuthLoginRequested(
        email: 'tecnico@orbytis.com.br',
        password: 'wrong',
      )),
      expect: () => [
        const AuthState(isSubmitting: true),
        const AuthState(errorMessage: 'Credenciais inválidas'),
      ],
    );
  });

  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'clears the session and emits unauthenticated',
      setUp: () => when(() => repository.logout()).thenAnswer((_) async {}),
      build: () => AuthBloc(authRepository: repository),
      seed: () => const AuthState(status: AuthStatus.authenticated, user: user),
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.unauthenticated),
      ],
      verify: (_) {
        verify(() => repository.logout()).called(1);
      },
    );
  });
}
