/// Event AdminCampaignBloc (kelola campaign + voucher pendanaan).
sealed class AdminCampaignEvent {
  const AdminCampaignEvent();
}

/// Muat semua campaign (semua status) untuk admin.
class AdminCampaignsLoaded extends AdminCampaignEvent {
  const AdminCampaignsLoaded();
}

/// Buat campaign baru (draft/active).
class AdminCampaignCreateSubmitted extends AdminCampaignEvent {
  const AdminCampaignCreateSubmitted(this.fields);

  final Map<String, dynamic> fields;
}

/// Ubah campaign (status/target/jadwal).
class AdminCampaignUpdateSubmitted extends AdminCampaignEvent {
  const AdminCampaignUpdateSubmitted({required this.id, required this.fields});

  final int id;
  final Map<String, dynamic> fields;
}

/// Buat voucher didanai campaign. Gagal bila dana kurang / mitra belum ok.
class AdminVoucherCreateSubmitted extends AdminCampaignEvent {
  const AdminVoucherCreateSubmitted(this.fields);

  final Map<String, dynamic> fields;
}

/// Reset status submit setelah dialog/snackbar ditutup.
class AdminCampaignSubmitReset extends AdminCampaignEvent {
  const AdminCampaignSubmitReset();
}
