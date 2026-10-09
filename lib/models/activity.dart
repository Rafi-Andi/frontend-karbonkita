/// Satu baris aktivitas terbaru dari `GET /api/user/activities`.
/// Backend ActivityController: {id, kind, title, delta, created_at}.
/// kind: waste | mobility | quiz | voucher | other.
/// delta bertanda: +poin/+XP masuk, -poin keluar (tukar voucher).
class UserActivity {
  const UserActivity({
    required this.id,
    required this.kind,
    required this.title,
    required this.delta,
    required this.createdAt,
  });

  final String id;
  final String kind;
  final String title;
  final int delta;
  final DateTime? createdAt;

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    final rawDate = json['created_at'];
    return UserActivity(
      id: json['id']?.toString() ?? '',
      kind: json['kind'] as String? ?? 'other',
      title: json['title'] as String? ?? '',
      delta: _toInt(json['delta']),
      createdAt: rawDate is String ? DateTime.tryParse(rawDate) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'title': title,
    'delta': delta,
    'created_at': createdAt?.toIso8601String(),
  };
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
