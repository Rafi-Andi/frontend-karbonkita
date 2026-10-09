import '../../models/donation.dart';

/// Status muat katalog/detail/riwayat.
enum DonationStatus { initial, loading, loaded, error }

/// Status proses buat donasi (invoice).
enum DonationCreateStatus { idle, creating, success, failure }

/// Status proses batal donasi.
enum DonationCancelStatus { idle, cancelling, success, failure }

class DonationState {
  const DonationState({
    this.status = DonationStatus.initial,
    this.campaigns = const [],
    this.errorMessage,
    this.detailStatus = DonationStatus.initial,
    this.detail,
    this.detailError,
    this.createStatus = DonationCreateStatus.idle,
    this.lastCreate,
    this.createErrorMessage,
    this.inventoryStatus = DonationStatus.initial,
    this.inventory,
    this.inventoryError,
    this.cancelStatus = DonationCancelStatus.idle,
    this.cancellingId,
    this.cancelErrorMessage,
    this.isUnauthorized = false,
  });

  final DonationStatus status;
  final List<DonationCampaign> campaigns;
  final String? errorMessage;

  final DonationStatus detailStatus;
  final DonationCampaign? detail;
  final String? detailError;

  final DonationCreateStatus createStatus;
  final CreateDonationResult? lastCreate;
  final String? createErrorMessage;

  final DonationStatus inventoryStatus;
  final MyDonationInventory? inventory;
  final String? inventoryError;

  final DonationCancelStatus cancelStatus;
  final int? cancellingId;
  final String? cancelErrorMessage;

  /// True bila backend 401 — UI harus logout, bukan sekadar retry.
  final bool isUnauthorized;

  DonationState copyWith({
    DonationStatus? status,
    List<DonationCampaign>? campaigns,
    String? errorMessage,
    DonationStatus? detailStatus,
    DonationCampaign? detail,
    String? detailError,
    DonationCreateStatus? createStatus,
    CreateDonationResult? lastCreate,
    bool clearCreate = false,
    String? createErrorMessage,
    DonationStatus? inventoryStatus,
    MyDonationInventory? inventory,
    String? inventoryError,
    DonationCancelStatus? cancelStatus,
    int? cancellingId,
    String? cancelErrorMessage,
    bool? isUnauthorized,
  }) {
    return DonationState(
      status: status ?? this.status,
      campaigns: campaigns ?? this.campaigns,
      errorMessage: errorMessage,
      detailStatus: detailStatus ?? this.detailStatus,
      detail: detail ?? this.detail,
      detailError: detailError,
      createStatus: createStatus ?? this.createStatus,
      lastCreate: clearCreate ? null : (lastCreate ?? this.lastCreate),
      createErrorMessage: clearCreate ? null : createErrorMessage,
      inventoryStatus: inventoryStatus ?? this.inventoryStatus,
      inventory: inventory ?? this.inventory,
      inventoryError: inventoryError,
      cancelStatus: cancelStatus ?? this.cancelStatus,
      cancellingId: cancellingId ?? this.cancellingId,
      cancelErrorMessage: cancelErrorMessage,
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
    );
  }
}
