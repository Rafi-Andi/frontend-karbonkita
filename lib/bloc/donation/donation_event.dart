/// Event DonationBloc (sisi warga/donatur).
sealed class DonationEvent {
  const DonationEvent();
}

/// Muat katalog campaign terbuka (publik).
/// [force]=true melewati cache state (pull-to-refresh / kembali dari detail).
class DonationCampaignsLoaded extends DonationEvent {
  const DonationCampaignsLoaded({this.force = false});

  final bool force;
}

/// Muat detail 1 campaign + leaderboard donatur.
class DonationDetailLoaded extends DonationEvent {
  const DonationDetailLoaded(this.slug);

  final String slug;
}

/// Buat donasi → invoice Xendit (dibayar di browser).
class DonationCreateSubmitted extends DonationEvent {
  const DonationCreateSubmitted({
    required this.campaignId,
    required this.amount,
    this.payerName,
  });

  final int campaignId;
  final int amount;
  final String? payerName;
}

/// Reset status create setelah invoice dibuka/ditutup.
class DonationCreateReset extends DonationEvent {
  const DonationCreateReset();
}

/// Muat riwayat donasi sendiri + tier.
class MyDonationsLoaded extends DonationEvent {
  const MyDonationsLoaded({this.force = false});

  final bool force;
}

/// Batalkan donasi pending (jadi expired).
class DonationCancelSubmitted extends DonationEvent {
  const DonationCancelSubmitted(this.id);

  final int id;
}
