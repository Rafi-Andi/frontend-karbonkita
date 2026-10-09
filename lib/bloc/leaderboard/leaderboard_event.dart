import '../../models/leaderboard.dart';

/// Event LeaderboardBloc.
sealed class LeaderboardEvent {
  const LeaderboardEvent();
}

/// Muat peringkat untuk kombinasi scope + timeframe.
class LeaderboardLoaded extends LeaderboardEvent {
  const LeaderboardLoaded({
    this.scope = LeaderboardScope.rt,
    this.timeframe = LeaderboardTimeframe.weekly,
  });

  final LeaderboardScope scope;
  final LeaderboardTimeframe timeframe;
}

/// Muat ulang kombinasi yang sedang aktif (pull-to-refresh).
class LeaderboardRefreshed extends LeaderboardEvent {
  const LeaderboardRefreshed();
}
