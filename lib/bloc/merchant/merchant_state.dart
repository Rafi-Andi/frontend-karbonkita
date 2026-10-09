import '../../models/merchant_dashboard.dart';

/// Status muat dashboard toko.
enum MerchantStatus { initial, loading, loaded, error }

/// Status proses redeem satu voucher.
enum MerchantRedeemStatus { idle, redeeming, success, failure }

/// Status muat halaman riwayat pencairan.
enum DisbursementHistoryStatus { initial, loading, loaded, loadingMore, error }

class MerchantState {
  const MerchantState({
    this.status = MerchantStatus.initial,
    this.dashboard,
    this.errorMessage,
    this.isToggling = false,
    this.toggleError,
    this.redeemStatus = MerchantRedeemStatus.idle,
    this.lastRedeem,
    this.redeemErrorMessage,
    this.isUnauthorized = false,
    this.isOffline = false,
    this.lastUpdated,
    this.historyStatus = DisbursementHistoryStatus.initial,
    this.historyItems = const [],
    this.historyStatusFilter = 'all',
    this.historyPage = 0,
    this.historyLastPage = 1,
    this.historyTotal = 0,
    this.historyError,
  });

  final MerchantStatus status;
  final MerchantDashboard? dashboard;
  final String? errorMessage;

  /// True saat PATCH /merchant/status sedang berjalan.
  final bool isToggling;
  final String? toggleError;

  final MerchantRedeemStatus redeemStatus;
  final RedeemResult? lastRedeem;
  final String? redeemErrorMessage;

  /// True bila backend 401 — UI harus logout, bukan sekadar retry.
  final bool isUnauthorized;

  /// True bila data berasal dari cache offline.
  final bool isOffline;
  final DateTime? lastUpdated;

  /// Halaman riwayat pencairan (independen dari dashboard).
  final DisbursementHistoryStatus historyStatus;
  final List<DisbursementHistoryItem> historyItems;
  final String historyStatusFilter;
  final int historyPage;
  final int historyLastPage;
  final int historyTotal;
  final String? historyError;

  MerchantState copyWith({
    MerchantStatus? status,
    MerchantDashboard? dashboard,
    String? errorMessage,
    bool? isToggling,
    String? toggleError,
    MerchantRedeemStatus? redeemStatus,
    RedeemResult? lastRedeem,
    bool clearRedeem = false,
    String? redeemErrorMessage,
    bool? isUnauthorized,
    bool? isOffline,
    DateTime? lastUpdated,
    DisbursementHistoryStatus? historyStatus,
    List<DisbursementHistoryItem>? historyItems,
    String? historyStatusFilter,
    int? historyPage,
    int? historyLastPage,
    int? historyTotal,
    String? historyError,
  }) {
    return MerchantState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      errorMessage: errorMessage,
      isToggling: isToggling ?? this.isToggling,
      toggleError: toggleError,
      redeemStatus: redeemStatus ?? this.redeemStatus,
      lastRedeem: clearRedeem ? null : (lastRedeem ?? this.lastRedeem),
      redeemErrorMessage: clearRedeem ? null : redeemErrorMessage,
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
      isOffline: isOffline ?? this.isOffline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      historyStatus: historyStatus ?? this.historyStatus,
      historyItems: historyItems ?? this.historyItems,
      historyStatusFilter: historyStatusFilter ?? this.historyStatusFilter,
      historyPage: historyPage ?? this.historyPage,
      historyLastPage: historyLastPage ?? this.historyLastPage,
      historyTotal: historyTotal ?? this.historyTotal,
      historyError: historyError,
    );
  }
}
