/// Voucher milik user dari `GET /api/user/my-vouchers`.
/// Backend VoucherClaimResource: claim_id, qr_token, status,
/// claimed_at, used_at, voucher{id,title,description,image_url,
/// rupiah_value,expired_at}, mitra{store_name,name}.
class MyVoucherClaim {
  const MyVoucherClaim({
    required this.claimId,
    required this.qrToken,
    required this.status,
    required this.claimedAt,
    required this.usedAt,
    required this.voucherId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.rupiahValue,
    required this.expiredAt,
    required this.storeName,
    required this.ownerName,
  });

  final int claimId;
  final String qrToken;
  final String status; // claimed | used | expired
  final String claimedAt;
  final String usedAt;
  final int voucherId;
  final String title;
  final String description;
  final String imageUrl;
  final double rupiahValue;
  final String expiredAt;
  final String storeName;
  final String ownerName;

  bool get isActive => status == 'claimed';
  bool get isUsed => status == 'used';

  factory MyVoucherClaim.fromJson(Map<String, dynamic> json) {
    final voucher = json['voucher'] as Map<String, dynamic>? ?? const {};
    final mitra = json['mitra'] as Map<String, dynamic>? ?? const {};
    return MyVoucherClaim(
      claimId: _toInt(json['claim_id']),
      qrToken: json['qr_token'] as String? ?? '',
      status: json['status'] as String? ?? 'claimed',
      claimedAt: json['claimed_at'] as String? ?? '',
      usedAt: json['used_at'] as String? ?? '',
      voucherId: _toInt(voucher['id']),
      title: voucher['title'] as String? ?? '',
      description: voucher['description'] as String? ?? '',
      imageUrl: voucher['image_url'] as String? ?? '',
      rupiahValue: _toDouble(voucher['rupiah_value']),
      expiredAt: voucher['expired_at'] as String? ?? '',
      storeName: mitra['store_name'] as String? ?? '',
      ownerName: mitra['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'claim_id': claimId,
    'qr_token': qrToken,
    'status': status,
    'claimed_at': claimedAt,
    'used_at': usedAt,
    'voucher': {
      'id': voucherId,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'rupiah_value': rupiahValue,
      'expired_at': expiredAt,
    },
    'mitra': {'store_name': storeName, 'name': ownerName},
  };
}

/// Inventaris dompet: `data: {active[], used[], expired[]}`.
class MyVoucherInventory {
  const MyVoucherInventory({
    required this.active,
    required this.used,
    required this.expired,
  });

  const MyVoucherInventory.empty()
    : active = const [],
      used = const [],
      expired = const [];

  final List<MyVoucherClaim> active;
  final List<MyVoucherClaim> used;
  final List<MyVoucherClaim> expired;

  factory MyVoucherInventory.fromJson(Map<String, dynamic> json) {
    List<MyVoucherClaim> parse(dynamic raw) {
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(MyVoucherClaim.fromJson)
            .toList();
      }
      return const [];
    }

    return MyVoucherInventory(
      active: parse(json['active']),
      used: parse(json['used']),
      expired: parse(json['expired']),
    );
  }

  Map<String, dynamic> toJson() => {
    'active': active.map((e) => e.toJson()).toList(),
    'used': used.map((e) => e.toJson()).toList(),
    'expired': expired.map((e) => e.toJson()).toList(),
  };
}

/// Hasil `POST /api/vouchers/claim` (201).
/// Backend: claim_id, qr_token, voucher_title, points_cost, remaining_points.
class ClaimResult {
  const ClaimResult({
    required this.claimId,
    required this.qrToken,
    required this.voucherTitle,
    required this.pointsCost,
    required this.remainingPoints,
  });

  final int claimId;
  final String qrToken;
  final String voucherTitle;
  final int pointsCost;
  final int remainingPoints;

  factory ClaimResult.fromJson(Map<String, dynamic> json) {
    return ClaimResult(
      claimId: _toInt(json['claim_id']),
      qrToken: json['qr_token'] as String? ?? '',
      voucherTitle: json['voucher_title'] as String? ?? '',
      pointsCost: _toInt(json['points_cost']),
      remainingPoints: _toInt(json['remaining_points']),
    );
  }

  Map<String, dynamic> toJson() => {
    'claim_id': claimId,
    'qr_token': qrToken,
    'voucher_title': voucherTitle,
    'points_cost': pointsCost,
    'remaining_points': remainingPoints,
  };
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Parsing angka yang tahan String ("20000.00"), num, maupun null.
double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
