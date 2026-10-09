import '../../models/donation.dart';
import '../../models/mitra_product.dart';

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
    this.products = const [],
    this.productsLoading = false,
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

  /// Produk untuk picker funding (hanya fundable yang bisa dipilih).
  final List<MitraProduct> products;
  final bool productsLoading;

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
    List<MitraProduct>? products,
    bool? productsLoading,
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
      products: products ?? this.products,
      productsLoading: productsLoading ?? this.productsLoading,
    );
  }
}
