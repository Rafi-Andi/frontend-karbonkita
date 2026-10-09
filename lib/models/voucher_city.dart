/// Satu kota yang punya voucher aktif (`GET /api/vouchers/cities`).
class VoucherCity {
  const VoucherCity({required this.city, required this.voucherCount});

  final String city;
  final int voucherCount;

  factory VoucherCity.fromJson(Map<String, dynamic> json) {
    final raw = json['city'];
    return VoucherCity(
      city: raw is String ? raw : '',
      voucherCount: (json['voucher_count'] as num? ?? 0).toInt(),
    );
  }
}
