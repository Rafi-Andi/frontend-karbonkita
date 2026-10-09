import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/auth_exception.dart';
import '../../core/network/voucher_exception.dart';
import '../../data/repositories/leaderboard_repository.dart';
import '../../models/leaderboard.dart';
import 'leaderboard_event.dart';
import 'leaderboard_state.dart';

/// BLoC papan peringkat: `GET /leaderboard?scope=&timeframe=`.
/// Data lama dipertahankan saat ganti tab agar layar tidak blank.
/// Cache-first Hive: kombinasi yang pernah dibuka langsung tampil offline.
class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  LeaderboardBloc(this._repository) : super(const LeaderboardState()) {
    on<LeaderboardLoaded>(_onLoaded);
    on<LeaderboardRefreshed>(_onRefreshed);
  }

  final LeaderboardRepository _repository;

  Future<void> _onLoaded(
    LeaderboardLoaded event,
    Emitter<LeaderboardState> emit,
  ) async {
    // Kombinasi sama + sudah ada data memory -> tidak perlu hit ulang.
    if (state.status == LeaderboardStatus.loaded &&
        state.scope == event.scope &&
        state.timeframe == event.timeframe &&
        state.board != null) {
      return;
    }
    // Coba cache Hive dulu agar instan saat offline / buka ulang.
    try {
      final cached = await _repository.getCachedLeaderboard(
        scope: event.scope,
        timeframe: event.timeframe,
      );
      if (cached.board != null) {
        emit(
          state.copyWith(
            status: LeaderboardStatus.loaded,
            scope: event.scope,
            timeframe: event.timeframe,
            board: cached.board,
            isOffline: true,
            lastUpdated: cached.savedAt,
          ),
        );
      }
    } catch (_) {}
    // Jika cache Hive sudah menutup kombinasi ini, tetap refresh diam-diam.
    if (state.board != null &&
        state.scope == event.scope &&
        state.timeframe == event.timeframe &&
        state.status == LeaderboardStatus.loaded) {
      // Lanjut ke _load untuk refresh background (tanpa loading penuh).
      await _load(emit, event.scope, event.timeframe);
      return;
    }
    await _load(emit, event.scope, event.timeframe);
  }

  Future<void> _onRefreshed(
    LeaderboardRefreshed event,
    Emitter<LeaderboardState> emit,
  ) async {
    await _load(emit, state.scope, state.timeframe);
  }

  Future<void> _load(
    Emitter<LeaderboardState> emit,
    LeaderboardScope scope,
    LeaderboardTimeframe timeframe,
  ) async {
    final hasCache = state.board != null;
    if (!hasCache) {
      emit(
        state.copyWith(
          status: LeaderboardStatus.loading,
          scope: scope,
          timeframe: timeframe,
          errorMessage: null,
          isUnauthorized: false,
        ),
      );
    } else {
      emit(
        state.copyWith(
          scope: scope,
          timeframe: timeframe,
          errorMessage: null,
          isUnauthorized: false,
        ),
      );
    }
    try {
      final board = await _repository.getLeaderboard(
        scope: scope,
        timeframe: timeframe,
      );
      emit(
        state.copyWith(
          status: LeaderboardStatus.loaded,
          board: board,
          isOffline: false,
          lastUpdated: DateTime.now(),
        ),
      );
    } on AuthException catch (e) {
      // Dio melempar AuthException langsung (belum dibungkus repository).
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          // Tetap tampilkan cache lama bila refresh gagal.
          status: hasCache ? LeaderboardStatus.loaded : LeaderboardStatus.error,
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
          status: hasCache ? LeaderboardStatus.loaded : LeaderboardStatus.error,
          errorMessage: e.message,
          isOffline: hasCache ? true : state.isOffline,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: hasCache ? LeaderboardStatus.loaded : LeaderboardStatus.error,
          errorMessage: 'Terjadi kesalahan: $e',
          isOffline: hasCache ? true : state.isOffline,
        ),
      );
    }
  }
}
