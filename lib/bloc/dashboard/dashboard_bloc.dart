import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/auth_exception.dart';
import '../../core/network/voucher_exception.dart';
import '../../data/repositories/voucher_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

/// BLoC khusus Beranda: 1 call `GET /user/dashboard` untuk
/// profil (level/XP/poin/streak), misi harian, dan preview peringkat.
///
/// Cache-first: tampilkan Hive instan, lalu refresh diam-diam saat online.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._repository) : super(const DashboardState()) {
    on<DashboardLoaded>(_onLoaded);
    on<DashboardRefreshed>(_onRefreshed);
  }

  final VoucherRepository _repository;

  Future<void> _onLoaded(
    DashboardLoaded event,
    Emitter<DashboardState> emit,
  ) async {
    // Sudah tampil (online/offline) → jangan timpa saat tab dibuka ulang.
    if (state.status == DashboardStatus.loaded) return;
    await _load(emit, showCacheFirst: true);
  }

  Future<void> _onRefreshed(
    DashboardRefreshed event,
    Emitter<DashboardState> emit,
  ) async {
    await _load(emit, showCacheFirst: false);
  }

  Future<void> _load(
    Emitter<DashboardState> emit, {
    required bool showCacheFirst,
  }) async {
    if (showCacheFirst) {
      try {
        final cached = await _repository.getCachedDashboard();
        if (cached.dashboard != null) {
          emit(
            state.copyWith(
              status: DashboardStatus.loaded,
              dashboard: cached.dashboard,
              isOffline: true,
              lastUpdated: cached.savedAt,
            ),
          );
        }
      } catch (_) {}
    }

    final hasData = state.dashboard != null;
    if (!hasData) {
      emit(
        state.copyWith(
          status: DashboardStatus.loading,
          errorMessage: null,
          isUnauthorized: false,
        ),
      );
    }
    try {
      final dashboard = await _repository.getDashboard();
      final savedAt = DateTime.now();
      emit(
        state.copyWith(
          status: DashboardStatus.loaded,
          dashboard: dashboard,
          isOffline: false,
          lastUpdated: savedAt,
        ),
      );
    } on AuthException catch (e) {
      // Dio melempar AuthException langsung (belum dibungkus repository).
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      if (hasData || state.dashboard != null) {
        // Offline tapi cache tersedia → tetap tampil, tandai offline.
        emit(state.copyWith(status: DashboardStatus.loaded, isOffline: true));
        return;
      }
      emit(
        state.copyWith(status: DashboardStatus.error, errorMessage: e.message),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      if (hasData || state.dashboard != null) {
        emit(state.copyWith(status: DashboardStatus.loaded, isOffline: true));
        return;
      }
      emit(
        state.copyWith(status: DashboardStatus.error, errorMessage: e.message),
      );
    } catch (e) {
      if (hasData || state.dashboard != null) {
        emit(state.copyWith(status: DashboardStatus.loaded, isOffline: true));
        return;
      }
      emit(
        state.copyWith(
          status: DashboardStatus.error,
          errorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }
}
