import 'user.dart';

/// Hasil `POST /api/auth/register-mitra` (201).
///
/// Backend selalu mengembalikan token (auto-login) + profil pending;
/// akun baru login tapi `canRedeem=false` sampai admin approve.
class MitraRegisterResult {
  const MitraRegisterResult({
    required this.user,
    required this.token,
    required this.mitraId,
    required this.storeName,
    required this.businessType,
    required this.verificationStatus,
    required this.isActive,
    required this.bankValidationStatus,
    required this.bankValidationNote,
    required this.photoUrls,
  });

  final User user;
  final String token;
  final int mitraId;
  final String storeName;
  final String businessType;
  final String verificationStatus;
  final bool isActive;
  final String bankValidationStatus;
  final String bankValidationNote;
  final Map<String, String?> photoUrls;

  bool get isPending => verificationStatus == 'pending';

  factory MitraRegisterResult.fromJson(Map<String, dynamic> json) {
    final mitra = json['mitra'] as Map<String, dynamic>? ?? const {};
    final photos = mitra['foto_urls'];
    final photoMap = <String, String?>{};
    if (photos is Map) {
      photos.forEach((k, v) => photoMap[k.toString()] = v as String?);
    }
    final rawActive = mitra['is_active'];
    return MitraRegisterResult(
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      token: json['token'] as String? ?? '',
      mitraId: _toInt(mitra['id']),
      storeName: mitra['nama_usaha'] as String? ?? '',
      businessType: mitra['jenis_usaha'] as String? ?? '',
      verificationStatus: mitra['status_verifikasi'] as String? ?? 'pending',
      isActive: rawActive is bool
          ? rawActive
          : (rawActive is num ? rawActive != 0 : false),
      bankValidationStatus: mitra['bank_validation_status'] as String? ?? '',
      bankValidationNote: mitra['bank_validation_note'] as String? ?? '',
      photoUrls: photoMap,
    );
  }
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
