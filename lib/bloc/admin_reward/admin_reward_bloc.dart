import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/auth_exception.dart';
import '../../core/network/voucher_exception.dart';
import '../../data/repositories/admin_reward_repository.dart';
import '../../models/admin_reward.dart';
import 'admin_reward_event.dart';
import 'admin_reward_state.dart';

/// BLoC kelola reward/voucher marketplace (role:admin).
///
/// - `AdminRewardsLoaded`: daftar semua reward (tanpa cache).
/// - `AdminRewardStatusSubmitted` + `AdminRewardUpdateSubmitted`: sukses →
///   muat ulang daftar; 422 → `submitErrors` per-field untuk sheet rincian.
/// - `AdminRewardClaimsLoaded` / `AdminRewardClaimsNextPage`: daftar penukar
///   satu reward dengan paginasi "Muat lebih banyak".
class AdminRewardBloc extends Bloc<AdminRewardEvent, AdminRewardState> {
  AdminRewardBloc(this._repository) : super(const AdminRewardState()) {
    on<AdminRewardsLoaded>(_onLoaded);
    on<AdminRewardsFiltered>(_onFiltered);
    on<AdminRewardStatusSubmitted>(_onStatusSubmitted);
    on<AdminRewardUpdateSubmitted>(_onUpdateSubmitted);
    on<AdminRewardClaimsLoaded>(_onClaimsLoaded);
    on<AdminRewardClaimsNextPage>(_onClaimsNextPage);
    on<AdminRewardSubmitReset>(_onSubmitReset);
  }

  final AdminRewardRepository _repository;

  Future<void> _onLoaded(
    AdminRewardsLoaded event,
    Emitter<AdminRewardState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdminRewardStatus.loading,
        errorMessage: null,
        isUnauthorized: false,
      ),
    );
    try {
      final rewards = await _repository.getRewards();
      emit(state.copyWith(status: AdminRewardStatus.loaded, rewards: rewards));
    } on AuthException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        emit(
          state.copyWith(
            status: AdminRewardStatus.loaded,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: AdminRewardStatus.error,
          errorMessage: e.message,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        emit(
          state.copyWith(
            status: AdminRewardStatus.loaded,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: AdminRewardStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdminRewardStatus.error,
          errorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  void _onFiltered(AdminRewardsFiltered event, Emitter<AdminRewardState> emit) {
    emit(
      state.copyWith(filter: event.filter, clearFilter: event.filter == null),
    );
  }

  Future<void> _onStatusSubmitted(
    AdminRewardStatusSubmitted event,
    Emitter<AdminRewardState> emit,
  ) async {
    await _submit(
      emit,
      () => _repository.setRewardStatus(event.id, event.isActive),
      successMessage: event.isActive
          ? 'Reward diaktifkan kembali.'
          : 'Reward dinonaktifkan. Voucher yang sudah ditukar tetap bisa '
                'dipakai sampai tenggat.',
    );
  }

  Future<void> _onUpdateSubmitted(
    AdminRewardUpdateSubmitted event,
    Emitter<AdminRewardState> emit,
  ) async {
    if (event.stock == null && event.expiredAt == null) return;
    await _submit(
      emit,
      () => _repository.updateReward(
        event.id,
        stock: event.stock,
        expiredAt: event.expiredAt,
      ),
      successMessage: 'Stok & tenggat reward tersimpan.',
    );
  }

  Future<void> _submit(
    Emitter<AdminRewardState> emit,
    Future<AdminReward> Function() call, {
    required String successMessage,
  }) async {
    if (state.submitStatus == AdminRewardSubmitStatus.submitting) return;
    emit(
      state.copyWith(
        submitStatus: AdminRewardSubmitStatus.submitting,
        clearSubmit: true,
        isUnauthorized: false,
      ),
    );
    try {
      final reward = await call();
      emit(
        state.copyWith(
          submitStatus: AdminRewardSubmitStatus.success,
          submitMessage: successMessage,
          lastReward: reward,
        ),
      );
      add(const AdminRewardsLoaded());
    } on AuthException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        emit(
          state.copyWith(
            submitStatus: AdminRewardSubmitStatus.idle,
            clearSubmit: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          submitStatus: AdminRewardSubmitStatus.failure,
          submitErrorMessage: e.message,
          submitErrors: e.errors,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        emit(
          state.copyWith(
            submitStatus: AdminRewardSubmitStatus.idle,
            clearSubmit: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          submitStatus: AdminRewardSubmitStatus.failure,
          submitErrorMessage: e.message,
          submitErrors: e.errors,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          submitStatus: AdminRewardSubmitStatus.failure,
          submitErrorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _onClaimsLoaded(
    AdminRewardClaimsLoaded event,
    Emitter<AdminRewardState> emit,
  ) async {
    emit(
      state.copyWith(
        claimsStatus: AdminRewardClaimsStatus.loading,
        claimsRewardId: event.rewardId,
        claims: const [],
        claimsPage: 1,
        claimsLastPage: 1,
        claimsTotal: 0,
        claimsError: null,
        isUnauthorized: false,
      ),
    );
    try {
      final page = await _repository.getRewardClaims(event.rewardId);
      emit(
        state.copyWith(
          claimsStatus: AdminRewardClaimsStatus.loaded,
          claims: page.items,
          claimsPage: page.currentPage,
          claimsLastPage: page.lastPage,
          claimsTotal: page.total,
          claimsError: null,
        ),
      );
    } on AuthException catch (e) {
      _emitClaimsError(emit, e.message, e.statusCode);
    } on VoucherException catch (e) {
      _emitClaimsError(emit, e.message, e.statusCode);
    } catch (e) {
      _emitClaimsError(emit, 'Terjadi kesalahan: $e', null);
    }
  }

  Future<void> _onClaimsNextPage(
    AdminRewardClaimsNextPage event,
    Emitter<AdminRewardState> emit,
  ) async {
    final rewardId = state.claimsRewardId;
    if (rewardId == null) return;
    if (state.claimsStatus == AdminRewardClaimsStatus.loading) return;
    if (!state.hasMoreClaims) return;

    final nextPage = state.claimsPage + 1;
    emit(
      state.copyWith(
        claimsStatus: AdminRewardClaimsStatus.loading,
        claimsError: null,
      ),
    );
    try {
      final page = await _repository.getRewardClaims(rewardId, page: nextPage);
      emit(
        state.copyWith(
          claimsStatus: AdminRewardClaimsStatus.loaded,
          claims: [...state.claims, ...page.items],
          claimsPage: page.currentPage,
          claimsLastPage: page.lastPage,
          claimsTotal: page.total,
          claimsError: null,
        ),
      );
    } on AuthException catch (e) {
      _emitClaimsError(emit, e.message, e.statusCode);
    } on VoucherException catch (e) {
      _emitClaimsError(emit, e.message, e.statusCode);
    } catch (e) {
      _emitClaimsError(emit, 'Terjadi kesalahan: $e', null);
    }
  }

  /// 401/403 → paksa logout; lainnya → tampilkan error di seksi penukar.
  void _emitClaimsError(
    Emitter<AdminRewardState> emit,
    String message,
    int? statusCode,
  ) {
    if (statusCode == 401 || statusCode == 403) {
      emit(
        state.copyWith(
          claimsStatus: AdminRewardClaimsStatus.idle,
          isUnauthorized: true,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        claimsStatus: AdminRewardClaimsStatus.error,
        claimsError: message,
      ),
    );
  }

  void _onSubmitReset(
    AdminRewardSubmitReset event,
    Emitter<AdminRewardState> emit,
  ) {
    emit(
      state.copyWith(
        submitStatus: AdminRewardSubmitStatus.idle,
        clearSubmit: true,
      ),
    );
  }
}
