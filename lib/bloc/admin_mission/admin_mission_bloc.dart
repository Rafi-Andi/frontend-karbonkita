import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/auth_exception.dart';
import '../../core/network/mission_exception.dart';
import '../../data/repositories/admin_mission_repository.dart';
import 'admin_mission_event.dart';
import 'admin_mission_state.dart';

/// BLoC kelola misi mobility & waste (role:admin).
///
/// - `AdminMissionsLoaded`: daftar semua status (tanpa cache).
/// - `AdminMissionCreateSubmitted` / `Update` / `Status`: submit,
///   sukses → muat ulang daftar; 422 → error per-field untuk sheet rincian.
class AdminMissionBloc extends Bloc<AdminMissionEvent, AdminMissionState> {
  AdminMissionBloc(this._repository) : super(const AdminMissionState()) {
    on<AdminMissionsLoaded>(_onLoaded);
    on<AdminMissionsFiltered>(_onFiltered);
    on<AdminMissionCreateSubmitted>(_onCreateSubmitted);
    on<AdminMissionUpdateSubmitted>(_onUpdateSubmitted);
    on<AdminMissionStatusSubmitted>(_onStatusSubmitted);
    on<AdminMissionSubmitReset>(_onSubmitReset);
  }

  final AdminMissionRepository _repository;

  Future<void> _onLoaded(
    AdminMissionsLoaded event,
    Emitter<AdminMissionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdminMissionStatus.loading,
        errorMessage: null,
        isUnauthorized: false,
      ),
    );
    try {
      final missions = await _repository.getAdminMissions();
      emit(
        state.copyWith(status: AdminMissionStatus.loaded, missions: missions),
      );
    } on AuthException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        emit(
          state.copyWith(
            status: AdminMissionStatus.loaded,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: AdminMissionStatus.error,
          errorMessage: e.message,
        ),
      );
    } on MissionException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        emit(
          state.copyWith(
            status: AdminMissionStatus.loaded,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: AdminMissionStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdminMissionStatus.error,
          errorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  void _onFiltered(
    AdminMissionsFiltered event,
    Emitter<AdminMissionState> emit,
  ) {
    emit(
      state.copyWith(
        filter: event.category,
        clearFilter: event.category == null,
      ),
    );
  }

  Future<void> _onCreateSubmitted(
    AdminMissionCreateSubmitted event,
    Emitter<AdminMissionState> emit,
  ) async {
    await _submit(
      emit,
      () => _repository.createMission(event.fields),
      onOk: (data) => state.copyWith(
        submitStatus: AdminMissionSubmitStatus.success,
        lastMission: data,
      ),
    );
  }

  Future<void> _onUpdateSubmitted(
    AdminMissionUpdateSubmitted event,
    Emitter<AdminMissionState> emit,
  ) async {
    await _submit(
      emit,
      () => _repository.updateMission(event.id, event.fields),
      onOk: (data) => state.copyWith(
        submitStatus: AdminMissionSubmitStatus.success,
        lastMission: data,
      ),
    );
  }

  Future<void> _onStatusSubmitted(
    AdminMissionStatusSubmitted event,
    Emitter<AdminMissionState> emit,
  ) async {
    await _submit(
      emit,
      () => _repository.setMissionStatus(event.id, event.isActive),
      onOk: (data) => state.copyWith(
        submitStatus: AdminMissionSubmitStatus.success,
        lastMission: data,
      ),
    );
  }

  Future<void> _submit(
    Emitter<AdminMissionState> emit,
    Future<Map<String, dynamic>> Function() call, {
    required AdminMissionState Function(Map<String, dynamic>) onOk,
  }) async {
    if (state.submitStatus == AdminMissionSubmitStatus.submitting) return;
    emit(
      state.copyWith(
        submitStatus: AdminMissionSubmitStatus.submitting,
        clearSubmit: true,
        isUnauthorized: false,
      ),
    );
    try {
      final data = await call();
      emit(onOk(data));
      add(const AdminMissionsLoaded());
    } on AuthException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        emit(
          state.copyWith(
            submitStatus: AdminMissionSubmitStatus.idle,
            clearSubmit: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          submitStatus: AdminMissionSubmitStatus.failure,
          submitErrorMessage: e.message,
          submitErrors: e.errors,
        ),
      );
    } on MissionException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        emit(
          state.copyWith(
            submitStatus: AdminMissionSubmitStatus.idle,
            clearSubmit: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          submitStatus: AdminMissionSubmitStatus.failure,
          submitErrorMessage: e.message,
          submitErrors: e.errors,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          submitStatus: AdminMissionSubmitStatus.failure,
          submitErrorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  void _onSubmitReset(
    AdminMissionSubmitReset event,
    Emitter<AdminMissionState> emit,
  ) {
    emit(
      state.copyWith(
        submitStatus: AdminMissionSubmitStatus.idle,
        clearSubmit: true,
      ),
    );
  }
}
