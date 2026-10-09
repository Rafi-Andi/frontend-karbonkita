import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/auth_exception.dart';
import '../../core/network/voucher_exception.dart';
import '../../data/repositories/profile_repository.dart';
import 'activity_event.dart';
import 'activity_state.dart';

/// BLoC aktivitas terbaru profil: `GET /api/user/activities`. Cache-first.
class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  ActivityBloc(this._repository) : super(const ActivityState()) {
    on<ActivityLoaded>(_onLoaded);
    on<ActivityRefreshed>(_onRefreshed);
  }

  final ProfileRepository _repository;

  Future<void> _onLoaded(
    ActivityLoaded event,
    Emitter<ActivityState> emit,
  ) async {
    if (state.status == ActivityStatus.loaded) return;
    try {
      final cached = await _repository.getCachedActivities();
      if (cached.items.isNotEmpty) {
        emit(
          state.copyWith(
            status: ActivityStatus.loaded,
            items: cached.items,
            isOffline: true,
            lastUpdated: cached.savedAt,
          ),
        );
      }
    } catch (_) {}
    if (state.items.isNotEmpty) {
      await _load(emit, silent: true);
      return;
    }
    await _load(emit);
  }

  Future<void> _onRefreshed(
    ActivityRefreshed event,
    Emitter<ActivityState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _load(Emitter<ActivityState> emit, {bool silent = false}) async {
    final hasCache = state.items.isNotEmpty;
    if (!silent && !hasCache) {
      emit(
        state.copyWith(
          status: ActivityStatus.loading,
          errorMessage: null,
          isUnauthorized: false,
        ),
      );
    }
    try {
      final items = await _repository.getActivities();
      emit(
        state.copyWith(
          status: ActivityStatus.loaded,
          items: items,
          isOffline: false,
          lastUpdated: DateTime.now(),
        ),
      );
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          status: hasCache ? ActivityStatus.loaded : ActivityStatus.error,
          errorMessage: e.message,
          isOffline: hasCache ? true : state.isOffline,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          status: hasCache ? ActivityStatus.loaded : ActivityStatus.error,
          errorMessage: e.message,
          isOffline: hasCache ? true : state.isOffline,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: hasCache ? ActivityStatus.loaded : ActivityStatus.error,
          errorMessage: 'Terjadi kesalahan: $e',
          isOffline: hasCache ? true : state.isOffline,
        ),
      );
    }
  }
}
