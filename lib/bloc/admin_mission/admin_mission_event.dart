/// Event AdminMissionBloc (kelola misi mobility & waste).
sealed class AdminMissionEvent {
  const AdminMissionEvent();
}

/// Muat semua misi (semua status) untuk admin.
class AdminMissionsLoaded extends AdminMissionEvent {
  const AdminMissionsLoaded();
}

/// Filter daftar tampil per kategori (null = semua).
class AdminMissionsFiltered extends AdminMissionEvent {
  const AdminMissionsFiltered(this.category);

  final String? category;
}

/// Submit form tambah misi.
class AdminMissionCreateSubmitted extends AdminMissionEvent {
  const AdminMissionCreateSubmitted(this.fields);

  final Map<String, dynamic> fields;
}

/// Submit form ubah misi.
class AdminMissionUpdateSubmitted extends AdminMissionEvent {
  const AdminMissionUpdateSubmitted({required this.id, required this.fields});

  final int id;
  final Map<String, dynamic> fields;
}

/// Aktif/nonaktif misi.
class AdminMissionStatusSubmitted extends AdminMissionEvent {
  const AdminMissionStatusSubmitted({required this.id, required this.isActive});

  final int id;
  final bool isActive;
}

/// Reset status submit setelah snackbar/sheet tampil.
class AdminMissionSubmitReset extends AdminMissionEvent {
  const AdminMissionSubmitReset();
}
