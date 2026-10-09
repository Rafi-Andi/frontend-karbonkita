/// Kontrak `GET /api/user/levels`: 3 tier lencana level untuk Profil.
/// Backend LevelController: data{xp, level, current_tier, tiers[]}.
class LevelTier {
  const LevelTier({
    required this.key,
    required this.label,
    required this.minXp,
    required this.maxXp,
    required this.isUnlocked,
    required this.isCurrent,
    required this.asset,
  });

  final String key;
  final String label;
  final int minXp;
  final int? maxXp;
  final bool isUnlocked;
  final bool isCurrent;
  final String asset;

  factory LevelTier.fromJson(Map<String, dynamic> json) {
    final maxRaw = json['max_xp'];
    return LevelTier(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      minXp: _toInt(json['min_xp']),
      maxXp: maxRaw == null ? null : _toInt(maxRaw),
      isUnlocked: json['is_unlocked'] as bool? ?? false,
      isCurrent: json['is_current'] as bool? ?? false,
      asset: json['asset'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'min_xp': minXp,
    'max_xp': maxXp,
    'is_unlocked': isUnlocked,
    'is_current': isCurrent,
    'asset': asset,
  };
}

class LevelTiersData {
  const LevelTiersData({
    required this.xp,
    required this.level,
    required this.currentTier,
    required this.tiers,
  });

  final int xp;
  final String level;
  final String currentTier;
  final List<LevelTier> tiers;

  factory LevelTiersData.fromJson(Map<String, dynamic> json) {
    final tiersJson = json['tiers'];
    return LevelTiersData(
      xp: _toInt(json['xp']),
      level: json['level'] as String? ?? '',
      currentTier: json['current_tier'] as String? ?? '',
      tiers: tiersJson is List
          ? tiersJson
                .whereType<Map<String, dynamic>>()
                .map(LevelTier.fromJson)
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'xp': xp,
    'level': level,
    'current_tier': currentTier,
    'tiers': tiers.map((t) => t.toJson()).toList(),
  };
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
