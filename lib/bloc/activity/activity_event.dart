/// Event ActivityBloc.
sealed class ActivityEvent {
  const ActivityEvent();
}

/// Muat aktivitas terbaru dari backend.
class ActivityLoaded extends ActivityEvent {
  const ActivityLoaded();
}

/// Muat ulang (pull-to-refresh).
class ActivityRefreshed extends ActivityEvent {
  const ActivityRefreshed();
}
