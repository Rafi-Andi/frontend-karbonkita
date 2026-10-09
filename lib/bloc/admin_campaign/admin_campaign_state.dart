import '../../models/donation.dart';

/// Status muat daftar campaign admin.
enum AdminCampaignStatus { initial, loading, loaded, error }

/// Status proses submit (create/update campaign, create voucher).
enum AdminCampaignSubmitStatus { idle, submitting, success, failure }

class AdminCampaignState {
  const AdminCampaignState({
    this.status = AdminCampaignStatus.initial,
    this.campaigns = const [],
    this.errorMessage,
    this.submitStatus = AdminCampaignSubmitStatus.idle,
    this.lastCampaign,
    this.lastVoucher,
    this.submitErrorMessage,
    this.isUnauthorized = false,
  });

  final AdminCampaignStatus status;
  final List<DonationCampaign> campaigns;
  final String? errorMessage;

  final AdminCampaignSubmitStatus submitStatus;

  /// Hasil create/update campaign: {id, slug, status}.
  final Map<String, dynamic>? lastCampaign;

  /// Hasil create funded voucher.
  final FundedVoucherResult? lastVoucher;
  final String? submitErrorMessage;

  /// True bila backend 401/403 — UI harus logout / tolak akses.
  final bool isUnauthorized;

  AdminCampaignState copyWith({
    AdminCampaignStatus? status,
    List<DonationCampaign>? campaigns,
    String? errorMessage,
    AdminCampaignSubmitStatus? submitStatus,
    Map<String, dynamic>? lastCampaign,
    FundedVoucherResult? lastVoucher,
    bool clearSubmit = false,
    String? submitErrorMessage,
    bool? isUnauthorized,
  }) {
    return AdminCampaignState(
      status: status ?? this.status,
      campaigns: campaigns ?? this.campaigns,
      errorMessage: errorMessage,
      submitStatus: submitStatus ?? this.submitStatus,
      lastCampaign: clearSubmit ? null : (lastCampaign ?? this.lastCampaign),
      lastVoucher: clearSubmit ? null : (lastVoucher ?? this.lastVoucher),
      submitErrorMessage: clearSubmit ? null : submitErrorMessage,
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
    );
  }
}
