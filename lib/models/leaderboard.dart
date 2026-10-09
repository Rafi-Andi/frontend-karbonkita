import 'dashboard.dart';

/// Scope leaderboard: individu se-RT atau individu se-RW.
enum LeaderboardScope { rt, rw }

/// Rentang waktu leaderboard.
enum LeaderboardTimeframe { weekly, monthly }

/// Papan peringkat penuh dari `GET /api/leaderboard`.
/// Backend LeaderboardResource: scope, timeframe, rankings[], current_user|null.
class LeaderboardBoard {
  const LeaderboardBoard({
    required this.scope,
    required this.timeframe,
    required this.rankings,
    required this.currentUser,
  });

  final String scope;
  final String timeframe;
  final List<LeaderboardPreview> rankings;
  final LeaderboardPreview? currentUser;

  factory LeaderboardBoard.fromJson(Map<String, dynamic> json) {
    final rankingsJson = json['rankings'];
    final currentJson = json['current_user'];
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
    );
  }

  Map<String, dynamic> toJson() => {
    'scope': scope,
    'timeframe': timeframe,
    'rankings': rankings.map((e) => e.toJson()).toList(),
    'current_user': currentUser?.toJson(),
  };
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
