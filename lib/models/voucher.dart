import 'package:flutter/material.dart';

/// Voucher marketplace dari API response.
/// Backend VoucherResource: id, title, description, category, image_url, points_cost,
/// rupiah_value, stock, claimed_count, expired_at, is_active, mitra{name, store_name}
class Voucher {
  const Voucher({
    required this.id,
    required this.title,
    required this.description,
    this.category = 'kuliner',
    required this.imageUrl,
    required this.pointsCost,
    required this.rupiahValue,
    required this.stock,
    required this.claimedCount,
    required this.expiredAt,
    required this.isActive,
    required this.mitra,
  });

  final int id;
  final String title;
  final String description;

  /// Kategori voucher: kuliner|sembako|fashion|jasa|donasi|transportasi.
  final String category;
  final String imageUrl;
  final int pointsCost;
  final double rupiahValue;
  final int stock;
  final int claimedCount;
  final String expiredAt;
  final bool isActive;
  final MitraInfo mitra;

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'kuliner',
      imageUrl: json['image_url'] as String? ?? '',
      pointsCost: (json['points_cost'] as num? ?? 0).toInt(),
      // Backend cast decimal:2 -> terkirim sebagai String ("20000.00").
      rupiahValue: _toDouble(json['rupiah_value']),
      stock: (json['stock'] as num? ?? 0).toInt(),
      claimedCount: (json['claimed_count'] as num? ?? 0).toInt(),
      expiredAt: json['expired_at'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      mitra: MitraInfo.fromJson(json['mitra'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// Parsing angka yang tahan String ("20000.00"), num, maupun null.
  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'image_url': imageUrl,
    'points_cost': pointsCost,
    'rupiah_value': rupiahValue,
    'stock': stock,
    'claimed_count': claimedCount,
    'expired_at': expiredAt,
    'is_active': isActive,
    'mitra': mitra.toJson(),
  };
}

/// Info mitra pemilik voucher.
class MitraInfo {
  const MitraInfo({required this.name, required this.storeName});

  final String name;
  final String storeName;

  factory MitraInfo.fromJson(Map<String, dynamic> json) {
    return MitraInfo(
      name: json['name'] as String? ?? '',
      storeName: json['store_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'store_name': storeName};

  /// Nama toko untuk tampilan, fallback ke nama owner.
  String get displayName =>
      storeName.isNotEmpty ? storeName : (name.isNotEmpty ? name : '-');
}

/// Daftar kategori voucher + label Indonesia.
/// `value: null` = Semua (tanpa filter).
class VoucherCategory {
  const VoucherCategory._(this.value, this.label, this.icon);

  final String? value;
  final String label;
  final IconData icon;

  static const List<VoucherCategory> values = [
    VoucherCategory._(null, 'Semua', Icons.apps_rounded),
    VoucherCategory._('kuliner', 'Kuliner', Icons.restaurant),
    VoucherCategory._('sembako', 'Sembako', Icons.shopping_basket),
    VoucherCategory._('fashion', 'Fashion', Icons.checkroom),
    VoucherCategory._('jasa', 'Jasa', Icons.cleaning_services),
    VoucherCategory._('donasi', 'Donasi', Icons.volunteer_activism),
    VoucherCategory._('transportasi', 'Transportasi', Icons.pedal_bike),
  ];
}
