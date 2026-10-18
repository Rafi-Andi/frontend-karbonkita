import '../../models/admin_reward.dart';

/// Status muat daftar reward.
enum AdminRewardStatus { initial, loading, loaded, error }

/// Status proses submit (toggle aktif/nonaktif, ubah tenggat).
enum AdminRewardSubmitStatus { idle, submitting, success, failure }

/// Status muat daftar penukar (per reward, paginasi).
enum AdminRewardClaimsStatus { idle, loading, loaded, error }

class AdminRewardState {
  const AdminRewardState({
    this.status = AdminRewardStatus.initial,
    this.rewards = const [],
    this.filter,
    this.errorMessage,
    this.isUnauthorized = false,
    this.submitStatus = AdminRewardSubmitStatus.idle,
    this.submitMessage,
    this.lastReward,
    this.submitErrors = const {},
    this.submitErrorMessage,
    this.claimsStatus = AdminRewardClaimsStatus.idle,
    this.claimsRewardId,
    this.claims = const [],
    this.claimsPage = 1,
    this.claimsLastPage = 1,
    this.claimsTotal = 0,
    this.claimsError,
  });

  final AdminRewardStatus status;
  final List<AdminReward> rewards;

  /// Filter tampilan: null = semua, 'active', 'inactive', 'expired'.
  final String? filter;
  final String? errorMessage;

  /// True bila backend 401/403 — UI harus logout / tolak akses.
  final bool isUnauthorized;

  final AdminRewardSubmitStatus submitStatus;

  /// Pesan sukses siap tampil (snackbar) setelah aksi berhasil.
  final String? submitMessage;

  /// Hasil create/update terakhir dari backend.
  final AdminReward? lastReward;

  /// Error 422 per-field dari backend (untuk sheet rincian).
  final Map<String, List<String>> submitErrors;
  final String? submitErrorMessage;

  // ---- Daftar penukar (detail satu reward) ----
  final AdminRewardClaimsStatus claimsStatus;

  /// Id reward yang daftar penukarnya sedang dimuat.
  final int? claimsRewardId;
  final List<AdminRewardClaim> claims;
  final int claimsPage;
  final int claimsLastPage;
  final int claimsTotal;
  final String? claimsError;

  /// True bila masih ada halaman penukar berikutnya.
  bool get hasMoreClaims => claimsPage < claimsLastPage;

  List<AdminReward> get filteredRewards {
    switch (filter) {
      case 'active':
        return rewards.where((r) => r.isActive && !r.isExpired).toList();
      case 'inactive':
        return rewards.where((r) => !r.isActive).toList();
      case 'expired':
        return rewards.where((r) => r.isExpired).toList();
      default:
        return rewards;
    }
  }

  AdminRewardState copyWith({
    AdminRewardStatus? status,
    List<AdminReward>? rewards,
    String? filter,
    bool clearFilter = false,
    String? errorMessage,
    bool? isUnauthorized,
    AdminRewardSubmitStatus? submitStatus,
    String? submitMessage,
    AdminReward? lastReward,
    Map<String, List<String>>? submitErrors,
    String? submitErrorMessage,
    bool clearSubmit = false,
    AdminRewardClaimsStatus? claimsStatus,
    int? claimsRewardId,
    List<AdminRewardClaim>? claims,
    int? claimsPage,
    int? claimsLastPage,
    int? claimsTotal,
    String? claimsError,
  }) {
    return AdminRewardState(
      status: status ?? this.status,
      rewards: rewards ?? this.rewards,
      filter: clearFilter ? null : (filter ?? this.filter),
      errorMessage: errorMessage,
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
      submitStatus: submitStatus ?? this.submitStatus,
      submitMessage: clearSubmit ? null : (submitMessage ?? this.submitMessage),
      lastReward: clearSubmit ? null : (lastReward ?? this.lastReward),
      submitErrors: clearSubmit
          ? const {}
          : (submitErrors ?? this.submitErrors),
      submitErrorMessage: clearSubmit ? null : submitErrorMessage,
      claimsStatus: claimsStatus ?? this.claimsStatus,
      claimsRewardId: claimsRewardId ?? this.claimsRewardId,
      claims: claims ?? this.claims,
      claimsPage: claimsPage ?? this.claimsPage,
      claimsLastPage: claimsLastPage ?? this.claimsLastPage,
      claimsTotal: claimsTotal ?? this.claimsTotal,
      claimsError: claimsError,
    );
  }
}
