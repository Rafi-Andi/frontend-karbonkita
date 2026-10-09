import 'user.dart';

/// Hasil login: user + token Sanctum `1|...`.
class AuthResponse {
  const AuthResponse({required this.user, required this.token});

  final User user;
  final String token;

  factory AuthResponse.fromEnvelope(Map<String, dynamic> envelope) {
    final data = envelope['data'] as Map<String, dynamic>? ?? {};
    return AuthResponse(
      user: User.fromJson(data['user'] as Map<String, dynamic>? ?? {}),
      token: data['token'] as String? ?? '',
    );
  }
}
