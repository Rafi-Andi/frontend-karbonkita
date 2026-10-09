/// Katalog & riwayat donasi dari API backend.
///
/// Publik: `GET /donation-campaigns`, `GET /donation-campaigns/{slug}`.
/// Login: `POST /donations`, `GET /user/my-donations`, `POST /donations/{id}/cancel`.
/// Admin: `GET|POST /admin/donation-campaigns`, `PATCH /admin/donation-campaigns/{id}`,
/// `POST /admin/vouchers` (voucher didanai campaign).
class DonationCampaign {
  const DonationCampaign({
    required this.id,
    required this.title,
    required this.slug,
    required this.imageUrl,
    required this.targetAmount,
    required this.collectedAmount,
    required this.availableAmount,
    required this.progressPercent,
    required this.status,
    required this.isOpen,
    required this.endedAt,
    this.description = '',
    this.donorCount = 0,
    this.topDonors = const [],
    this.recentDonations = const [],
  });

  final int id;
  final String title;
  final String slug;
  final String imageUrl;
  final double targetAmount;
  final double collectedAmount;
  final double availableAmount;
  final double progressPercent;
  final String status;
  final bool isOpen;
  final String endedAt;

  /// Hanya ada di detail (campaignDetail).
  final String description;
  final int donorCount;
  final List<DonorEntry> topDonors;
  final List<RecentDonation> recentDonations;

  factory DonationCampaign.fromJson(Map<String, dynamic> json) {
    final donors = json['top_donors'];
    final recent = json['recent_donations'];
    return DonationCampaign(
      id: _toInt(json['id']),
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      targetAmount: _toDouble(json['target_amount']),
      collectedAmount: _toDouble(json['collected_amount']),
      availableAmount: _toDouble(json['available_amount']),
      progressPercent: _toDouble(json['progress_percent']),
      status: json['status'] as String? ?? '',
      isOpen: _toBool(json['is_open']),
      endedAt: json['ended_at'] as String? ?? '',
      description: json['description'] as String? ?? '',
      donorCount: _toInt(json['donor_count']),
      topDonors: donors is List
          ? donors
                .whereType<Map<String, dynamic>>()
                .map(DonorEntry.fromJson)
                .toList()
          : const [],
      recentDonations: recent is List
          ? recent
                .whereType<Map<String, dynamic>>()
                .map(RecentDonation.fromJson)
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'slug': slug,
    'image_url': imageUrl,
    'target_amount': targetAmount.toStringAsFixed(2),
    'collected_amount': collectedAmount.toStringAsFixed(2),
    'available_amount': availableAmount.toStringAsFixed(2),
    'progress_percent': progressPercent,
    'status': status,
    'is_open': isOpen,
    'ended_at': endedAt,
  };
}

/// Satu baris leaderboard donatur campaign.
class DonorEntry {
  const DonorEntry({
    required this.payerName,
    required this.total,
    required this.tier,
  });

  final String payerName;
  final double total;
  final String tier;

  factory DonorEntry.fromJson(Map<String, dynamic> json) {
    return DonorEntry(
      payerName: json['payer_name'] as String? ?? 'Donatur',
      total: _toDouble(json['total']),
      tier: json['tier'] as String? ?? '',
    );
  }
}

/// Satu donasi lunas terbaru di campaign.
class RecentDonation {
  const RecentDonation({
    required this.payerName,
    required this.amount,
    required this.paidAt,
  });

  final String payerName;
  final double amount;
  final String paidAt;

  factory RecentDonation.fromJson(Map<String, dynamic> json) {
    return RecentDonation(
      payerName: json['payer_name'] as String? ?? 'Donatur',
      amount: _toDouble(json['amount']),
      paidAt: json['paid_at'] as String? ?? '',
    );
  }
}

/// Satu riwayat donasi milik user dari `GET /user/my-donations`.
class MyDonation {
  const MyDonation({
    required this.id,
    required this.campaignId,
    required this.campaignTitle,
    required this.campaignSlug,
    required this.amount,
    required this.status,
    required this.invoiceUrl,
    required this.paidAt,
    required this.paymentChannel,
  });

  final int id;
  final int campaignId;
  final String campaignTitle;
  final String campaignSlug;
  final double amount;
  final String status; // pending | paid | expired | failed
  final String invoiceUrl; // hanya pending + ada invoice
  final String paidAt;
  final String paymentChannel;

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';

  factory MyDonation.fromJson(Map<String, dynamic> json) {
    final campaign = json['campaign'] as Map<String, dynamic>? ?? const {};
    return MyDonation(
      id: _toInt(json['id']),
      campaignId: _toInt(campaign['id']),
      campaignTitle: campaign['title'] as String? ?? '',
      campaignSlug: campaign['slug'] as String? ?? '',
      amount: _toDouble(json['amount']),
      status: json['status'] as String? ?? '',
      invoiceUrl: json['invoice_url'] as String? ?? '',
      paidAt: json['paid_at'] as String? ?? '',
      paymentChannel: json['payment_channel'] as String? ?? '',
    );
  }
}

/// Inventaris `my-donations`: daftar + total seumur hidup + tier badge.
class MyDonationInventory {
  const MyDonationInventory({
    required this.donations,
    required this.lifetimeTotal,
    required this.tier,
  });

  final List<MyDonation> donations;
  final double lifetimeTotal;
  final String tier;

  factory MyDonationInventory.fromJson(Map<String, dynamic> json) {
    final raw = json['donations'];
    return MyDonationInventory(
      donations: raw is List
          ? raw
                .whereType<Map<String, dynamic>>()
                .map(MyDonation.fromJson)
                .toList()
          : const [],
      lifetimeTotal: _toDouble(json['lifetime_total']),
      tier: json['tier'] as String? ?? '',
    );
  }
}

/// Hasil `POST /api/donations` (201): invoice Xendit untuk dibayar.
/// Pembayaran terjadi di halaman Xendit (browser), bukan di aplikasi.
class CreateDonationResult {
  const CreateDonationResult({
    required this.donationId,
    required this.externalId,
    required this.amount,
    required this.invoiceUrl,
    required this.expiresAt,
  });

  final int donationId;
  final String externalId;
  final double amount;
  final String invoiceUrl;
  final String expiresAt;

  factory CreateDonationResult.fromJson(Map<String, dynamic> json) {
    return CreateDonationResult(
      donationId: _toInt(json['donation_id']),
      externalId: json['external_id'] as String? ?? '',
      amount: _toDouble(json['amount']),
      invoiceUrl: json['invoice_url'] as String? ?? '',
      expiresAt: json['expires_at'] as String? ?? '',
    );
  }
}

/// Hasil `POST /api/admin/vouchers` (201): voucher didanai campaign.
class FundedVoucherResult {
  const FundedVoucherResult({
    required this.voucherId,
    required this.campaignId,
    required this.allocatedAmount,
    required this.campaignAvailable,
  });

  final int voucherId;
  final int campaignId;
  final double allocatedAmount;
  final double campaignAvailable;

  factory FundedVoucherResult.fromJson(Map<String, dynamic> json) {
    return FundedVoucherResult(
      voucherId: _toInt(json['voucher_id']),
      campaignId: _toInt(json['campaign_id']),
      allocatedAmount: _toDouble(json['allocated_amount']),
      campaignAvailable: _toDouble(json['campaign_available']),
    );
  }
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.toLowerCase();
    return v == 'true' || v == '1';
  }
  return false;
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
