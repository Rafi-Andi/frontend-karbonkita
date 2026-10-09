import 'mission.dart';

/// Data dashboard Beranda dari `GET /api/user/dashboard`.
/// Backend DashboardResource: user{...}, daily_missions[], leaderboard_preview[].
class DashboardData {
  const DashboardData({
    required this.user,
    required this.dailyMissions,
    required this.leaderboardPreview,
  });

  final DashboardUser user;
  final List<Mission> dailyMissions;
  final List<LeaderboardPreview> leaderboardPreview;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? {};
    final missionsJson = json['daily_missions'];
    final previewJson = json['leaderboard_preview'];

    return DashboardData(
      user: DashboardUser.fromJson(userJson),
      dailyMissions: missionsJson is List
          ? missionsJson
                .whereType<Map<String, dynamic>>()
                .map(Mission.fromJson)
                .toList()
          : const [],
      leaderboardPreview: previewJson is List
          ? previewJson
                .whereType<Map<String, dynamic>>()
                .map(LeaderboardPreview.fromJson)
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'daily_missions': dailyMissions.map((m) => m.toJson()).toList(),
    'leaderboard_preview': leaderboardPreview.map((e) => e.toJson()).toList(),
  };
}

/// Profil ringkas user di dashboard.
class DashboardUser {
  const DashboardUser({
    required this.name,
    required this.rt,
    required this.rw,
    required this.kelurahan,
    required this.level,
    required this.xp,
    required this.xpMax,
    required this.xpPercentage,
    required this.ecoPoints,
    required this.streakDays,
    required this.rankPercentage,
    required this.totalDistanceKm,
    required this.totalWasteKg,
    required this.totalCarbonSavedKg,
  });

  final String name;
  final String rt;
  final String rw;
  final String kelurahan;
  final String level;
  final int xp;
  final int xpMax;
  final double xpPercentage;
  final int ecoPoints;
  final int streakDays;
  final double rankPercentage;
  final double totalDistanceKm;
  final double totalWasteKg;
  final double totalCarbonSavedKg;

  factory DashboardUser.fromJson(Map<String, dynamic> json) {
    return DashboardUser(
      name: json['name'] as String? ?? '',
      rt: json['rt']?.toString() ?? '',
      rw: json['rw']?.toString() ?? '',
      kelurahan: json['kelurahan'] as String? ?? '',
      level: json['level'] as String? ?? '',
      xp: (json['xp'] as num? ?? 0).toInt(),
      xpMax: (json['xp_max'] as num? ?? 0).toInt(),
      xpPercentage: _toDouble(json['xp_percentage']),
      ecoPoints: (json['eco_points'] as num? ?? 0).toInt(),
      streakDays: (json['streak_days'] as num? ?? 0).toInt(),
      rankPercentage: _toDouble(json['rank_percentage']),
      totalDistanceKm: _toDouble(json['total_distance_km']),
      totalWasteKg: _toDouble(json['total_waste_kg']),
      totalCarbonSavedKg: _toDouble(json['total_carbon_saved_kg']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'rt': rt,
    'rw': rw,
    'kelurahan': kelurahan,
    'level': level,
    'xp': xp,
    'xp_max': xpMax,
    'xp_percentage': xpPercentage,
    'eco_points': ecoPoints,
    'streak_days': streakDays,
    'rank_percentage': rankPercentage,
    'total_distance_km': totalDistanceKm,
    'total_waste_kg': totalWasteKg,
    'total_carbon_saved_kg': totalCarbonSavedKg,
  };
}

/// Satu baris preview leaderboard (RT/RW) di dashboard.
/// Backend LeaderboardEntryResource: rank, user_id, name, rt, rw, xp, avatar, level.
class LeaderboardPreview {
  const LeaderboardPreview({
    required this.rank,
    required this.userId,
    required this.name,
    required this.rt,
    required this.rw,
    required this.xp,
    required this.avatar,
    required this.level,
  });

  final int rank;
  final int userId;
  final String name;
  final String rt;
  final String rw;
  final int xp;
  final String? avatar;
  final String level;

  factory LeaderboardPreview.fromJson(Map<String, dynamic> json) {
    return LeaderboardPreview(
      rank: _toInt(json['rank']),
      userId: _toInt(json['user_id']),
      name: json['name'] as String? ?? '',
      rt: json['rt']?.toString() ?? '',
      rw: json['rw']?.toString() ?? '',
      // Preview dashboard pakai key `xp`; leaderboard full pakai `total_xp`
      // (SUM MySQL kadang terkirim sebagai String).
      xp: _toInt(json['xp'] ?? json['total_xp']),
      avatar: json['avatar'] as String?,
      level: json['level'] as String? ?? 'Earth Newbie',
    );
  }

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'user_id': userId,
    'name': name,
    'rt': rt,
    'rw': rw,
    'xp': xp,
    'avatar': avatar,
    'level': level,
  };
}

/// Parsing int yang tahan num, String ("3450"), maupun null.
int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Parsing angka yang tahan num, String ("20000.00"), maupun null.
double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
