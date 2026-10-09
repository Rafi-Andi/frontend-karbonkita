/// Produk master milik mitra (`GET/POST /merchant/products`).
///
/// Harga fix diinput mitra. Poin dihitung server via EcoRate (Rp40/poin):
/// `points_cost = ceil(rupiah / 40)`. Field `pointsPreview` hanya preview,
/// server tetap otoritatif saat funding voucher.
class MitraProduct {
  const MitraProduct({
    required this.id,
    required this.mitraProfileId,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.rupiahValue,
    required this.pointsPreview,
    required this.rupiahPerPoint,
    required this.isActive,
    this.storeName = '',
    this.fundable = true,
  });

  final int id;
  final int mitraProfileId;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final double rupiahValue;
  final int pointsPreview;
  final int rupiahPerPoint;
  final bool isActive;
  final String storeName;
  final bool fundable;

  factory MitraProduct.fromJson(Map<String, dynamic> json) {
    return MitraProduct(
      id: _toInt(json['id']),
      mitraProfileId: _toInt(json['mitra_profile_id']),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'kuliner',
      imageUrl: json['image_url'] as String? ?? '',
      rupiahValue: _toDouble(json['rupiah_value']),
      pointsPreview: _toInt(json['points_preview']),
      rupiahPerPoint: _toInt(json['rupiah_per_point'], fallback: 40),
      isActive: _toBool(json['is_active']),
      storeName: json['store_name'] as String? ?? '',
      fundable: json['fundable'] == null ? true : _toBool(json['fundable']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mitra_profile_id': mitraProfileId,
        'title': title,
        'description': description,
        'category': category,
        'image_url': imageUrl,
        'rupiah_value': rupiahValue,
        'points_preview': pointsPreview,
        'rupiah_per_point': rupiahPerPoint,
        'is_active': isActive,
      };
}

int _toInt(dynamic v, {int fallback = 0}) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

bool _toBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    return s == 'true' || s == '1';
  }
  return false;
}
