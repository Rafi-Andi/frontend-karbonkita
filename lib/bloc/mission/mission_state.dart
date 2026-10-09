import '../../models/mission.dart';
import '../../models/verify_waste_result.dart';

/// Status muat misi.
enum MissionStatus { initial, loading, loaded, error }

/// Status sinkronisasi mobilitas (terpisah dari status daftar misi).
enum MobilitySyncStatus { initial, syncing, success, failure }

/// Status verifikasi sampah via AI (terpisah dari status daftar misi).
enum WasteVerifyStatus {
  initial,
  uploading,
  verified,
  rejected,
  duplicate,
  dailyCapped,
  pendingReview,
  failure,
}

class MissionState {
  const MissionState({
    this.status = MissionStatus.initial,
    this.missions = const [],
    this.quizzes = const [],
    this.filteredMissions = const [],
    this.currentFilter,
    this.errorMessage,
    this.isOffline = false,
    this.lastUpdated,
    this.mobilityStatus = MobilitySyncStatus.initial,
    this.mobilityResult,
    this.mobilityErrorMessage,
    this.wasteVerifyStatus = WasteVerifyStatus.initial,
    this.verifyResult,
    this.wasteVerifyErrorMessage,
    this.wasteVerifyData,
  });

  final MissionStatus status;
  final List<Mission> missions; // Semua misi aktif (mobility + waste)
  final List<Mission> quizzes; // Kuis harian dari Saga
  final List<Mission> filteredMissions; // Hasil filter
  final String? currentFilter; // null = Semua, 'mobility', 'waste'
  final String? errorMessage;

  /// True bila data berasal dari cache offline.
  final bool isOffline;
  final DateTime? lastUpdated;

  /// Hasil sync mobilitas terakhir (isi `data` dari envelope backend).
  final MobilitySyncStatus mobilityStatus;
  final Map<String, dynamic>? mobilityResult;
  final String? mobilityErrorMessage;

  /// Hasil verifikasi sampah terakhir (isi `data` envelope 200/201).
  final WasteVerifyStatus wasteVerifyStatus;
  final VerifyWasteResult? verifyResult;
  final String? wasteVerifyErrorMessage;

  /// Payload `data` mentah untuk kasus error 409/503 (berisi
  /// user_mission_id / already_completed_today dari backend).
  final Map<String, dynamic>? wasteVerifyData;

  /// Semua misi non-kuis (untuk tab 'Semua'). Kuis hanya lewat FAB.
  List<Mission> get allMissions => missions;

  // Sentinel agar copyWith bisa me-reset currentFilter ke null (tab 'Semua').
  // Tanpa ini, `currentFilter ?? this.currentFilter` tidak pernah bisa null
  // lagi setelah user pindah tab.
  static const _noChange = Object();

  MissionState copyWith({
    MissionStatus? status,
    List<Mission>? missions,
    List<Mission>? quizzes,
    List<Mission>? filteredMissions,
    Object? currentFilter = _noChange,
    String? errorMessage,
    bool? isOffline,
    DateTime? lastUpdated,
    MobilitySyncStatus? mobilityStatus,
    Object? mobilityResult = _noChange,
    Object? mobilityErrorMessage = _noChange,
    WasteVerifyStatus? wasteVerifyStatus,
    Object? verifyResult = _noChange,
    Object? wasteVerifyErrorMessage = _noChange,
    Object? wasteVerifyData = _noChange,
  }) {
    return MissionState(
      status: status ?? this.status,
      missions: missions ?? this.missions,
      quizzes: quizzes ?? this.quizzes,
      filteredMissions: filteredMissions ?? this.filteredMissions,
      currentFilter: currentFilter == _noChange
          ? this.currentFilter
          : currentFilter as String?,
      errorMessage: errorMessage,
      isOffline: isOffline ?? this.isOffline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      mobilityStatus: mobilityStatus ?? this.mobilityStatus,
      mobilityResult: mobilityResult == _noChange
          ? this.mobilityResult
          : mobilityResult as Map<String, dynamic>?,
      mobilityErrorMessage: mobilityErrorMessage == _noChange
          ? this.mobilityErrorMessage
          : mobilityErrorMessage as String?,
      wasteVerifyStatus: wasteVerifyStatus ?? this.wasteVerifyStatus,
      verifyResult: verifyResult == _noChange
          ? this.verifyResult
          : verifyResult as VerifyWasteResult?,
      wasteVerifyErrorMessage: wasteVerifyErrorMessage == _noChange
          ? this.wasteVerifyErrorMessage
          : wasteVerifyErrorMessage as String?,
      wasteVerifyData: wasteVerifyData == _noChange
          ? this.wasteVerifyData
          : wasteVerifyData as Map<String, dynamic>?,
    );
  }

  /// Filter missions berdasarkan kategori (non-kuis saja)
  List<Mission> getFiltered(String? category) {
    if (category == null) return allMissions;
    return allMissions.where((m) => m.category == category).toList();
  }
}
