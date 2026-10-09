/// Hasil verifikasi sampah dari `POST /api/missions/verify-waste`.
///
/// Backend mengembalikan envelope `{success, message, data}` dengan `data`:
/// 201 verified → user_mission_id, status, is_valid, confidence,
///   waste_category, xp_earned, points_earned, new_xp, new_level,
///   new_eco_points, streak_days
/// 200 rejected AI → field sama + rejection_reason, xp/points 0
class VerifyWasteResult {
  const VerifyWasteResult({
    required this.userMissionId,
    required this.status,
    required this.isValid,
    required this.confidence,
    required this.wasteCategory,
    required this.xpEarned,
    required this.pointsEarned,
    this.rejectionReason,
    this.newXp,
    this.newLevel,
    this.newEcoPoints,
    this.streakDays,
  });

  final int? userMissionId;
  final String status; // 'verified' | 'rejected' | 'pending'
  final bool isValid;
  final double confidence;
  final String wasteCategory;
  final int xpEarned;
  final int pointsEarned;
  final String? rejectionReason;
  final int? newXp;
  final String? newLevel;
  final int? newEcoPoints;
  final int? streakDays;

  bool get verified => status == 'verified';

  factory VerifyWasteResult.fromJson(Map<String, dynamic> json) {
    return VerifyWasteResult(
      userMissionId: (json['user_mission_id'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'pending',
      isValid: json['is_valid'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      wasteCategory: json['waste_category'] as String? ?? 'unknown',
      xpEarned: (json['xp_earned'] as num? ?? 0).toInt(),
      pointsEarned: (json['points_earned'] as num? ?? 0).toInt(),
      rejectionReason: json['rejection_reason'] as String?,
      newXp: (json['new_xp'] as num?)?.toInt(),
      newLevel: json['new_level'] as String?,
      newEcoPoints: (json['new_eco_points'] as num?)?.toInt(),
      streakDays: (json['streak_days'] as num?)?.toInt(),
    );
  }

  /// Label Indonesia untuk kategori sampah backend.
  String get categoryLabel {
    switch (wasteCategory) {
      case 'plastic':
        return 'Plastik Terpilah';
      case 'paper':
        return 'Kertas Terpilah';
      case 'organic':
        return 'Organik Terpilah';
      case 'electronic':
        return 'Elektronik Terpilah';
      case 'mixed':
        return 'Campuran Terpilah';
      case 'residue':
        return 'Residu Terpilah';
      default:
        return 'Sampah Terpilah';
    }
  }
}
