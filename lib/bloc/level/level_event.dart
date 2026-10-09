/// Event LevelBloc.
sealed class LevelEvent {
  const LevelEvent();
}

/// Muat 3 tier level dari backend.
class LevelLoaded extends LevelEvent {
  const LevelLoaded();
}

/// Muat ulang (pull-to-refresh).
class LevelRefreshed extends LevelEvent {
  const LevelRefreshed();
}
