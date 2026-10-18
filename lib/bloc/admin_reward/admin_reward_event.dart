/// Event AdminRewardBloc (kelola reward marketplace).
sealed class AdminRewardEvent {
  const AdminRewardEvent();
}

/// Muat semua reward (termasuk nonaktif & kedaluwarsa) untuk admin.
class AdminRewardsLoaded extends AdminRewardEvent {
  const AdminRewardsLoaded();
}

/// Filter tampilan daftar: null = semua, 'active', 'inactive', 'expired'.
class AdminRewardsFiltered extends AdminRewardEvent {
  const AdminRewardsFiltered(this.filter);

  final String? filter;
}

/// Aktif/nonaktifkan reward (nonaktif = klaim baru berhenti).
class AdminRewardStatusSubmitted extends AdminRewardEvent {
  const AdminRewardStatusSubmitted({required this.id, required this.isActive});

  final int id;
  final bool isActive;
}

/// Ubah tenggat reward. Stok tidak bisa diubah dari sini — terikat
/// alokasi dana campaign (backend menolak payload stok).
class AdminRewardUpdateSubmitted extends AdminRewardEvent {
  const AdminRewardUpdateSubmitted({required this.id, required this.expiredAt});

  final int id;

  /// Format Y-m-d.
  final String expiredAt;
}

/// Muat halaman pertama daftar penukar satu reward.
class AdminRewardClaimsLoaded extends AdminRewardEvent {
  const AdminRewardClaimsLoaded(this.rewardId);

  final int rewardId;
}

/// Muat halaman berikutnya dari daftar penukar ("Muat lebih banyak").
class AdminRewardClaimsNextPage extends AdminRewardEvent {
  const AdminRewardClaimsNextPage();
}

/// Reset status submit setelah snackbar/sheet tampil.
class AdminRewardSubmitReset extends AdminRewardEvent {
  const AdminRewardSubmitReset();
}
