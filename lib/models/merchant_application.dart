/// Pengajuan mitra dari `GET /api/admin/merchants` (paginated).
///
/// Backend AdminController@index: data = paginator Laravel
/// {current_page, data[], per_page, total}, plus `summary`
/// {pending, verified, rejected} di level envelope.
class MerchantApplicationPage {
  const MerchantApplicationPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.summary,
  });

  final List<MerchantApplicationItem> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final MerchantApplicationSummary summary;

  bool get hasMore => currentPage < lastPage;

  factory MerchantApplicationPage.fromEnvelope(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    final rawItems = data is Map<String, dynamic> ? data['data'] : null;
    final summaryJson = envelope['summary'];
    return MerchantApplicationPage(
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(MerchantApplicationItem.fromJson)
                .toList()
          : const [],
      currentPage: _toInt(data is Map ? data['current_page'] : null),
      lastPage: _toInt(data is Map ? data['last_page'] : null),
      total: _toInt(data is Map ? data['total'] : null),
      summary: MerchantApplicationSummary.fromJson(
        summaryJson is Map<String, dynamic> ? summaryJson : const {},
      ),
    );
  }
}

class MerchantApplicationSummary {
  const MerchantApplicationSummary({
    required this.pending,
    required this.verified,
    required this.rejected,
  });

  final int pending;
  final int verified;
  final int rejected;

  factory MerchantApplicationSummary.fromJson(Map<String, dynamic> json) {
    return MerchantApplicationSummary(
      pending: _toInt(json['pending']),
      verified: _toInt(json['verified']),
      rejected: _toInt(json['rejected']),
    );
  }
}

/// Satu baris antrean (field index ringan: user + status).
class MerchantApplicationItem {
  const MerchantApplicationItem({
    required this.id,
    required this.storeName,
    required this.businessType,
    required this.verificationStatus,
    required this.isActive,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.registeredAt,
  });

  final int id;
  final String storeName;
  final String businessType;
  final String verificationStatus;
  final bool isActive;
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;
  final String registeredAt;

  factory MerchantApplicationItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    final rawActive = json['is_active'];
    return MerchantApplicationItem(
      id: _toInt(json['id']),
      storeName: json['nama_usaha'] as String? ?? '',
      businessType: json['jenis_usaha'] as String? ?? '',
      verificationStatus: json['status_verifikasi'] as String? ?? 'pending',
      isActive: rawActive is bool
          ? rawActive
          : (rawActive is num ? rawActive != 0 : false),
      ownerName: user['name'] as String? ?? '',
      ownerEmail: user['email'] as String? ?? '',
      ownerPhone: user['phone'] as String? ?? '',
      registeredAt: json['created_at'] as String? ?? '',
    );
  }
}

/// Detail 1 pengajuan dari `GET /api/admin/merchants/{id}`.
class MerchantApplicationDetail {
  const MerchantApplicationDetail({
    required this.id,
    required this.storeName,
    required this.businessType,
    required this.verificationStatus,
    required this.isActive,
    required this.verificationNote,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.ownerDomisili,
    required this.businessAddress,
    required this.storePhotos,
    required this.ktpNumber,
    required this.ktpPhoto,
    required this.nibNumber,
    required this.nibPhoto,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountHolder,
    required this.bankValidationStatus,
    required this.bankValidatedAt,
    required this.bankValidationNote,
    required this.balance,
  });

  final int id;
  final String storeName;
  final String businessType;
  final String verificationStatus;
  final bool isActive;
  final String verificationNote;
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final String ownerDomisili;
  final String businessAddress;
  final List<String?> storePhotos;
  final String ktpNumber;
  final String ktpPhoto;
  final String nibNumber;
  final String nibPhoto;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountHolder;
  final String bankValidationStatus;
  final String bankValidatedAt;
  final String bankValidationNote;
  final double balance;

  factory MerchantApplicationDetail.fromJson(Map<String, dynamic> json) {
    final store = json['store'] as Map<String, dynamic>? ?? const {};
    final owner = json['owner'] as Map<String, dynamic>? ?? const {};
    final lokasi = json['lokasi_usaha'] as Map<String, dynamic>? ?? const {};
    final foto = json['foto_toko'] as Map<String, dynamic>? ?? const {};
    final dokumen = json['dokumen'] as Map<String, dynamic>? ?? const {};
    final rekening = json['rekening'] as Map<String, dynamic>? ?? const {};
    final rawActive = json['is_active'];
    return MerchantApplicationDetail(
      id: _toInt(json['id']),
      storeName: store['nama_usaha'] as String? ?? '',
      businessType: store['jenis_usaha'] as String? ?? '',
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      isActive: rawActive is bool
          ? rawActive
          : (rawActive is num ? rawActive != 0 : false),
      verificationNote: json['verification_note'] as String? ?? '',
      ownerName: owner['name'] as String? ?? '',
      ownerPhone: owner['phone'] as String? ?? '',
      ownerEmail: owner['email'] as String? ?? '',
      ownerDomisili: owner['domisili'] as String? ?? '',
      businessAddress: _joinAddress(lokasi),
      storePhotos: [
        foto['foto_1'] as String?,
        foto['foto_2'] as String?,
        foto['foto_3'] as String?,
      ],
      ktpNumber: dokumen['nomor_ktp'] as String? ?? '',
      ktpPhoto: dokumen['foto_ktp'] as String? ?? '',
      nibNumber: dokumen['nomor_nib'] as String? ?? '',
      nibPhoto: dokumen['foto_nib'] as String? ?? '',
      bankName: rekening['bank'] as String? ?? '',
      bankAccountNumber: rekening['nomor_rekening'] as String? ?? '',
      bankAccountHolder: rekening['atas_nama'] as String? ?? '',
      bankValidationStatus: rekening['bank_validation_status'] as String? ?? '',
      bankValidatedAt: rekening['bank_validated_at'] as String? ?? '',
      bankValidationNote: rekening['bank_validation_note'] as String? ?? '',
      balance: _toDouble(json['balance']),
    );
  }

  static String _joinAddress(Map<String, dynamic> lokasi) {
    final parts = [
      lokasi['alamat'],
      lokasi['kelurahan'],
      lokasi['kecamatan'],
      lokasi['kota'],
      lokasi['provinsi'],
      lokasi['kode_pos'],
    ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
    return parts.join(', ');
  }
}

/// Hasil `POST /api/admin/merchants/{id}/verify`.
class MerchantVerifyResult {
  const MerchantVerifyResult({
    required this.id,
    required this.storeName,
    required this.verificationStatus,
    required this.isActive,
  });

  final int id;
  final String storeName;
  final String verificationStatus;
  final bool isActive;

  bool get approved => verificationStatus == 'verified';

  factory MerchantVerifyResult.fromJson(Map<String, dynamic> json) {
    final rawActive = json['is_active'];
    return MerchantVerifyResult(
      id: _toInt(json['id']),
      storeName: json['store_name'] as String? ?? '',
      verificationStatus: json['verification_status'] as String? ?? '',
      isActive: rawActive is bool
          ? rawActive
          : (rawActive is num ? rawActive != 0 : false),
    );
  }
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
