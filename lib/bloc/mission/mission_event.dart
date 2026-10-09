/// Event MissionBloc.
sealed class MissionEvent {
  const MissionEvent();
}

/// Muat misi aktif (mobility & waste) dari backend.
/// [force] = true melewati cache memori agar status harian refresh
/// (dipakai setelah misi selesai).
class MissionsLoaded extends MissionEvent {
  const MissionsLoaded({this.force = false});

  final bool force;
}

/// Muat kuis harian (Saga Map) dari backend.
class QuizzesLoaded extends MissionEvent {
  const QuizzesLoaded();
}

/// Filter misi berdasarkan kategori.
class MissionsFiltered extends MissionEvent {
  const MissionsFiltered(this.category);

  final String? category; // null = 'Semua', 'mobility', 'waste'
}

/// Sinkronisasi aktivitas mobilitas.
class MobilitySynced extends MissionEvent {
  const MobilitySynced({
    this.missionId,
    required this.activityType,
    required this.distanceKm,
    required this.durationSeconds,
    required this.gpsCoordinatesPath,
  });

  final int? missionId;
  final String activityType;
  final double distanceKm;
  final int durationSeconds;
  final List<Map<String, double>> gpsCoordinatesPath;
}

/// Reset status sync mobilitas ke initial (dipakai setelah result sheet ditutup).
class MobilitySyncReset extends MissionEvent {
  const MobilitySyncReset();
}

/// Submit jawaban kuis.
class QuizAnswerSubmitted extends MissionEvent {
  const QuizAnswerSubmitted({required this.quizId, required this.answer});

  final int quizId;
  final String answer;
}

/// Upload foto sampah untuk validasi AI Gemini (backend).
class WasteVerifyRequested extends MissionEvent {
  const WasteVerifyRequested({
    required this.missionId,
    required this.imagePath,
  });

  final int missionId;
  final String imagePath;
}

/// Reset status verifikasi sampah ke initial (dipakai setelah sheet ditutup).
class WasteVerifyReset extends MissionEvent {
  const WasteVerifyReset();
}
