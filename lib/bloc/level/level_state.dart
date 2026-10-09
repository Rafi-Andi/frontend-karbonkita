import '../../models/level_tier.dart';

/// Status muat level tiers.
enum LevelStatus { initial, loading, loaded, error }

class LevelState {
  const LevelState({
    this.status = LevelStatus.initial,
    this.data,
    this.errorMessage,
    this.isUnauthorized = false,
    this.isOffline = false,
    this.lastUpdated,
  });

  final LevelStatus status;
  final LevelTiersData? data;
  final String? errorMessage;

  /// True bila backend 401 — UI harus logout, bukan sekadar retry.
  final bool isUnauthorized;

  final bool isOffline;
  final DateTime? lastUpdated;

  LevelState copyWith({
    LevelStatus? status,
    LevelTiersData? data,
    String? errorMessage,
    bool? isUnauthorized,
    bool? isOffline,
    DateTime? lastUpdated,
  }) {
    return LevelState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
      isOffline: isOffline ?? this.isOffline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
