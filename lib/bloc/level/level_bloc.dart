import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/auth_exception.dart';
import '../../core/network/voucher_exception.dart';
import '../../data/repositories/profile_repository.dart';
import 'level_event.dart';
import 'level_state.dart';

/// BLoC 3 tier lencana level: `GET /api/user/levels`. Cache-first Hive.
class LevelBloc extends Bloc<LevelEvent, LevelState> {
  LevelBloc(this._repository) : super(const LevelState()) {
    on<LevelLoaded>(_onLoaded);
    on<LevelRefreshed>(_onRefreshed);
  }

  final ProfileRepository _repository;

  Future<void> _onLoaded(LevelLoaded event, Emitter<LevelState> emit) async {
    if (state.status == LevelStatus.loaded) return;
    try {
      final cached = await _repository.getCachedLevels();
      if (cached.data != null) {
        emit(
          state.copyWith(
            status: LevelStatus.loaded,
            data: cached.data,
            isOffline: true,
            lastUpdated: cached.savedAt,
          ),
        );
        // Refresh diam-diam di bawah.
      }
    } catch (_) {}
    if (state.data != null) {
      await _load(emit, silent: true);
      return;
    }
    await _load(emit);
  }

  Future<void> _onRefreshed(
    LevelRefreshed event,
    Emitter<LevelState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _load(Emitter<LevelState> emit, {bool silent = false}) async {
    final hasCache = state.data != null;
    if (!silent && !hasCache) {
      emit(
        state.copyWith(
          status: LevelStatus.loading,
          errorMessage: null,
          isUnauthorized: false,
        ),
      );
    }
    try {
      final data = await _repository.getLevels();
      emit(
        state.copyWith(
          status: LevelStatus.loaded,
          data: data,
          isOffline: false,
          lastUpdated: DateTime.now(),
        ),
      );
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      if (hasCache) {
        emit(state.copyWith(status: LevelStatus.loaded, isOffline: true));
        return;
      }
      emit(state.copyWith(status: LevelStatus.error, errorMessage: e.message));
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      if (hasCache) {
        emit(state.copyWith(status: LevelStatus.loaded, isOffline: true));
        return;
      }
      emit(state.copyWith(status: LevelStatus.error, errorMessage: e.message));
    } catch (e) {
      if (hasCache) {
        emit(state.copyWith(status: LevelStatus.loaded, isOffline: true));
        return;
      }
      emit(
        state.copyWith(
          status: LevelStatus.error,
          errorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }
}
