import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/auth_exception.dart';
import '../../core/network/voucher_exception.dart';
import '../../data/repositories/voucher_repository.dart';
import 'voucher_event.dart';
import 'voucher_state.dart';

/// Cache-first untuk marketplace + dompet.
class VoucherBloc extends Bloc<VoucherEvent, VoucherState> {
  VoucherBloc(this._repository) : super(const VoucherState()) {
    on<VouchersLoaded>(_onVouchersLoaded);
    on<MyVouchersLoaded>(_onMyVouchersLoaded);
    on<VoucherClaimSubmitted>(_onClaimSubmitted);
    on<VoucherClaimReset>(_onClaimReset);
  }

  final VoucherRepository _repository;

  Future<void> _onVouchersLoaded(
    VouchersLoaded event,
    Emitter<VoucherState> emit,
  ) async {
    final isSameCategory = state.selectedCategory == event.category;
    if (state.status == VoucherStatus.loaded &&
        state.vouchers.isNotEmpty &&
        isSameCategory) {
      return;
    }
    // Tampilkan cache Hive instan (termasuk saat ganti kategori).
    try {
      final cached = await _repository.getCachedVouchers(
        category: event.category,
      );
      final cachedPoints = await _repository.getCachedEcoPoints();
      if (cached.vouchers.isNotEmpty || cachedPoints != null) {
        emit(
          state.copyWith(
            status: VoucherStatus.loaded,
            vouchers: cached.vouchers.isNotEmpty
                ? cached.vouchers
                : state.vouchers,
            selectedCategory: event.category,
            ecoPoints: cachedPoints ?? state.ecoPoints,
            isOffline: true,
            lastUpdated: cached.savedAt ?? state.lastUpdated,
          ),
        );
        if (isSameCategory && cached.vouchers.isNotEmpty) {
          // Tetap lanjut refresh diam-diam di bawah.
        }
      } else if (state.vouchers.isEmpty) {
        emit(
          state.copyWith(
            status: VoucherStatus.loading,
            selectedCategory: event.category,
            errorMessage: null,
          ),
        );
      } else {
        emit(state.copyWith(selectedCategory: event.category));
      }
    } catch (_) {
      if (state.vouchers.isEmpty) {
        emit(
          state.copyWith(
            status: VoucherStatus.loading,
            selectedCategory: event.category,
            errorMessage: null,
          ),
        );
      }
    }

    try {
      final vouchers = await _repository.getVouchers(category: event.category);
      int? ecoPoints = state.ecoPoints;
      try {
        ecoPoints = await _repository.getEcoPoints();
      } catch (_) {}
      emit(
        state.copyWith(
          status: VoucherStatus.loaded,
          vouchers: vouchers,
          ecoPoints: ecoPoints,
          isOffline: false,
          lastUpdated: DateTime.now(),
        ),
      );
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      if (state.vouchers.isNotEmpty) {
        emit(state.copyWith(status: VoucherStatus.loaded, isOffline: true));
        return;
      }
      emit(
        state.copyWith(status: VoucherStatus.error, errorMessage: e.message),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      if (state.vouchers.isNotEmpty) {
        emit(state.copyWith(status: VoucherStatus.loaded, isOffline: true));
        return;
      }
      emit(
        state.copyWith(status: VoucherStatus.error, errorMessage: e.message),
      );
    } catch (e) {
      if (state.vouchers.isNotEmpty) {
        emit(state.copyWith(status: VoucherStatus.loaded, isOffline: true));
        return;
      }
      emit(
        state.copyWith(
          status: VoucherStatus.error,
          errorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _onMyVouchersLoaded(
    MyVouchersLoaded event,
    Emitter<VoucherState> emit,
  ) async {
    if (!event.force &&
        state.inventoryStatus == InventoryStatus.loaded &&
        state.myVouchers != null) {
      return;
    }
    // Cache Hive dulu agar dompet langsung tampil offline.
    if (state.myVouchers == null) {
      try {
        final cached = await _repository.getCachedMyVouchers();
        if (cached.inventory != null) {
          emit(
            state.copyWith(
              inventoryStatus: InventoryStatus.loaded,
              myVouchers: cached.inventory,
              isOffline: true,
            ),
          );
        }
      } catch (_) {}
    }
    final hasCache = state.myVouchers != null;
    if (!hasCache) {
      emit(
        state.copyWith(
          inventoryStatus: InventoryStatus.loading,
          inventoryError: null,
          isUnauthorized: false,
        ),
      );
    } else {
      emit(state.copyWith(inventoryError: null, isUnauthorized: false));
    }
    try {
      final inventory = await _repository.getMyVouchers();
      emit(
        state.copyWith(
          inventoryStatus: InventoryStatus.loaded,
          myVouchers: inventory,
          isOffline: false,
        ),
      );
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          inventoryStatus: hasCache
              ? InventoryStatus.loaded
              : InventoryStatus.error,
          inventoryError: e.message,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          inventoryStatus: hasCache
              ? InventoryStatus.loaded
              : InventoryStatus.error,
          inventoryError: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          inventoryStatus: hasCache
              ? InventoryStatus.loaded
              : InventoryStatus.error,
          inventoryError: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _onClaimSubmitted(
    VoucherClaimSubmitted event,
    Emitter<VoucherState> emit,
  ) async {
    if (state.claimStatus == ClaimStatus.claiming) return;
    emit(
      state.copyWith(
        claimStatus: ClaimStatus.claiming,
        claimingVoucherId: event.voucherId,
        clearClaim: true,
        isUnauthorized: false,
      ),
    );
    try {
      final result = await _repository.claimVoucher(voucherId: event.voucherId);
      // Klaim mengubah stok + saldo → muat ulang daftar, saldo, dompet.
      final vouchers = await _repository.getVouchers();
      final ecoPoints = await _repository.getEcoPoints();
      final inventory = await _repository.getMyVouchers();
      emit(
        state.copyWith(
          status: VoucherStatus.loaded,
          vouchers: vouchers,
          ecoPoints: ecoPoints,
          inventoryStatus: InventoryStatus.loaded,
          myVouchers: inventory,
          claimStatus: ClaimStatus.success,
          claimingVoucherId: event.voucherId,
          lastClaim: result,
        ),
      );
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(
          state.copyWith(
            claimStatus: ClaimStatus.idle,
            clearClaim: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          claimStatus: ClaimStatus.failure,
          claimingVoucherId: event.voucherId,
          claimErrorMessage: e.message,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(
          state.copyWith(
            claimStatus: ClaimStatus.idle,
            clearClaim: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          claimStatus: ClaimStatus.failure,
          claimingVoucherId: event.voucherId,
          claimErrorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          claimStatus: ClaimStatus.failure,
          claimingVoucherId: event.voucherId,
          claimErrorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  void _onClaimReset(VoucherClaimReset event, Emitter<VoucherState> emit) {
    emit(state.copyWith(claimStatus: ClaimStatus.idle, clearClaim: true));
  }
}
