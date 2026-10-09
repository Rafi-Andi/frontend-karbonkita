import '../../models/leaderboard.dart';

/// Status muat leaderboard.
enum LeaderboardStatus { initial, loading, loaded, error }

class LeaderboardState {
  const LeaderboardState({
    this.status = LeaderboardStatus.initial,
    this.scope = LeaderboardScope.rt,
    this.timeframe = LeaderboardTimeframe.weekly,
    this.board,
    this.errorMessage,
    this.isUnauthorized = false,
    this.isOffline = false,
    this.lastUpdated,
  });

  final LeaderboardStatus status;
  final LeaderboardScope scope;
  final LeaderboardTimeframe timeframe;
  final LeaderboardBoard? board;
  final String? errorMessage;

  /// True bila backend 401 — UI harus logout, bukan sekadar retry.
  final bool isUnauthorized;

  /// True bila papan berasal dari cache offline.
  final bool isOffline;
  final DateTime? lastUpdated;

  LeaderboardState copyWith({
    LeaderboardStatus? status,
    LeaderboardScope? scope,
    LeaderboardTimeframe? timeframe,
    LeaderboardBoard? board,
    String? errorMessage,
    bool? isUnauthorized,
    bool? isOffline,
    DateTime? lastUpdated,
  }) {
    return LeaderboardState(
      status: status ?? this.status,
      scope: scope ?? this.scope,
      timeframe: timeframe ?? this.timeframe,
      board: board ?? this.board,
      errorMessage: errorMessage,
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
      isOffline: isOffline ?? this.isOffline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
