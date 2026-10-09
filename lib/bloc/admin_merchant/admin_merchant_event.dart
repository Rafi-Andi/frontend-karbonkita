/// Event BLoC validasi mitra admin.
sealed class AdminMerchantEvent {
  const AdminMerchantEvent();
}

/// Muat antrean per tab status (pending/verified/rejected).
class AdminMerchantsLoaded extends AdminMerchantEvent {
  const AdminMerchantsLoaded({this.status = 'pending'});

  final String status;
}

/// Ubah kata kunci pencarian (filter client-side di halaman aktif —
/// backend belum menyediakan `?search=`).
class AdminMerchantSearchChanged extends AdminMerchantEvent {
  const AdminMerchantSearchChanged(this.query);

  final String query;
}

/// Muat detail 1 pengajuan untuk kartu validasi.
class AdminMerchantDetailLoaded extends AdminMerchantEvent {
  const AdminMerchantDetailLoaded(this.id);

  final int id;
}

/// Approve (reason opsional) / reject (reason wajib) pengajuan.
class AdminMerchantVerifySubmitted extends AdminMerchantEvent {
  const AdminMerchantVerifySubmitted({
    required this.id,
    required this.approve,
    this.reason,
  });

  final int id;
  final bool approve;
  final String? reason;
}

/// Reset status verify setelah dialog/snackbar ditutup.
class AdminMerchantVerifyReset extends AdminMerchantEvent {
  const AdminMerchantVerifyReset();
}
