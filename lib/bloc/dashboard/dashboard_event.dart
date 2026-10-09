/// Event DashboardBloc.
sealed class DashboardEvent {
  const DashboardEvent();
}

/// Muat paket dashboard Beranda dari backend.
class DashboardLoaded extends DashboardEvent {
  const DashboardLoaded();
}

/// Muat ulang dashboard (pull-to-refresh Beranda).
class DashboardRefreshed extends DashboardEvent {
  const DashboardRefreshed();
}
