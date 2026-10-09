/// User minimal dari response login/backend (AuthController + GET /user).
class User {
  const User({
    required this.id,
    required this.name,
    required this.role,
    this.kota = '',
  });

  final int id;
  final String name;
  final String role;

  /// Kota domisili (dipakai opsi "Lokasi saya" filter marketplace).
  final String kota;

  factory User.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final src = data is Map<String, dynamic> ? data : json;
    return User(
      id: (src['id'] as num? ?? 0).toInt(),
      name: src['name'] as String? ?? '',
      role: src['role'] as String? ?? 'warga',
      kota: src['kota'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'role': role, 'kota': kota};
}
