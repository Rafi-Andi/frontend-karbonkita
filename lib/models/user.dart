/// User minimal dari response login backend (AuthController).
class User {
  const User({required this.id, required this.name, required this.role});

  final int id;
  final String name;
  final String role;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'warga',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'role': role};
}
