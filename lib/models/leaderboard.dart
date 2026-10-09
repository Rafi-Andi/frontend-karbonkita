import 'dashboard.dart';

/// Scope leaderboard: individu se-RT atau individu se-RW.
enum LeaderboardScope { rt, rw }

/// Rentang waktu leaderboard.
enum LeaderboardTimeframe { weekly, monthly }

/// Papan peringkat penuh dari `GET /api/leaderboard`.
/// Backend LeaderboardResource: scope, timeframe, wilayah{}, rankings[], current_user|null.
class LeaderboardBoard {
  const LeaderboardBoard({
    required this.scope,
    required this.timeframe,
    required this.rankings,
    required this.currentUser,
    required this.wilayah,
  });

  final String scope;
  final String timeframe;
  final List<LeaderboardPreview> rankings;
  final LeaderboardPreview? currentUser;
  final LeaderboardWilayah wilayah;

  factory LeaderboardBoard.fromJson(Map<String, dynamic> json) {
    final rankingsJson = json['rankings'];
    final currentJson = json['current_user'];
    final wilayahJson = json['wilayah'];
    return LeaderboardBoard(
      scope: json['scope'] as String? ?? 'rt',
      timeframe: json['timeframe'] as String? ?? 'weekly',
      rankings: rankingsJson is List
          ? rankingsJson
                .whereType<Map<String, dynamic>>()
                .map(LeaderboardPreview.fromJson)
                .toList()
          : const [],
      currentUser: currentJson is Map<String, dynamic>
          ? LeaderboardPreview.fromJson(currentJson)
          : null,
      wilayah: wilayahJson is Map<String, dynamic>
          ? LeaderboardWilayah.fromJson(wilayahJson)
          : const LeaderboardWilayah.empty(),
    );
  }

  Map<String, dynamic> toJson() => {
    'scope': scope,
    'timeframe': timeframe,
    'wilayah': wilayah.toJson(),
    'rankings': rankings.map((e) => e.toJson()).toList(),
    'current_user': currentUser?.toJson(),
  };
}

/// Wilayah leaderboard aktif (dari user login + scope).
/// scope=rt -> rt terisi; scope=rw -> rt null (semua RT dalam RW itu).
class LeaderboardWilayah {
  const LeaderboardWilayah({
    required this.kota,
    required this.kecamatan,
    required this.kelurahan,
    required this.rw,
    required this.rt,
  });

  const LeaderboardWilayah.empty()
    : kota = '',
      kecamatan = '',
      kelurahan = '',
      rw = '',
      rt = null;

  final String kota;
  final String kecamatan;
  final String kelurahan;
  final String rw;
  final String? rt;

  factory LeaderboardWilayah.fromJson(Map<String, dynamic> json) {
    return LeaderboardWilayah(
      kota: json['kota'] as String? ?? '',
      kecamatan: json['kecamatan'] as String? ?? '',
      kelurahan: json['kelurahan'] as String? ?? '',
      rw: json['rw']?.toString() ?? '',
      rt: json['rt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'kota': kota,
    'kecamatan': kecamatan,
    'kelurahan': kelurahan,
    'rw': rw,
    'rt': rt,
  };

  bool get isEmpty => kota.isEmpty && kelurahan.isEmpty && rw.isEmpty;

  /// "RT 005/RW 02 • Mojo, Gubeng, Surabaya" atau "RW 02 • Mojo, Gubeng, Surabaya".
  String get label {
    final rtRw = rt == null || rt!.isEmpty ? 'RW $rw' : 'RT $rt/RW $rw';
    final area = [
      kelurahan,
      kecamatan,
      kota,
    ].where((e) => e.isNotEmpty).join(', ');
    if (area.isEmpty) return rtRw;
    return '$rtRw • $area';
  }
}

/// Mapping toggle UI ke query backend.
extension LeaderboardScopeX on LeaderboardScope {
  String get query => switch (this) {
    LeaderboardScope.rt => 'rt',
    LeaderboardScope.rw => 'rw',
  };
}

extension LeaderboardTimeframeX on LeaderboardTimeframe {
  String get query => switch (this) {
    LeaderboardTimeframe.weekly => 'weekly',
    LeaderboardTimeframe.monthly => 'monthly',
  };
}
