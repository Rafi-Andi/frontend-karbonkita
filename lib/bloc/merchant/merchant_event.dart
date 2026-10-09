/// Event MerchantBloc (dashboard toko + redeem voucher).
sealed class MerchantEvent {
  const MerchantEvent();
}

/// Muat dashboard merchant (cache-first, sekali saja).
class MerchantLoaded extends MerchantEvent {
  const MerchantLoaded();
}

/// Muat ulang paksa dari backend (pull-to-refresh / retry).
class MerchantRefreshed extends MerchantEvent {
  const MerchantRefreshed();
}

/// Toggle Buka/Tutup toko via PATCH /merchant/status.
class MerchantStatusToggled extends MerchantEvent {
  const MerchantStatusToggled(this.isOpen);

  final bool isOpen;
}

/// Verifikasi voucher warga via POST /vouchers/redeem.
/// [uniqueCode] = hasil scan QR atau input manual (format asli KBK-XXX-XXX).
class MerchantRedeemSubmitted extends MerchantEvent {
  const MerchantRedeemSubmitted(this.uniqueCode);

  final String uniqueCode;
}

/// Reset status redeem setelah bottom sheet sukses ditutup.
class MerchantRedeemReset extends MerchantEvent {
  const MerchantRedeemReset();
}

/// Muat halaman riwayat pencairan dana. [loadMore] true = append halaman
/// berikutnya; false = reset ke halaman 1 dengan filter [status].
class MerchantDisbursementsLoaded extends MerchantEvent {
  const MerchantDisbursementsLoaded({
    this.status = 'all',
    this.loadMore = false,
  });

  final String status;
  final bool loadMore;
}
