import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/bloc/auth/auth_bloc.dart';
import 'package:karbon_kita_app/bloc/auth/auth_event.dart';
import 'package:karbon_kita_app/bloc/auth/auth_state.dart';
import 'package:karbon_kita_app/core/network/auth_exception.dart';
import 'package:karbon_kita_app/core/network/dio_client.dart';
import 'package:karbon_kita_app/core/storage/token_storage.dart';
import 'package:karbon_kita_app/data/datasources/auth_remote_datasource.dart';
import 'package:karbon_kita_app/data/repositories/auth_repository.dart';
import 'package:karbon_kita_app/models/auth_response.dart';
import 'package:karbon_kita_app/models/user.dart';

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({this.loginResult, this.loginError})
    : super(AuthRemoteDatasource(DioClient()), TokenStorage());

  final AuthResponse? loginResult;
  final Exception? loginError;

  @override
  Future<AuthResponse> login({
    required String phoneOrEmail,
    required String password,
  }) async {
    if (loginError != null) throw loginError!;
    return loginResult!;
  }

  @override
  Future<User?> checkSession() async => null;

  @override
  Future<void> logout() async {}
}

void main() {
  group('AuthResponse parsing (kontrak backend)', () {
    test('fromEnvelope baca user + token', () {
      final res = AuthResponse.fromEnvelope({
        'success': true,
        'message': 'Login successful.',
        'data': {
          'user': {'id': 1, 'name': 'Rafi', 'role': 'warga'},
          'token': '1|abc',
        },
      });
      expect(res.user.id, 1);
      expect(res.user.name, 'Rafi');
      expect(res.user.role, 'warga');
      expect(res.token, '1|abc');
    });
  });

  group('AuthBloc login', () {
    test('field kosong -> unauthenticated + pesan', () async {
      final bloc = AuthBloc(FakeAuthRepository());
      bloc.add(const LoginSubmitted(phoneOrEmail: '', password: ''));
      await expectLater(
        bloc.stream,
        emits(
          predicate<AuthState>(
            (s) => s.status == AuthStatus.unauthenticated && s.message != null,
          ),
        ),
      );
      await bloc.close();
    });

    test('login sukses -> authenticated', () async {
      final bloc = AuthBloc(
        FakeAuthRepository(
          loginResult: const AuthResponse(
            user: User(id: 7, name: 'Warga', role: 'warga'),
            token: '1|tok',
          ),
        ),
      );
      bloc.add(
        const LoginSubmitted(
          phoneOrEmail: 'user@email.com',
          password: 'secret123',
        ),
      );
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) =>
                s.status == AuthStatus.authenticated && s.user?.role == 'warga',
          ),
        ),
      );
      await bloc.close();
    });

    test('401 backend -> unauthenticated + pesan ramah', () async {
      final bloc = AuthBloc(
        FakeAuthRepository(
          loginError: const AuthException(
            'No HP/Email atau kata sandi salah.',
            statusCode: 401,
          ),
        ),
      );
      bloc.add(
        const LoginSubmitted(
          phoneOrEmail: 'salah@email.com',
          password: 'salah',
        ),
      );
      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) =>
                s.status == AuthStatus.unauthenticated &&
                s.message == 'No HP/Email atau kata sandi salah.',
          ),
        ),
      );
      await bloc.close();
    });
  });
}
