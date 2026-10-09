import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/auth_exception.dart';
import '../../core/network/voucher_exception.dart';
import '../../data/repositories/merchant_repository.dart';
import '../../models/merchant_dashboard.dart';
import 'merchant_event.dart';
import 'merchant_state.dart';

/// BLoC dashboard merchant: cache-first seperti DashboardBloc/VoucherBloc.
///
/// - `MerchantLoaded`: tampilkan Hive instan, lalu refresh diam-diam online.
/// - `MerchantStatusToggled`: optimistic update + rollback bila PATCH gagal.
/// - `MerchantRedeemSubmitted`: POST redeem, sukses → refresh dashboard agar
///   saldo + riwayat sinkron.
class MerchantBloc extends Bloc<MerchantEvent, MerchantState> {
  MerchantBloc(this._repository) : super(const MerchantState()) {
    on<MerchantLoaded>(_onLoaded);
    on<MerchantRefreshed>(_onRefreshed);
    on<MerchantStatusToggled>(_onStatusToggled);
    on<MerchantRedeemSubmitted>(_onRedeemSubmitted);
    on<MerchantRedeemReset>(_onRedeemReset);
    on<MerchantDisbursementsLoaded>(_onDisbursementsLoaded);
  }

  final MerchantRepository _repository;

  Future<void> _onLoaded(
    MerchantLoaded event,
    Emitter<MerchantState> emit,
  ) async {
    if (state.status == MerchantStatus.loaded) return;
    await _load(emit, showCacheFirst: true);
  }

  Future<void> _onRefreshed(
    MerchantRefreshed event,
    Emitter<MerchantState> emit,
  ) async {
    await _load(emit, showCacheFirst: false);
  }

  Future<void> _load(
    Emitter<MerchantState> emit, {
    required bool showCacheFirst,
  }) async {
    if (showCacheFirst) {
      try {
        final cached = await _repository.getCachedDashboard();
        if (cached.dashboard != null) {
          emit(
            state.copyWith(
              status: MerchantStatus.loaded,
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
          status: MerchantStatus.loading,
          errorMessage: null,
          isUnauthorized: false,
        ),
      );
    }
    try {
      final dashboard = await _repository.getDashboard();
      emit(
        state.copyWith(
          status: MerchantStatus.loaded,
          dashboard: dashboard,
          isOffline: false,
          lastUpdated: DateTime.now(),
        ),
      );
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      if (hasData) {
        emit(state.copyWith(status: MerchantStatus.loaded, isOffline: true));
        return;
      }
      emit(
        state.copyWith(status: MerchantStatus.error, errorMessage: e.message),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      if (hasData) {
        emit(state.copyWith(status: MerchantStatus.loaded, isOffline: true));
        return;
      }
      emit(
        state.copyWith(status: MerchantStatus.error, errorMessage: e.message),
      );
    } catch (e) {
      if (hasData) {
        emit(state.copyWith(status: MerchantStatus.loaded, isOffline: true));
        return;
      }
      emit(
        state.copyWith(
          status: MerchantStatus.error,
          errorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _onStatusToggled(
    MerchantStatusToggled event,
    Emitter<MerchantState> emit,
  ) async {
    final current = state.dashboard;
    if (current == null || state.isToggling) return;
    final previous = current.isOpen;

    // Optimistic update agar Switch terasa instan.
    final optimistic = MerchantDashboard(
      storeName: current.storeName,
      verificationStatus: current.verificationStatus,
      isOpen: event.isOpen,
      canRedeem: current.isVerified && event.isOpen,
      balance: current.balance,
      stats: current.stats,
      recent: current.recent,
    );
    emit(state.copyWith(dashboard: optimistic, isToggling: true));

    try {
      final confirmed = await _repository.updateStatus(isOpen: event.isOpen);
      final synced = MerchantDashboard(
        storeName: current.storeName,
        verificationStatus: current.verificationStatus,
        isOpen: confirmed,
        canRedeem: current.isVerified && confirmed,
        balance: current.balance,
        stats: current.stats,
        recent: current.recent,
      );
      emit(state.copyWith(dashboard: synced, isToggling: false));
      // Sinkron penuh agar statistik tetap akurat.
      add(const MerchantRefreshed());
    } on AuthException catch (e) {
      emit(
        state.copyWith(
          dashboard: current,
          isToggling: false,
          toggleError: e.statusCode == 401
              ? 'Sesi berakhir. Silakan login ulang.'
              : e.message,
          isUnauthorized: e.statusCode == 401,
        ),
      );
      if (e.statusCode != 401) {
        // Kembalikan Switch ke posisi semula (sudah via dashboard: current).
        assert(previous != event.isOpen || true);
      }
    } on VoucherException catch (e) {
      emit(
        state.copyWith(
          dashboard: current,
          isToggling: false,
          toggleError: e.statusCode == 401
              ? 'Sesi berakhir. Silakan login ulang.'
              : e.message,
          isUnauthorized: e.statusCode == 401,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          dashboard: current,
          isToggling: false,
          toggleError: 'Gagal mengubah status toko: $e',
        ),
      );
    }
  }

  Future<void> _onRedeemSubmitted(
    MerchantRedeemSubmitted event,
    Emitter<MerchantState> emit,
  ) async {
    if (state.redeemStatus == MerchantRedeemStatus.redeeming) return;
    emit(
      state.copyWith(
        redeemStatus: MerchantRedeemStatus.redeeming,
        clearRedeem: true,
        isUnauthorized: false,
      ),
    );
    try {
      final result = await _repository.redeem(uniqueCode: event.uniqueCode);
      emit(
        state.copyWith(
          redeemStatus: MerchantRedeemStatus.success,
          lastRedeem: result,
        ),
      );
      // Saldo + riwayat berubah → sinkron dashboard diam-diam.
      try {
        final dashboard = await _repository.getCachedDashboard().then(
          (_) => _repository.getDashboard(),
        );
        emit(state.copyWith(dashboard: dashboard));
      } catch (_) {}
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(
          state.copyWith(
            redeemStatus: MerchantRedeemStatus.idle,
            clearRedeem: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          redeemStatus: MerchantRedeemStatus.failure,
          redeemErrorMessage: e.message,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(
          state.copyWith(
            redeemStatus: MerchantRedeemStatus.idle,
            clearRedeem: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          redeemStatus: MerchantRedeemStatus.failure,
          redeemErrorMessage: _friendlyRedeemError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          redeemStatus: MerchantRedeemStatus.failure,
          redeemErrorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  void _onRedeemReset(MerchantRedeemReset event, Emitter<MerchantState> emit) {
    emit(
      state.copyWith(
        redeemStatus: MerchantRedeemStatus.idle,
        clearRedeem: true,
      ),
    );
  }

  Future<void> _onDisbursementsLoaded(
    MerchantDisbursementsLoaded event,
    Emitter<MerchantState> emit,
  ) async {
    final loadMore = event.loadMore && state.historyItems.isNotEmpty;
    final nextPage = loadMore ? state.historyPage + 1 : 1;

    emit(
      state.copyWith(
        historyStatus: loadMore
            ? DisbursementHistoryStatus.loadingMore
            : DisbursementHistoryStatus.loading,
        historyStatusFilter: event.status,
        historyError: null,
        // Reset daftar saat ganti filter / muat ulang dari awal.
        historyItems: loadMore ? state.historyItems : const [],
        isUnauthorized: false,
      ),
    );

    try {
      final page = await _repository.getDisbursements(
        status: event.status,
        page: nextPage,
      );
      emit(
        state.copyWith(
          historyStatus: DisbursementHistoryStatus.loaded,
          historyItems: loadMore
              ? [...state.historyItems, ...page.items]
              : page.items,
          historyPage: page.currentPage,
          historyLastPage: page.lastPage,
          historyTotal: page.total,
        ),
      );
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          historyStatus: DisbursementHistoryStatus.error,
          historyError: e.message,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          historyStatus: DisbursementHistoryStatus.error,
          historyError: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          historyStatus: DisbursementHistoryStatus.error,
          historyError: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  /// Pesan redeem ramah kasir berdasarkan status backend.
  /// 403 belum verified/tutup atau milik toko lain, 404 tidak ketemu,
  /// 409 sudah used, 422 expired/inactive, 429 throttle 30/menit.
  String _friendlyRedeemError(VoucherException e) {
    switch (e.statusCode) {
      case 403:
        return e.message.isNotEmpty
            ? e.message
            : 'Toko belum terverifikasi / voucher milik toko lain.';
      case 404:
        return 'Kode voucher tidak ditemukan. Periksa token lagi.';
      case 409:
        return 'Voucher sudah pernah dicairkan.';
      case 422:
        return e.message.isNotEmpty
            ? e.message
            : 'Voucher kedaluwarsa atau tidak aktif.';
      case 429:
        return 'Terlalu sering verifikasi. Tunggu sebentar lalu coba lagi.';
      default:
        return e.message.isNotEmpty ? e.message : 'Gagal verifikasi voucher.';
    }
  }
}
