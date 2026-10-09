import '../../models/user.dart';

/// Status sesi login.
enum AuthStatus { initial, checking, loading, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.message,
    this.fieldErrors = const {},
  });

  final AuthStatus status;
  final User? user;
  final String? message;
  final Map<String, List<String>> fieldErrors;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? message,
    Map<String, List<String>>? fieldErrors,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      message: message,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}
