/// Dashboard merchant dari `GET /api/merchant/dashboard`.
///
/// Backend MerchantController@dashboard: store_name, verification_status
/// (pending|verified|rejected), is_open, can_redeem, balance (String "0.00"),
/// stats{total_vouchers, active_vouchers, total_redeemed, total_disbursed},
/// recent_disbursements[{id, voucher_claim_id, amount, status, raw_status,
/// payout_id, reference_id, xendit_disbursement_id, failure_code, processed_at}].
///
/// Catatan: API apa adanya belum join nama warga / judul voucher, jadi list
/// transaksi ditampilkan generik (Klaim #id + nominal + status).
class MerchantDashboard {
  const MerchantDashboard({
    required this.storeName,
    required this.verificationStatus,
    required this.isOpen,
    required this.canRedeem,
    required this.balance,
    required this.stats,
    required this.recent,
  });

  final String storeName;
  final String verificationStatus;
  final bool isOpen;
  final bool canRedeem;
  final double balance;
  final MerchantStats stats;
  final List<MerchantDisbursement> recent;

  bool get isVerified => verificationStatus == 'verified';

  factory MerchantDashboard.fromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'] as Map<String, dynamic>? ?? const {};
    final recentJson = json['recent_disbursements'];
    return MerchantDashboard(
      storeName: json['store_name'] as String? ?? '',
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      isOpen: _toBool(json['is_open']),
      canRedeem: _toBool(json['can_redeem']),
      balance: _toDouble(json['balance']),
      stats: MerchantStats.fromJson(statsJson),
      recent: recentJson is List
          ? recentJson
                .whereType<Map<String, dynamic>>()
                .map(MerchantDisbursement.fromJson)
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'store_name': storeName,
    'verification_status': verificationStatus,
    'is_open': isOpen,
    'can_redeem': canRedeem,
    'balance': balance.toStringAsFixed(2),
    'stats': stats.toJson(),
    'recent_disbursements': recent.map((e) => e.toJson()).toList(),
  };
}

class MerchantStats {
  const MerchantStats({
    required this.totalVouchers,
    required this.activeVouchers,
    required this.totalRedeemed,
    required this.totalDisbursed,
  });

  final int totalVouchers;
  final int activeVouchers;
  final int totalRedeemed;
  final double totalDisbursed;

  factory MerchantStats.fromJson(Map<String, dynamic> json) {
    return MerchantStats(
      totalVouchers: _toInt(json['total_vouchers']),
      activeVouchers: _toInt(json['active_vouchers']),
      totalRedeemed: _toInt(json['total_redeemed']),
      totalDisbursed: _toDouble(json['total_disbursed']),
    );
  }

  Map<String, dynamic> toJson() => {
    'total_vouchers': totalVouchers,
    'active_vouchers': activeVouchers,
    'total_redeemed': totalRedeemed,
    'total_disbursed': totalDisbursed.toStringAsFixed(2),
  };
}

class MerchantDisbursement {
  const MerchantDisbursement({
    required this.id,
    required this.voucherClaimId,
    required this.amount,
    required this.status,
    required this.rawStatus,
    required this.payoutId,
    required this.referenceId,
    required this.processedAt,
  });

  final int id;
  final int voucherClaimId;
  final double amount;
  final String status;
  final String rawStatus;
  final String payoutId;
  final String referenceId;
  final String processedAt;

  bool get isCompleted => status == 'completed';

  factory MerchantDisbursement.fromJson(Map<String, dynamic> json) {
    return MerchantDisbursement(
      id: _toInt(json['id']),
      voucherClaimId: _toInt(json['voucher_claim_id']),
      amount: _toDouble(json['amount']),
      status: json['status'] as String? ?? '',
      rawStatus: json['raw_status'] as String? ?? '',
      payoutId:
          (json['payout_id'] ?? json['xendit_disbursement_id'])?.toString() ??
          '',
      referenceId: json['reference_id'] as String? ?? '',
      processedAt: json['processed_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'voucher_claim_id': voucherClaimId,
    'amount': amount.toStringAsFixed(2),
    'status': status,
    'raw_status': rawStatus,
    'payout_id': payoutId,
    'reference_id': referenceId,
    'processed_at': processedAt,
  };
}

/// Satu baris riwayat pencairan dari `GET /api/merchant/disbursements`.
///
/// Beda dengan [MerchantDisbursement] (dipakai dashboard ringkas): di sini
/// backend sudah join nama warga (RT/RW) + judul voucher + data rekening.
class DisbursementHistoryItem {
  const DisbursementHistoryItem({
    required this.id,
    required this.voucherClaimId,
    required this.amount,
    required this.status,
    required this.rawStatus,
    required this.payoutId,
    required this.referenceId,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountName,
    required this.failureCode,
    required this.failureReason,
    required this.processedAt,
    required this.wargaName,
    required this.wargaRt,
    required this.wargaRw,
    required this.voucherTitle,
  });

  final int id;
  final int voucherClaimId;
  final double amount;
  final String status;
  final String rawStatus;
  final String payoutId;
  final String referenceId;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountName;
  final String failureCode;
  final String failureReason;
  final String processedAt;
  final String wargaName;
  final String wargaRt;
  final String wargaRw;
  final String voucherTitle;

  bool get isCompleted => status == 'completed';

  factory DisbursementHistoryItem.fromJson(Map<String, dynamic> json) {
    return DisbursementHistoryItem(
      id: _toInt(json['id']),
      voucherClaimId: _toInt(json['voucher_claim_id']),
      amount: _toDouble(json['amount']),
      status: json['status'] as String? ?? '',
      rawStatus: json['raw_status'] as String? ?? '',
      payoutId:
          (json['payout_id'] ?? json['xendit_disbursement_id'])?.toString() ??
          '',
      referenceId: json['reference_id'] as String? ?? '',
      bankName: json['bank_name'] as String? ?? '',
      bankAccountNumber: json['bank_account_number'] as String? ?? '',
      bankAccountName: json['bank_account_name'] as String? ?? '',
      failureCode: json['failure_code'] as String? ?? '',
      failureReason: json['failure_reason'] as String? ?? '',
      processedAt: json['processed_at'] as String? ?? '',
      wargaName: json['warga_name'] as String? ?? '',
      wargaRt: json['warga_rt']?.toString() ?? '',
      wargaRw: json['warga_rw']?.toString() ?? '',
      voucherTitle: json['voucher_title'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'voucher_claim_id': voucherClaimId,
    'amount': amount.toStringAsFixed(2),
    'status': status,
    'raw_status': rawStatus,
    'payout_id': payoutId,
    'reference_id': referenceId,
    'bank_name': bankName,
    'bank_account_number': bankAccountNumber,
    'bank_account_name': bankAccountName,
    'failure_code': failureCode,
    'failure_reason': failureReason,
    'processed_at': processedAt,
    'warga_name': wargaName,
    'warga_rt': wargaRt,
    'warga_rw': wargaRw,
    'voucher_title': voucherTitle,
  };
}

/// Satu halaman riwayat pencairan: item + meta paginasi.
class DisbursementHistoryPage {
  const DisbursementHistoryPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<DisbursementHistoryItem> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory DisbursementHistoryPage.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> meta,
  ) {
    final rawItems = json['data'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(DisbursementHistoryItem.fromJson)
              .toList()
        : <DisbursementHistoryItem>[];

    return DisbursementHistoryPage(
      items: items,
      currentPage: _toInt(meta['current_page']),
      lastPage: _toInt(meta['last_page']),
      total: _toInt(meta['total']),
    );
  }
}

/// Hasil redeem dari `POST /api/vouchers/redeem`.
///
/// Sukses: {claim_id, qr_token, voucher_title, amount, new_balance,
/// xendit_payout_id, reference_id, disbursement_status, disbursement_id}.
class RedeemResult {
  const RedeemResult({
    required this.claimId,
    required this.qrToken,
    required this.voucherTitle,
    required this.amount,
    required this.newBalance,
    required this.payoutId,
    required this.referenceId,
    required this.disbursementStatus,
    required this.disbursementId,
  });

  final int claimId;
  final String qrToken;
  final String voucherTitle;
  final double amount;
  final double newBalance;
  final String payoutId;
  final String referenceId;
  final String disbursementStatus;
  final int disbursementId;

  bool get isCompleted => disbursementStatus == 'completed';

  factory RedeemResult.fromJson(Map<String, dynamic> json) {
    return RedeemResult(
      claimId: _toInt(json['claim_id']),
      qrToken: json['qr_token'] as String? ?? '',
      voucherTitle: json['voucher_title'] as String? ?? '',
      amount: _toDouble(json['amount']),
      newBalance: _toDouble(json['new_balance']),
      payoutId: json['xendit_payout_id'] as String? ?? '',
      referenceId: json['reference_id'] as String? ?? '',
      disbursementStatus: json['disbursement_status'] as String? ?? 'pending',
      disbursementId: _toInt(json['disbursement_id']),
    );
  }

  Map<String, dynamic> toJson() => {
    'claim_id': claimId,
    'qr_token': qrToken,
    'voucher_title': voucherTitle,
    'amount': amount.toStringAsFixed(2),
    'new_balance': newBalance.toStringAsFixed(2),
    'xendit_payout_id': payoutId,
    'reference_id': referenceId,
    'disbursement_status': disbursementStatus,
    'disbursement_id': disbursementId,
  };
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
