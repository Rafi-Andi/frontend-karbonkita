/// Model reward (voucher marketplace) untuk layar Kelola Reward admin.
///
/// Backend `AdminVoucherResource`: id, mitra_product_id, title, description,
/// category, image_url, points_cost, rupiah_value, stock, claimed_count,
/// claims_count (hitung nyata dari tabel claims), used_claims_count,
/// expired_at (Y-m-d), is_active, created_at, mitra{id,name,store_name,city}.
class AdminReward {
  const AdminReward({
    required this.id,
    required this.title,
    required this.description,
    this.category = 'kuliner',
    this.imageUrl = '',
    required this.pointsCost,
    required this.rupiahValue,
    required this.stock,
    required this.claimedCount,
    required this.claimsCount,
    required this.usedClaimsCount,
    required this.expiredAt,
    required this.isActive,
    required this.mitra,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final int pointsCost;
  final double rupiahValue;
  final int stock;

  /// Kolom vouchers.claimed_count — bisa drift, hanya cadangan tampilan.
  final int claimedCount;

  /// Hitungan nyata dari tabel voucher_claims (backend withCount).
  final int claimsCount;
  final int usedClaimsCount;

  /// Tenggat format Y-m-d.
  final String expiredAt;
  final bool isActive;
  final AdminRewardMitra mitra;

  factory AdminReward.fromJson(Map<String, dynamic> json) {
    return AdminReward(
      id: _toInt(json['id']),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'kuliner',
      imageUrl: json['image_url'] as String? ?? '',
      pointsCost: _toInt(json['points_cost']),
      rupiahValue: _toDouble(json['rupiah_value']),
      stock: _toInt(json['stock']),
      claimedCount: _toInt(json['claimed_count']),
      claimsCount: json['claims_count'] == null
          ? _toInt(json['claimed_count'])
          : _toInt(json['claims_count']),
      usedClaimsCount: _toInt(json['used_claims_count']),
      expiredAt: json['expired_at'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      mitra: AdminRewardMitra.fromJson(
        json['mitra'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Parsing angka yang tahan String ("20000.00"), num, maupun null.
  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  /// Tenggat sudah lewat (dibanding tanggal hari ini).
  bool get isExpired {
    final date = DateTime.tryParse(expiredAt);
    if (date == null) return false;
    final now = DateTime.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Stok habis — tidak bisa ditukar sampai stok ditambah admin.
  bool get isSoldOut => stock <= 0;

  /// Tenggat siap tampil: "30 Nov 2026".
  String get expiredAtLabel => _formatDay(expiredAt);
}

/// Info mitra pemilik reward.
class AdminRewardMitra {
  const AdminRewardMitra({
    this.id = 0,
    this.name = '',
    this.storeName = '',
    this.city = '',
  });

  final int id;
  final String name;
  final String storeName;
  final String city;

  factory AdminRewardMitra.fromJson(Map<String, dynamic> json) {
    return AdminRewardMitra(
      id: AdminReward._toInt(json['id']),
      name: json['name'] as String? ?? '',
      storeName: json['store_name'] as String? ?? '',
      city: json['city'] as String? ?? '',
    );
  }

  /// Nama toko untuk tampilan, fallback ke nama owner.
  String get displayName =>
      storeName.isNotEmpty ? storeName : (name.isNotEmpty ? name : '-');
}

/// Satu baris penukar reward (backend AdminVoucherClaimResource).
class AdminRewardClaim {
  const AdminRewardClaim({
    required this.claimId,
    required this.qrToken,
    required this.status,
    required this.claimedAt,
    this.usedAt,
    required this.user,
  });

  final int claimId;
  final String qrToken;

  /// claimed | used | expired.
  final String status;
  final String claimedAt;
  final String? usedAt;
  final AdminRewardClaimant user;

  factory AdminRewardClaim.fromJson(Map<String, dynamic> json) {
    return AdminRewardClaim(
      claimId: AdminReward._toInt(json['claim_id']),
      qrToken: json['qr_token'] as String? ?? '',
      status: json['status'] as String? ?? 'claimed',
      claimedAt: json['claimed_at'] as String? ?? '',
      usedAt: json['used_at'] as String?,
      user: AdminRewardClaimant.fromJson(
        json['user'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  String get statusLabel => switch (status) {
    'used' => 'Sudah dipakai',
    'expired' => 'Kedaluwarsa',
    _ => 'Belum dipakai',
  };

  String get claimedAtLabel => _formatDateTime(claimedAt);
  String? get usedAtLabel =>
      usedAt == null || usedAt!.isEmpty ? null : _formatDateTime(usedAt!);
}

/// Warga penukar reward (nama, kontak, wilayah).
class AdminRewardClaimant {
  const AdminRewardClaimant({
    this.id = 0,
    this.name = '',
    this.phone = '',
    this.rt = '',
    this.rw = '',
  });

  final int id;
  final String name;
  final String phone;
  final String rt;
  final String rw;

  factory AdminRewardClaimant.fromJson(Map<String, dynamic> json) {
    return AdminRewardClaimant(
      id: AdminReward._toInt(json['id']),
      name: json['name'] as String? ?? '',
      phone: (json['phone'] ?? '').toString(),
      rt: (json['rt'] ?? '').toString(),
      rw: (json['rw'] ?? '').toString(),
    );
  }

  /// "RT 03 / RW 05" atau '-' bila kosong.
  String get regionLabel {
    final parts = <String>[];
    if (rt.isNotEmpty) parts.add('RT $rt');
    if (rw.isNotEmpty) parts.add('RW $rw');
    return parts.isEmpty ? '-' : parts.join(' / ');
  }
}

/// Hasil paginasi daftar penukar (meta dari backend).
class AdminRewardClaimsPage {
  const AdminRewardClaimsPage({
    required this.items,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
  });

  final List<AdminRewardClaim> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}

const _monthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// "2026-11-30" -> "30 Nov 2026" (fallback nilai asli / '-').
String _formatDay(String raw) {
  final date = DateTime.tryParse(raw);
  if (date == null) return raw.isEmpty ? '-' : raw;
  return '${date.day} ${_monthsShort[date.month - 1]} ${date.year}';
}

/// "2026-10-18T14:30:00" -> "18 Okt 2026 • 14:30".
String _formatDateTime(String raw) {
  final date = DateTime.tryParse(raw);
  if (date == null) return raw.isEmpty ? '-' : raw;
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${_formatDay(raw)} • $hour:$minute';
}
