import '../../models/merchant_application.dart';

/// Status muat daftar antrean.
enum AdminMerchantStatus { initial, loading, loaded, error }

/// Status muat detail 1 pengajuan.
enum AdminMerchantDetailStatus { initial, loading, loaded, error }

/// Status proses approve/reject.
enum AdminMerchantVerifyStatus { idle, submitting, success, failure }

class AdminMerchantState {
  const AdminMerchantState({
    this.status = AdminMerchantStatus.initial,
    this.items = const [],
    this.summary = const MerchantApplicationSummary(
      pending: 0,
      verified: 0,
      rejected: 0,
    ),
    this.filter = 'pending',
    this.searchQuery = '',
    this.errorMessage,
    this.detailStatus = AdminMerchantDetailStatus.initial,
    this.detail,
    this.detailError,
    this.verifyStatus = AdminMerchantVerifyStatus.idle,
    this.lastResult,
    this.verifyErrorMessage,
    this.isUnauthorized = false,
  });

  final AdminMerchantStatus status;
  final List<MerchantApplicationItem> items;
  final MerchantApplicationSummary summary;
  final String filter;

  /// Filter client-side (nama toko/owner) di halaman aktif.
  final String searchQuery;
  final String? errorMessage;

  final AdminMerchantDetailStatus detailStatus;
  final MerchantApplicationDetail? detail;
  final String? detailError;

  final AdminMerchantVerifyStatus verifyStatus;
  final MerchantVerifyResult? lastResult;
  final String? verifyErrorMessage;

  /// True bila backend 401 — UI harus logout, bukan sekadar retry.
  final bool isUnauthorized;

  /// Hasil filter pencarian (tidak memanggil backend ulang).
  List<MerchantApplicationItem> get filteredItems {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((e) {
      return e.storeName.toLowerCase().contains(q) ||
          e.ownerName.toLowerCase().contains(q) ||
          e.ownerEmail.toLowerCase().contains(q);
    }).toList();
  }

  AdminMerchantState copyWith({
    AdminMerchantStatus? status,
    List<MerchantApplicationItem>? items,
    MerchantApplicationSummary? summary,
    String? filter,
    String? searchQuery,
    String? errorMessage,
    AdminMerchantDetailStatus? detailStatus,
    MerchantApplicationDetail? detail,
    bool clearDetail = false,
    String? detailError,
    AdminMerchantVerifyStatus? verifyStatus,
    MerchantVerifyResult? lastResult,
    bool clearVerify = false,
    String? verifyErrorMessage,
    bool? isUnauthorized,
  }) {
    return AdminMerchantState(
      status: status ?? this.status,
      items: items ?? this.items,
      summary: summary ?? this.summary,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      detailStatus: detailStatus ?? this.detailStatus,
      detail: clearDetail ? null : (detail ?? this.detail),
      detailError: detailError,
      verifyStatus: verifyStatus ?? this.verifyStatus,
      lastResult: clearVerify ? null : (lastResult ?? this.lastResult),
      verifyErrorMessage: clearVerify ? null : verifyErrorMessage,
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
    );
  }
}
