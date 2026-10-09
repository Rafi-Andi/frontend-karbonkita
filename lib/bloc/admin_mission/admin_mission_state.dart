import '../../models/mission.dart';

/// Status muat daftar misi admin.
enum AdminMissionStatus { initial, loading, loaded, error }

/// Status proses submit (create/update/toggle status).
enum AdminMissionSubmitStatus { idle, submitting, success, failure }

class AdminMissionState {
  const AdminMissionState({
    this.status = AdminMissionStatus.initial,
    this.missions = const [],
    this.filter,
    this.errorMessage,
    this.submitStatus = AdminMissionSubmitStatus.idle,
    this.lastMission,
    this.submitErrors = const {},
    this.submitErrorMessage,
    this.isUnauthorized = false,
  });

  final AdminMissionStatus status;
  final List<Mission> missions;

  /// Filter kategori tampil ('mobility' | 'waste' | null = semua).
  final String? filter;
  final String? errorMessage;

  final AdminMissionSubmitStatus submitStatus;

  /// Hasil create/update terakhir (map mentah backend).
  final Map<String, dynamic>? lastMission;

  /// Error 422 per-field dari backend (untuk bottom sheet rincian).
  final Map<String, List<String>> submitErrors;
  final String? submitErrorMessage;

  /// True bila backend 401/403 — UI harus logout / tolak akses.
  final bool isUnauthorized;

  List<Mission> get filteredMissions {
    if (filter == null) return missions;
    return missions.where((m) => m.category == filter).toList();
  }

  AdminMissionState copyWith({
    AdminMissionStatus? status,
    List<Mission>? missions,
    String? filter,
    bool clearFilter = false,
    String? errorMessage,
    AdminMissionSubmitStatus? submitStatus,
    Map<String, dynamic>? lastMission,
    Map<String, List<String>>? submitErrors,
    String? submitErrorMessage,
    bool clearSubmit = false,
    bool? isUnauthorized,
  }) {
    return AdminMissionState(
      status: status ?? this.status,
      missions: missions ?? this.missions,
      filter: clearFilter ? null : (filter ?? this.filter),
      errorMessage: errorMessage,
      submitStatus: submitStatus ?? this.submitStatus,
      lastMission: clearSubmit ? null : (lastMission ?? this.lastMission),
      submitErrors: clearSubmit
          ? const {}
          : (submitErrors ?? this.submitErrors),
      submitErrorMessage: clearSubmit ? null : submitErrorMessage,
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
    );
  }
}
