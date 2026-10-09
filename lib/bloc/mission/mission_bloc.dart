import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/mission_exception.dart';
import '../../data/repositories/mission_repository.dart';
import 'mission_event.dart';
import 'mission_state.dart';

/// Cache-first: tampilkan misi tersimpan instan, refresh diam-diam.
class MissionBloc extends Bloc<MissionEvent, MissionState> {
  MissionBloc(this._repository) : super(const MissionState()) {
    on<MissionsLoaded>(_onMissionsLoaded);
    on<QuizzesLoaded>(_onQuizzesLoaded);
    on<MissionsFiltered>(_onMissionsFiltered);
    on<MobilitySynced>(_onMobilitySynced);
    on<MobilitySyncReset>(_onMobilitySyncReset);
    on<QuizAnswerSubmitted>(_onQuizAnswerSubmitted);
    on<WasteVerifyRequested>(_onWasteVerifyRequested);
    on<WasteVerifyReset>(_onWasteVerifyReset);
  }

  final MissionRepository _repository;

  Future<void> _onMissionsLoaded(
    MissionsLoaded event,
    Emitter<MissionState> emit,
  ) async {
    // Cache memory sesi masih dianggap tampil — tapi pastikan juga
    // cache Hive dimuat saat app baru dibuka (missions kosong).
    // force=true (setelah misi selesai) melewati short-circuit ini.
    if (!event.force &&
        state.status == MissionStatus.loaded &&
        state.missions.isNotEmpty) {
      return;
    }
    try {
      final cached = await _repository.getCachedActiveMissions();
      if (cached.missions.isNotEmpty) {
        final filtered = state.currentFilter != null
            ? cached.missions
                  .where((m) => m.category == state.currentFilter)
                  .toList()
            : cached.missions;
        emit(
          state.copyWith(
            status: MissionStatus.loaded,
            missions: cached.missions,
            filteredMissions: filtered,
            isOffline: true,
            lastUpdated: cached.savedAt,
          ),
        );
      }
    } catch (_) {}

    if (state.missions.isEmpty) {
      emit(state.copyWith(status: MissionStatus.loading, errorMessage: null));
    }
    try {
      final missions = await _repository.getActiveMissions();
      final filtered = state.currentFilter != null
          ? missions.where((m) => m.category == state.currentFilter).toList()
          : missions;
      emit(
        state.copyWith(
          status: MissionStatus.loaded,
          missions: missions,
          filteredMissions: filtered,
          isOffline: false,
          lastUpdated: DateTime.now(),
        ),
      );
    } on MissionException catch (e) {
      if (state.missions.isNotEmpty) {
        emit(state.copyWith(status: MissionStatus.loaded, isOffline: true));
        return;
      }
      emit(
        state.copyWith(status: MissionStatus.error, errorMessage: e.message),
      );
    } catch (e) {
      if (state.missions.isNotEmpty) {
        emit(state.copyWith(status: MissionStatus.loaded, isOffline: true));
        return;
      }
      emit(
        state.copyWith(
          status: MissionStatus.error,
          errorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _onQuizzesLoaded(
    QuizzesLoaded event,
    Emitter<MissionState> emit,
  ) async {
    if (state.quizzes.isNotEmpty && state.status == MissionStatus.loaded) {
      return;
    }
    try {
      final cached = await _repository.getCachedSagaQuizzes();
      if (cached.isNotEmpty) {
        emit(
          state.copyWith(
            status: MissionStatus.loaded,
            quizzes: cached,
            filteredMissions: state.getFiltered(state.currentFilter),
            isOffline: true,
          ),
        );
      }
    } catch (_) {}

    if (state.quizzes.isEmpty && state.missions.isEmpty) {
      emit(state.copyWith(status: MissionStatus.loading, errorMessage: null));
    }
    try {
      final quizzes = await _repository.getSagaQuizzes();
      // Kuis tidak ditampilkan di halaman misi (hanya lewat FAB),
      // jadi daftar filter selalu dihitung dari misi non-kuis saja.
      final filtered = state.getFiltered(state.currentFilter);
      emit(
        state.copyWith(
          status: MissionStatus.loaded,
          quizzes: quizzes,
          filteredMissions: filtered,
          isOffline: false,
          lastUpdated: DateTime.now(),
        ),
      );
    } on MissionException catch (e) {
      if (state.missions.isNotEmpty || state.quizzes.isNotEmpty) {
        emit(state.copyWith(status: MissionStatus.loaded, isOffline: true));
        return;
      }
      emit(
        state.copyWith(status: MissionStatus.error, errorMessage: e.message),
      );
    } catch (e) {
      if (state.missions.isNotEmpty || state.quizzes.isNotEmpty) {
        emit(state.copyWith(status: MissionStatus.loaded, isOffline: true));
        return;
      }
      emit(
        state.copyWith(
          status: MissionStatus.error,
          errorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _onMissionsFiltered(
    MissionsFiltered event,
    Emitter<MissionState> emit,
  ) async {
    final filtered = event.category != null
        ? state.getFiltered(event.category)
        : state.allMissions;
    emit(
      state.copyWith(currentFilter: event.category, filteredMissions: filtered),
    );
  }

  Future<void> _onMobilitySynced(
    MobilitySynced event,
    Emitter<MissionState> emit,
  ) async {
    emit(
      state.copyWith(
        mobilityStatus: MobilitySyncStatus.syncing,
        mobilityErrorMessage: null,
      ),
    );
    try {
      final envelope = await _repository.syncMobility(
        missionId: event.missionId,
        activityType: event.activityType,
        distanceKm: event.distanceKm,
        durationSeconds: event.durationSeconds,
        gpsCoordinatesPath: event.gpsCoordinatesPath,
      );
      final data = envelope['data'];
      emit(
        state.copyWith(
          mobilityStatus: MobilitySyncStatus.success,
          mobilityResult: data is Map<String, dynamic>
              ? data
              : <String, dynamic>{'raw': data},
          mobilityErrorMessage: null,
        ),
      );
    } on MissionException catch (e) {
      emit(
        state.copyWith(
          mobilityStatus: MobilitySyncStatus.failure,
          mobilityErrorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          mobilityStatus: MobilitySyncStatus.failure,
          mobilityErrorMessage: 'Gagal sinkronisasi: $e',
        ),
      );
    }
  }

  void _onMobilitySyncReset(
    MobilitySyncReset event,
    Emitter<MissionState> emit,
  ) {
    emit(
      state.copyWith(
        mobilityStatus: MobilitySyncStatus.initial,
        mobilityResult: null,
        mobilityErrorMessage: null,
      ),
    );
  }

  Future<void> _onQuizAnswerSubmitted(
    QuizAnswerSubmitted event,
    Emitter<MissionState> emit,
  ) async {
    try {
      await _repository.submitQuizAnswer(
        quizId: event.quizId,
        answer: event.answer,
      );
      // Success - bisa emit event tambahan jika perlu refresh data
    } on MissionException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
      rethrow;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Gagal submit jawaban: $e'));
      rethrow;
    }
  }

  Future<void> _onWasteVerifyRequested(
    WasteVerifyRequested event,
    Emitter<MissionState> emit,
  ) async {
    emit(
      state.copyWith(
        wasteVerifyStatus: WasteVerifyStatus.uploading,
        wasteVerifyErrorMessage: null,
        wasteVerifyData: null,
      ),
    );
    try {
      final result = await _repository.verifyWaste(
        missionId: event.missionId,
        imagePath: event.imagePath,
      );
      if (result.verified) {
        emit(
          state.copyWith(
            wasteVerifyStatus: WasteVerifyStatus.verified,
            verifyResult: result,
            wasteVerifyErrorMessage: null,
          ),
        );
        // Refresh kunci harian agar kartu misi terkunci seperti mobility.
        add(const MissionsLoaded(force: true));
      } else if (result.status == 'rejected') {
        emit(
          state.copyWith(
            wasteVerifyStatus: WasteVerifyStatus.rejected,
            verifyResult: result,
            wasteVerifyErrorMessage: null,
          ),
        );
      } else {
        emit(
          state.copyWith(
            wasteVerifyStatus: WasteVerifyStatus.pendingReview,
            verifyResult: result,
            wasteVerifyErrorMessage: null,
          ),
        );
      }
    } on MissionException catch (e) {
      if (e.statusCode == 409) {
        // Backend bedakan via data: {already_completed_today: true}
        // = daily-cap, selain itu = foto duplikat (anti-fraud).
        final alreadyCapped = e.data?['already_completed_today'] == true;
        emit(
          state.copyWith(
            wasteVerifyStatus: alreadyCapped
                ? WasteVerifyStatus.dailyCapped
                : WasteVerifyStatus.duplicate,
            wasteVerifyErrorMessage: e.message,
            wasteVerifyData: e.data,
          ),
        );
        return;
      }
      if (e.statusCode == 503) {
        emit(
          state.copyWith(
            wasteVerifyStatus: WasteVerifyStatus.pendingReview,
            wasteVerifyErrorMessage: e.message,
            wasteVerifyData: e.data,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          wasteVerifyStatus: WasteVerifyStatus.failure,
          wasteVerifyErrorMessage: e.message,
          wasteVerifyData: e.data,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          wasteVerifyStatus: WasteVerifyStatus.failure,
          wasteVerifyErrorMessage: 'Gagal verifikasi: $e',
        ),
      );
    }
  }

  void _onWasteVerifyReset(WasteVerifyReset event, Emitter<MissionState> emit) {
    emit(
      state.copyWith(
        wasteVerifyStatus: WasteVerifyStatus.initial,
        verifyResult: null,
        wasteVerifyErrorMessage: null,
        wasteVerifyData: null,
      ),
    );
  }
}
