import '../../models/dashboard.dart';

/// Status muat dashboard Beranda.
enum DashboardStatus { initial, loading, loaded, error }

class DashboardState {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.dashboard,
    this.errorMessage,
    this.isUnauthorized = false,
    this.isOffline = false,
    this.lastUpdated,
  });

  final DashboardStatus status;
  final DashboardData? dashboard;
  final String? errorMessage;

  /// True bila backend 401 — UI harus logout, bukan sekadar retry.
  final bool isUnauthorized;

  /// True bila data berasal dari cache offline (belum refresh sukses).
  final bool isOffline;

  /// Kapan cache terakhir disimpan (untuk label "terakhir diperbarui").
  final DateTime? lastUpdated;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardData? dashboard,
    String? errorMessage,
    bool? isUnauthorized,
    bool? isOffline,
    DateTime? lastUpdated,
    bool clearLastUpdated = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      errorMessage: errorMessage,
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
      isOffline: isOffline ?? this.isOffline,
      lastUpdated: clearLastUpdated ? null : (lastUpdated ?? this.lastUpdated),
    );
  }
}
