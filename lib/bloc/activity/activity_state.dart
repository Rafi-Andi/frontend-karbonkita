import '../../models/activity.dart';

/// Status muat aktivitas terbaru.
enum ActivityStatus { initial, loading, loaded, error }

class ActivityState {
  const ActivityState({
    this.status = ActivityStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.isUnauthorized = false,
    this.isOffline = false,
    this.lastUpdated,
  });

  final ActivityStatus status;
  final List<UserActivity> items;
  final String? errorMessage;

  /// True bila backend 401 — UI harus logout, bukan sekadar retry.
  final bool isUnauthorized;

  final bool isOffline;
  final DateTime? lastUpdated;

  ActivityState copyWith({
    ActivityStatus? status,
    List<UserActivity>? items,
    String? errorMessage,
    bool? isUnauthorized,
    bool? isOffline,
    DateTime? lastUpdated,
  }) {
    return ActivityState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
      isOffline: isOffline ?? this.isOffline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
