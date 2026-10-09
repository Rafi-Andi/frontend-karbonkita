/// Satuan wilayah administrasi Indonesia (provinsi → desa/kelurahan).
///
/// Sumber utama: `https://wilayah.id` (format `{"code","name"}` di dalam
/// envelope `{"data": [...]}`). Parser dibuat defensif agar juga menerima
/// format list polos / field `id` (mis. API emsifa) sebagai fallback.
class Region {
  const Region({required this.code, required this.name});

  final String code;
  final String name;

  factory Region.fromJson(Map<String, dynamic> json) {
    final code = (json['code'] ?? json['id'] ?? '').toString().trim();
    final name = (json['name'] ?? '').toString().trim();
    return Region(code: code, name: name);
  }

  /// Terima envelope `{"data": [...]}` maupun list polos `[...]`.
  /// Entri tanpa code/nama dibuang agar dropdown tidak menampilkan baris kosong.
  static List<Region> listOf(dynamic data) {
    final raw = data is Map<String, dynamic> ? data['data'] : data;
    if (raw is! List) return const [];
    final out = <Region>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final region = Region.fromJson(
        item.map((k, v) => MapEntry(k.toString(), v)),
      );
      if (region.code.isNotEmpty && region.name.isNotEmpty) out.add(region);
    }
    return out;
  }

  Map<String, dynamic> toJson() => {'code': code, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Region && other.code == code && other.name == name);

  @override
  int get hashCode => Object.hash(code, name);

  @override
  String toString() => 'Region($code, $name)';
}
